package BampoManager::Controller::Lines::ControlPoints;

use Moose;
use namespace::autoclean;
use BampoManager::Schema::Const qw/:LINE_TYPE/;
use BampoManager::Filter::Const qw/:STAT_PERIOD/;
use BampoManager::Stat::ControlPoints qw/get_cpoints_stat/;
use BampoManager::Utils::DB qw/
    get_clients_by_agencies
    get_banner_formats
    get_products
    get_channel_groups
    get_placement_targetings
    get_geos
    filter_by_list_format
    extra_filter_placements
    extra_filter_cpoints
/;

BEGIN { extends 'BampoManager::Controller::Base' }

#/////////////////////////////////////////////////////////////////////
sub index :Path
{
    my ($self, $c) = @_;
    my $filter = $self->get_filter($c);

    $c->stash->{filter}         = $filter;
    $c->stash->{agencies}       = get_clients_by_agencies($c);
    $c->stash->{banner_formats} = get_banner_formats($c);
    $c->stash->{products}       = get_products($c);
    $c->stash->{channel_groups} = get_channel_groups($c);
    $c->stash->{placement_targetings}   = get_placement_targetings($c);
    $c->stash->{geos}           = get_geos($c);
    $c->stash->{data}           = get_statistics($c, $filter);
}

#/////////////////////////////////////////////////////////////////////
sub get_filter
{
    my ($self, $c) = @_;

    my $filter_class = 'BampoManager::Filter::ControlPoints';
    my $filter = $self->get_page_filter($c, $filter_class);

    my $stat_filter_class = 'BampoManager::Filter::StatPeriod';
    my $stat_filter = $self->get_page_filter($c, $stat_filter_class);

    my $extra_filter_class = 'BampoManager::Filter::Extras';
    my $extra_filter = $self->get_page_filter($c, $extra_filter_class);

    # copy stat period from another page
    $filter->copy_stat_period($stat_filter);

    # copy extras filters from another page
    $filter->copy_cpoint_extra_filter($extra_filter);
    $filter->copy_placement_extra_filter($extra_filter);

    # save filters
    $self->set_page_filter($c, $filter_class, $filter);
    $self->set_page_filter($c, $stat_filter_class, $stat_filter);
    $self->set_page_filter($c, $extra_filter_class, $extra_filter);

    return $filter;
}

#/////////////////////////////////////////////////////////////////////
sub get_statistics
{
    my ($c, $filter) = @_;

    my ($line_rs, $stat_rs, $leads_rs, $client_stat_rs) = prepare_stat_queries($c, $filter);

    # Get lines info
    my %lines;
    foreach my $row ($line_rs->all)
    {
        my %line = $row->get_columns();
        my $line_id = $line{line_id};
        $lines{$line_id} = \%line;
    }

    # Get lines stat
    my $lines_stat = get_cpoints_stat($stat_rs, $leads_rs, $client_stat_rs, $filter);

    # Add information to the stat objects
    my $total_stat = pop @$lines_stat;
    foreach my $line_stat (@$lines_stat)
    {
        my $line_id   = $line_stat->{line_id};
        my $line_info = $lines{$line_id};
        my @fields = keys %$line_info;
        @{$line_stat}{@fields} = @{$line_info}{@fields};
        delete $lines{$line_id};
    }

    my $result = [];
    if ($filter->show_empty)
    {
        push @$result, @$lines_stat, values %lines;
    }
    else
    {
        # Skip control points with zero statistics
        push @$result, grep {
            (defined $_->{impressions} and $_->{impressions} != 0)
            or (defined $_->{clicks} and $_->{clicks} != 0)
            or (defined $_->{leads} and $_->{leads} != 0)
        } @$lines_stat;
    }
    push @$result, $total_stat;

    return $result;
}

#/////////////////////////////////////////////////////////////////////
sub prepare_stat_queries
{
    my ($c, $filter) = @_;

    my $line_rs        = prepare_line_rs($c, $filter);
    my $stat_rs        = prepare_stat_rs($c, $filter);
    my $leads_rs       = prepare_leads_rs($c, $filter);
    my $client_stat_rs = prepare_client_stat_rs($c, $filter);

    return ($line_rs, $stat_rs, $leads_rs, $client_stat_rs);
}

