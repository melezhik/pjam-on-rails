package BampoManager::Stat::Placement::Daily;

use strict;
use warnings;

use Exporter 'import';
use BampoManager;
use BampoManager::Stat qw/
    prepare_stat_rs
    calc_leads
    calc_money
    calc_stat
    @STAT_COUNTERS
/;
use BampoManager::Filter::Const qw/:STAT_PERIOD/;
use BampoManager::Utils::DB qw/filter_by_stat_period/;
use BampoManager::Utils::Misc qw/gen_zero_stat/;

our @EXPORT_OK = qw/
    get_placement_daily_stat
    get_profile_daily_stat
    get_banner_daily_stat
/;

*get_profile_daily_stat = \&get_daily_stat;
*get_banner_daily_stat  = \&get_daily_stat;


my @COUNTERS = @STAT_COUNTERS;

my @FILTER_EMPTY = (qw/impressions clicks leads_reach leads_uniq leads_nu leads_proper placement_costs/);

#/////////////////////////////////////////////////////////////////////
sub get_placement_daily_stat
{
    my ($stat_rs, $placement_row, $cpoint_row, $filter) = @_;

    $stat_rs = prepare_stat_rs($stat_rs, $filter);
    $stat_rs = $stat_rs->search(undef, { group_by => ['me.date'] });

    my $result = [];
    my $total_stat = { map { $_ => 0 } @COUNTERS };

    my $client_leads = get_cpoint_client_stat($cpoint_row, $filter);
    my $total_leads  = calc_total_leads($cpoint_row, $filter);
    my $costs_daily  = get_placement_costs_daily($placement_row, $cpoint_row, $filter);

    foreach my $row ($stat_rs->all)
    {
        my %stat_obj = $row->get_columns();
        my $date = $stat_obj{date};
        $stat_obj{placement_costs} = $costs_daily->{$date}->{placement_costs};
        delete $costs_daily->{$date};
        calc_leads(\%stat_obj, $client_leads, $total_leads);
        calc_money(\%stat_obj);
        foreach (@COUNTERS)
        {
            $total_stat->{$_} += $stat_obj{$_} if $stat_obj{$_};
        }
        calc_stat(\%stat_obj);
        push @$result, \%stat_obj;
    }
    $stat_rs->clear_cache;

    foreach my $date_costs (values %$costs_daily)
    {
        my %stat_obj = %$date_costs;
        calc_money(\%stat_obj);
        foreach (@COUNTERS)
        {
            $total_stat->{$_} += $stat_obj{$_} if $stat_obj{$_};
        }
        calc_stat(\%stat_obj);
        push @$result, \%stat_obj;
    }

    # generate zero statistics on missing dates
    gen_zero_stat($result, $filter, $cpoint_row, $placement_row);

    calc_stat($total_stat);
    push @$result, $total_stat;

    return $result;
}

#/////////////////////////////////////////////////////////////////////
sub get_placement_costs_daily
{
    my ($placement_row, $cpoint_row, $filter) = @_;

    my $costs_rs = $placement_row->costs->search(undef,
        {
            select => ['line.costsSourceId', 'line.priceType', 'line.pricePurchase', 'me.date', 'me.costs'],
            as     => [qw/placement_costs_source placement_price_type price_purchase date placement_costs/],
            join   => 'line',
        }
    );

    # Filter costs by period of time
    my $start_date = ($cpoint_row->startDate < $filter->start_date) ?
        $filter->start_date : $cpoint_row->startDate;
    my $stop_date = (defined $cpoint_row->stopDate and $cpoint_row->stopDate < $filter->stop_date) ?
        $cpoint_row->stopDate : $filter->stop_date;
    $costs_rs = $costs_rs->search({
        -and => [
            { 'me.date' => { '>=', $start_date->strftime('%F') } },
            { 'me.date' => { '<=', $stop_date->strftime('%F') } },
        ],
    });

    my %costs_daily;
    foreach my $row ($costs_rs->all)
    {
        my %columns = $row->get_columns();
        my $date = $columns{date};
        $costs_daily{$date} = \%columns;
    }

    return \%costs_daily;
}

#/////////////////////////////////////////////////////////////////////
sub get_daily_stat
{
    my ($stat_rs, $placement_row, $cpoint_row, $filter) = @_;

    $stat_rs = prepare_stat_rs($stat_rs, $filter);
    $stat_rs = $stat_rs->search(undef, { group_by => ['me.date'] });

    my $result = [];
    my $total_stat = { map { $_ => 0 } @COUNTERS };

    my $client_leads = get_cpoint_client_stat($cpoint_row, $filter);
    my $total_leads  = calc_total_leads($cpoint_row, $filter);

    foreach my $row ($stat_rs->all)
    {
        my %stat_obj = $row->get_columns();
        calc_leads(\%stat_obj, $client_leads, $total_leads);
        calc_money(\%stat_obj);
        foreach (@COUNTERS)
        {
            $total_stat->{$_} += $stat_obj{$_} if $stat_obj{$_};
        }
        calc_stat(\%stat_obj);
        push @$result, \%stat_obj;
    }

    # generate zero statistics on missing dates
    gen_zero_stat($result, $filter, $cpoint_row, $placement_row);

    calc_stat($total_stat);
    push @$result, $total_stat;

    return $result;
}

#/////////////////////////////////////////////////////////////////////
sub get_cpoint_client_stat
{
    my ($cpoint_row, $filter) = @_;

    my $client_stat_rs = $cpoint_row->client_stat;
    $client_stat_rs = filter_by_stat_period($client_stat_rs, $filter);
    my $leads_col = $client_stat_rs->get_column('leads_client');

    return $leads_col->sum();
}

#/////////////////////////////////////////////////////////////////////
sub calc_total_leads
{
    my ($cpoint_row, $filter) = @_;

    my $leads_rs = $cpoint_row->target_stat->search(undef,
        {
            select => [
                { SUM => 'me.leads_reach' },
                { SUM => 'me.leads'       },
                { SUM => 'me.leads_nu'    },
                { SUM => 'me.leads_proper'    },
            ],
            as => [qw/
                leads_reach
                leads_uniq
                leads_nu
                leads_proper
            /],
            group_by => ['me.targetLineId'],
        }
    );
    $leads_rs = filter_by_stat_period($leads_rs, $filter, 'me');

    my $total_leads = 0;
    # actually in resultset should be only one row
    foreach my $row ($leads_rs->all)
    {
        my %leads_stat = $row->get_columns();
        $leads_stat{cp_price_type} = $cpoint_row->priceType;
        calc_leads(\%leads_stat);
        $total_leads += $leads_stat{leads};
    }

    return $total_leads;
}

#/////////////////////////////////////////////////////////////////////


1;
