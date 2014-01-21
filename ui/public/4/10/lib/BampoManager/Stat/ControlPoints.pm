package BampoManager::Stat::ControlPoints;

use strict;
use warnings;

use Exporter 'import';
use BampoManager::Stat qw/
    prepare_stat_rs
    check_placement_costs
    calc_leads
    calc_money
    calc_client_stat
    calc_stat
    @STAT_COUNTERS
/;
use BampoManager::Utils::DB qw/
    filter_by_stat_period
    is_placement_match_filter
/;

our @EXPORT_OK = qw/
    get_cpoints_stat
/;

my @COUNTERS = (@STAT_COUNTERS, qw/ leads_other /);

#/////////////////////////////////////////////////////////////////////
sub get_cpoints_stat
{
    my ($stat_rs, $leads_rs, $client_stat_rs, $filter) = @_;

    my $leads_stat  = get_leads_stat($leads_rs, $filter);
    my $client_stat = get_client_stat($client_stat_rs, $filter);
    my $lines_stat  = get_lines_stat($stat_rs, $client_stat, $filter);

    my $result = [];
    my %mediaplans;
    my $total_stat = { map { $_ => 0 } @COUNTERS };
    # Remove impressions, clicks and costs from counters
    # For impressions, clicks and costs we calculate total
    # inside mediaplan as single value from any control point
    my @line_counters = grep !/^(impressions|clicks|costs_exp|costs_real_outer|costs_real_inner|costs_deviation)$/, @COUNTERS;
    my @mediaplan_counters = qw/impressions clicks costs_exp costs_real_inner costs_real_outer costs_deviation/;
    while (my ($line_id, $line_stat) = each %$lines_stat)
    {
        if (exists $client_stat->{$line_id})
        {
            my $stat = delete $client_stat->{$line_id};
            # We leave the original leads value by cliets stat
            # if we couldn't calculate client leads distribution
            $line_stat->{leads} = $stat->{leads_client} unless $line_stat->{leads};
        }
        $line_stat->{leads_other} = (exists $leads_stat->{$line_id}) ? $leads_stat->{$line_id}->{leads_other} : undef;
        foreach (@line_counters)
        {
            $total_stat->{$_} += $line_stat->{$_} if $line_stat->{$_};
        }

        my $mediaplan_id = $line_stat->{mediaplan_id};
        my $sitezone_key = $line_stat->{site_id} . '_' . $line_stat->{sitezone_id};
        $mediaplans{$mediaplan_id} = { $sitezone_key => 1 } unless exists $mediaplans{$mediaplan_id};
        if (exists $mediaplans{$mediaplan_id}->{$sitezone_key})
        {
            foreach (@mediaplan_counters)
            {
                $total_stat->{$_} += $line_stat->{$_} if $line_stat->{$_};
            }
        }
        else
        {
            $mediaplans{$mediaplan_id}->{$sitezone_key} = 1;
        }
        calc_stat($line_stat);
        push @$result, $line_stat;
    }

    if ($filter->does('BampoManager::Filter::Role::ExtraPlacements') and not $filter->is_used_placement_extra_filter)
    {
        foreach my $stat_data (values %$client_stat)
        {
            my $line_stat = { %$stat_data };
            calc_client_stat($line_stat, $stat_data);
            foreach (@line_counters)
            {
                $total_stat->{$_} += $line_stat->{$_} if $line_stat->{$_};
            }
            calc_stat($line_stat);
            push @$result, $line_stat;
        }
    }

    calc_stat($total_stat);
    push @$result, $total_stat;

    return $result;
}

#/////////////////////////////////////////////////////////////////////
sub get_leads_stat
{
    my ($leads_rs, $filter) = @_;

    $leads_rs = $leads_rs->search(undef,
        {
            select   => [ 'me.lineId', { SUM => 'me.leads_other' } ],
            as       => [qw/ line_id leads_other /],
            group_by => ['me.lineId'],
        }
    );
    $leads_rs = filter_by_stat_period($leads_rs, $filter, 'me');

    my %leads_stat;
    foreach my $row ($leads_rs->all)
    {
        my %line_stat = $row->get_columns();
        my $line_id = $line_stat{line_id};
        $leads_stat{$line_id} = \%line_stat;
    }

    return \%leads_stat;
}

#/////////////////////////////////////////////////////////////////////
sub get_client_stat
{
    my ($client_stat_rs, $filter) = @_;

    $client_stat_rs = $client_stat_rs->search(undef,
        {
            select => [
                'me.lineId',
                'line.statType',
                'line.priceSale',
                'line.supercom',
                { SUM => 'me.leads_client' },
            ],
            as   => [qw/ line_id stat_type price_sale supercom leads_client /],
            join => 'line',
            group_by => ['me.lineId']
        }
    );
    $client_stat_rs = filter_by_stat_period($client_stat_rs, $filter, 'me');

    my %client_stat;
    foreach my $row ($client_stat_rs->all)
    {
        my %line_stat = $row->get_columns();
        my $line_id = $line_stat{line_id};
        $client_stat{$line_id} = \%line_stat;
    }

    return \%client_stat;
}

#/////////////////////////////////////////////////////////////////////
sub get_lines_stat
{
    my ($stat_rs, $client_stat, $filter) = @_;

    $stat_rs = prepare_stat_rs($stat_rs, $filter, { add_placement_costs => 1 });
    $stat_rs = $stat_rs->search(undef,
        {
            '+select' => ['me.targetLineId', 'target.mediaplanId', 'target.siteId', 'target.siteZoneId'],
            '+as'     => [qw/ line_id mediaplan_id site_id sitezone_id /],
            group_by  => ['me.targetLineId', 'me.sourceLineId'],
            cache     => 1,
        }
    );

    my $total_leads = calc_total_leads($stat_rs);

    my %lines_stat;
    foreach my $row ($stat_rs->all)
    {
        my %placement_stat = $row->get_columns();
        next if $filter->is_used_placement_extra_filter and not is_placement_match_filter(\%placement_stat, $filter);

        my $target_id = $placement_stat{line_id};
        my $client_leads = $client_stat->{$target_id}->{leads_client};
        calc_leads(\%placement_stat, $client_leads, $total_leads->{$target_id});
        calc_money(\%placement_stat);
        check_placement_costs(\%placement_stat, $filter);

        unless (exists $lines_stat{$target_id})
        {
            $lines_stat{$target_id} = \%placement_stat;
        }
        else
        {
            foreach (@COUNTERS)
            {
                $lines_stat{$target_id}->{$_} += $placement_stat{$_} if $placement_stat{$_};
            }

            if (not $placement_stat{costs_check_ok} and $lines_stat{$target_id}->{costs_check_ok})
            {
                $lines_stat{$target_id}->{costs_check_ok} = 0;
            }
        }
    }
    $stat_rs->clear_cache;

    return \%lines_stat;
}

#/////////////////////////////////////////////////////////////////////
sub calc_total_leads
{
    my ($stat_rs) = @_;

    my %total_leads;
    foreach my $row ($stat_rs->all)
    {
        my %placement_stat = $row->get_columns();
        my $target_id = $placement_stat{line_id};
        calc_leads(\%placement_stat);
        $total_leads{$target_id} += $placement_stat{leads};
    }

    return \%total_leads;
}

#/////////////////////////////////////////////////////////////////////


1;
