package BampoManager::Controller::Lines::CPoint::DailyStat;

use Moose;
use namespace::autoclean;
use HTTP::Status qw/:constants/;
use BampoManager::Schema::Const qw/:LINE_TYPE/;
use BampoManager::Stat::CPoint::Daily qw/get_cpoint_daily_stat/;
use BampoManager::Utils::DB qw/
    get_banner_formats
    get_products
    extra_filter_placements
/;

BEGIN { extends 'BampoManager::Controller::Base' }


#/////////////////////////////////////////////////////////////////////
sub index :Chained('/lines/cpoint/_title') :PathPart('daily_stat') :Args(0)
{
    my ($self, $c) = @_;

    my $cpoint_row = $c->stash->{cpoint_row};
    my $cpoint_id  = $cpoint_row->id;

    my $filter = $self->get_filter($c);
    my $title  = { $c->stash->{title_row}->get_columns };
    my $stat_rs = prepare_stat_rs($c, $cpoint_id, $filter);

    $c->stash->{filter}         = $filter;
    $c->stash->{title}          = $title;
    $c->stash->{data}           = get_cpoint_daily_stat($stat_rs, $cpoint_row, $filter);
    $c->stash->{banner_formats} = get_banner_formats($c);
    $c->stash->{products}       = get_products($c);
}

#/////////////////////////////////////////////////////////////////////
sub get_filter
{
    my ($self, $c) = @_;

    my $filter_class = 'BampoManager::Filter::CPoint::DailyStat';
    my $filter = $self->get_page_filter($c, $filter_class);

    my $stat_filter_class = 'BampoManager::Filter::StatPeriod';
    my $stat_filter = $self->get_page_filter($c, $stat_filter_class);

    my $extra_filter_class = 'BampoManager::Filter::Extras';
    my $extra_filter = $self->get_page_filter($c, $extra_filter_class);

    # copy stat period from another page
    $filter->copy_stat_period($stat_filter);

    # copy extras filters from another page
    $filter->copy_placement_extra_filter($extra_filter);

    # save filters
    $self->set_page_filter($c, $filter_class, $filter);
    $self->set_page_filter($c, $stat_filter_class, $stat_filter);
    $self->set_page_filter($c, $extra_filter_class, $extra_filter);

    return $filter;
}

#/////////////////////////////////////////////////////////////////////
sub prepare_stat_rs
{
    my ($c, $cpoint_id, $filter) = @_;

    my $stat_rs = $c->model('Bampo::Statistics')->search(
        {
            'me.targetLineId' => $cpoint_id,
            'source.type'     => LINE_TYPE_ADRIVER,
        },
        {
            select => ['me.date'],
            as     => [qw/date/],
        }
    );

    # Don't filter placements in DB, we'll filter them later by hand when calc stat.
    # We don't filter placements in DB because we need all information to calc client
    # leads stat distribution.
    #my ($alias, $join) = ('source', 'source');
    #$stat_rs = extra_filter_placements($stat_rs, $filter, $alias, $join);

    return $stat_rs;
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
