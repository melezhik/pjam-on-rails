package BampoManager::Stat::CPoint::Daily;

use strict;
use warnings;

use Exporter 'import';
use BampoManager::Utils::Misc qw/gen_zero_stat/;
use BampoManager::Stat qw/
    prepare_stat_rs
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
    get_cpoint_daily_stat
/;

my @COUNTERS = (@STAT_COUNTERS, qw/ leads_other /);

#/////////////////////////////////////////////////////////////////////
sub get_cpoint_daily_stat
{
    my ($stat_rs, $cpoint_row, $filter) = @_;

    my $leads_stat  = get_period_leads_stat($cpoint_row, $filter);
    my $client_stat = get_period_client_stat($cpoint_row, $filter);
    my $dates_stat  = get_period_line_stat($stat_rs, $client_stat, $filter);

    my $result = [];
    my $total_stat = { map { $_ => 0 } @COUNTERS };
    while (my ($date, $date_stat) = each %$dates_stat)
    {
        if (exists $client_stat->{$date})
        {
            my $stat = delete $client_stat->{$date};
            # We leave the original leads value by cliets stat
            # if we couldn't calculate client leads distribution
            $date_stat->{leads} = $stat->{leads_client} unless $date_stat->{leads};
        }
        if (exists $leads_stat->{$date})
        {
            $date_stat->{leads_other} = $leads_stat->{$date}->{leads_other};
            delete $leads_stat->{$date};
        }
        foreach (@COUNTERS)
        {
            $total_stat->{$_} += $date_stat->{$_} if $date_stat->{$_};
        }
    }

    while (my ($date, $stat_data) = each %$client_stat)
    {
        my $date_stat = { %$stat_data };
        calc_client_stat($date_stat, $stat_data);
        foreach (@COUNTERS)
        {
            $total_stat->{$_} += $date_stat->{$_} if $date_stat->{$_};
        }

        # Save a new date stat in the hash
        $dates_stat->{$date} = $date_stat;
    }

    while (my ($date, $date_stat) = each %$leads_stat)
    {
        # Check if the date exists in the hash. It's possible if it got there from the client_stat data
        if (exists $dates_stat->{$date})
        {
            $dates_stat->{$date}->{leads_other} = $date_stat->{leads_other};
        }
        else
        {
            $dates_stat->{$date} = $date_stat;
        }
        $total_stat->{leads_other} += $date_stat->{leads_other};
    }

    foreach my $date_stat (values %$dates_stat)
    {
        calc_stat($date_stat);
        push @$result, $date_stat;
    }

    # generate zero statistics on missing dates
    gen_zero_stat($result, $filter, $cpoint_row);

    calc_stat($total_stat);
    push @$result, $total_stat;

    return $result;
}

#/////////////////////////////////////////////////////////////////////
sub get_period_leads_stat
{
    my ($cpoint_row, $filter) = @_;

    my $leads_rs = $cpoint_row->leads_stat->search(undef,
        {
            select   => [ 'me.lineId', 'me.date', { SUM => 'me.leads_other' } ],
            as       => [qw/ line_id date leads_other /],
            group_by => ['me.date'],
        }
    );
    $leads_rs = filter_by_stat_period($leads_rs, $filter, 'me');

    my %leads_stat;
    foreach my $row ($leads_rs->all)
    {
        my %line_stat = $row->get_columns();
        my $date = $line_stat{date};
        $leads_stat{$date} = \%line_stat;
    }

    return \%leads_stat
}

#/////////////////////////////////////////////////////////////////////
sub get_period_client_stat
{
    my ($cpoint_row, $filter) = @_;

    my $client_stat_rs = $cpoint_row->client_stat->search(undef,
        {
            select => [
                'me.lineId',
                'line.statType',
                'line.priceSale',
                'line.supercom',
                'me.date',
                { SUM => 'me.leads_client' },
            ],
            as   => [qw/ line_id stat_type price_sale supercom date leads_client /],
            join => 'line',
            group_by => ['me.date'],
        }
    );
    $client_stat_rs = filter_by_stat_period($client_stat_rs, $filter, 'me');

    my %client_stat;
    foreach my $row ($client_stat_rs->all)
    {
        my %line_stat = $row->get_columns();
        my $date = $line_stat{date};
        $client_stat{$date} = \%line_stat;
    }

    return \%client_stat
}

#/////////////////////////////////////////////////////////////////////
sub get_period_line_stat
{
    my ($stat_rs, $client_stat, $filter) = @_;

    $stat_rs = prepare_stat_rs($stat_rs, $filter, { add_placement_costs_daily => 1 });
    $stat_rs = $stat_rs->search(undef,
        {
            group_by => ['me.date', 'me.sourceLineId'],
            cache    => 1,
        }
    );

    my $total_leads = calc_total_leads($stat_rs);

    my %dates_stat;
    foreach my $row ($stat_rs->all)
    {
        my %placement_stat = $row->get_columns();
        next if $filter->is_used_placement_extra_filter and not is_placement_match_filter(\%placement_stat, $filter);

        my $date = $placement_stat{date};
        my $client_leads = $client_stat->{$date}->{leads_client};
        calc_leads(\%placement_stat, $client_leads, $total_leads->{$date});
        calc_money(\%placement_stat);
        check_placement_costs(\%placement_stat);

        unless (exists $dates_stat{$date})
        {
            $dates_stat{$date} = \%placement_stat;
        }
        else
        {
            foreach (@COUNTERS)
            {
                $dates_stat{$date}->{$_} += $placement_stat{$_} if $placement_stat{$_};
            }

            if (not $placement_stat{costs_check_ok} and $dates_stat{$date}->{costs_check_ok})
            {
                $dates_stat{$date}->{costs_check_ok} = 0;
            }
        }
    }
    $stat_rs->clear_cache;

    return \%dates_stat;
}

#/////////////////////////////////////////////////////////////////////
sub calc_total_leads
{
    my ($stat_rs) = @_;

    my %total_leads;
    foreach my $row ($stat_rs->all)
    {
        my %placement_stat = $row->get_columns();
        my $date = $placement_stat{date};
        calc_leads(\%placement_stat);
        $total_leads{$date} += $placement_stat{leads};
    }

    return \%total_leads;
}

#/////////////////////////////////////////////////////////////////////
sub check_placement_costs
{
    my ($placement_stat) = @_;

    if ($placement_stat->{placement_costs_source})
    {
        $placement_stat->{costs_check_ok} = (defined $placement_stat->{placement_costs}) ? 1 : 0;
    }
    else
    {
        $placement_stat->{costs_check_ok} = 1;
    }

    return undef;
}

#/////////////////////////////////////////////////////////////////////


1;