#/////////////////////////////////////////////////////////////////////
sub prepare_line_rs
{
    my ($c, $filter) = @_;

    my $line_rs = $c->model('Bampo::Line')->search(
        {
            'me.type' => LINE_TYPE_PIXEL,
        },
        {
            join   => { 'mediaplan' => 'advertiser' },
            select => [qw/ mediaplan.id mediaplan.title advertiser.title me.title me.id me.status /],
            as     => [qw/ mediaplan_id mediaplan_title advertiser_title line_title line_id line_status /],
        }
    );

    # Apply filters
    my $alias = 'mediaplan';
    $line_rs = filter_by_list_format($c, $line_rs, $filter, $alias);

    $alias = 'me';
    $line_rs = filter_by_stat_period($line_rs, $filter, $alias);

    $alias = 'me';
    $line_rs = extra_filter_cpoints($line_rs, $filter, $alias);

    return $line_rs;
}

#/////////////////////////////////////////////////////////////////////
sub prepare_stat_rs
{
    my ($c, $filter) = @_;

    my $stat_rs = $c->model('Bampo::Statistics')->search(
        {
            'target.type' => LINE_TYPE_PIXEL,
        },
        {
            join   => 'target',
            select => [qw/ me.targetLineId /],
            as     => [qw/ line_id /],
        }
    );

    # Apply filters
    my $alias = 'mediaplan';
    my $join = { 'target' => 'mediaplan' };
    $stat_rs = filter_by_list_format($c, $stat_rs, $filter, $alias, $join);

    $alias = 'target';
    $stat_rs = filter_by_stat_period($stat_rs, $filter, $alias);

    # Don't filter placements in DB, we'll filter them later by hand when calc stat.
    # We don't filter placements in DB because we need all information to calc client
    # leads stat distribution.
    #($alias, $join) = ('source', 'source');
    #$stat_rs = extra_filter_placements($stat_rs, $filter, $alias, $join);

    $alias = 'target';
    $stat_rs = extra_filter_cpoints($stat_rs, $filter, $alias);

    return $stat_rs;
}

#/////////////////////////////////////////////////////////////////////
sub prepare_leads_rs
{
    my ($c, $filter) = @_;

    my $leads_rs = $c->model('Bampo::LeadStats');

    # Apply filters
    my $alias = 'mediaplan';
    my $join = { 'line' => 'mediaplan' };
    $leads_rs = filter_by_list_format($c, $leads_rs, $filter, $alias, $join);

    ($alias, $join) = ('line', 'line');
    $leads_rs = filter_by_stat_period($leads_rs, $filter, $alias, $join);

    ($alias, $join) = ('line', 'line');
    $leads_rs = extra_filter_cpoints($leads_rs, $filter, $alias, $join);

    return $leads_rs;
}

#/////////////////////////////////////////////////////////////////////
sub prepare_client_stat_rs
{
    my ($c, $filter) = @_;

    my $client_stat_rs = $c->model('Bampo::ClientStat');

    # Apply filters
    my $alias = 'mediaplan';
    my $join = { 'line' => 'mediaplan' };
    $client_stat_rs = filter_by_list_format($c, $client_stat_rs, $filter, $alias, $join);

    ($alias, $join) = ('line', 'line');
    $client_stat_rs = filter_by_stat_period($client_stat_rs, $filter, $alias, $join);

    ($alias, $join) = ('line', 'line');
    $client_stat_rs = extra_filter_cpoints($client_stat_rs, $filter, $alias, $join);

    return $client_stat_rs;
}

#/////////////////////////////////////////////////////////////////////
sub filter_by_stat_period
{
    my ($rs, $filter, $alias, $join) = @_;

    my $start_date = ($alias) ? $alias . '.startDate' : 'startDate';
    my $stop_date  = ($alias) ? $alias . '.stopDate'  : 'stopDate';
    $rs = $rs->search(
        {
            -or => [
                -and => [
                    $start_date => { '<=', $filter->start_date->strftime('%F') },
                    -or => [
                        $stop_date => undef,
                        $stop_date => { '>=', $filter->start_date->strftime('%F') },
                    ],
                ],
                -and => [
                    $start_date => { '>=', $filter->start_date->strftime('%F') },
                    $start_date => { '<=', $filter->stop_date->strftime('%F') },
                ],
            ],
        }
    );
    $rs = $rs->search(undef, { join => $join }) if defined $join;

    return $rs;
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
