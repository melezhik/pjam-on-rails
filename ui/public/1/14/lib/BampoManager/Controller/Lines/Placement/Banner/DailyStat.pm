package BampoManager::Controller::Lines::Placement::Banner::DailyStat;

use Moose;
use namespace::autoclean;
use BampoManager::Stat::Placement::Daily qw/get_banner_daily_stat/;
use HTTP::Status qw/:constants/;

BEGIN { extends 'BampoManager::Controller::Base' }


#/////////////////////////////////////////////////////////////////////
sub _banner :Chained('/lines/placement/dailystat/_title') :PathPart('banners') :CaptureArgs(1)
{
    my ($self, $c, $id) = @_;
    $c->stash->{banner_id} = $id;
}

#/////////////////////////////////////////////////////////////////////
sub index :Chained('_banner') :PathPart('daily_stat') :Args(0)
{
    my ($self, $c) = @_;

    my $banner_id = $c->stash->{banner_id};
    my $title     = $c->stash->{title};
    $title->{banner_id} = $banner_id;
    $title->{banner}    = eval { $c->model('Adriver')->banner($banner_id)->comment } || $banner_id;
    $title->{banner}    =~ s/\s*Copied from banner #\d+\s*//;

    my $filter = $self->get_filter($c);
    $c->stash->{filter} = $filter;
    $c->stash->{data}   = get_daily_stat($c, $filter);
}

#/////////////////////////////////////////////////////////////////////
sub get_filter
{
    my ($self, $c) = @_;

    my $filter_class = 'BampoManager::Filter::StatPeriod';
    my $filter = $self->get_page_filter($c, $filter_class);
    $self->set_page_filter($c, $filter_class, $filter);

    return $filter;
}

#/////////////////////////////////////////////////////////////////////
sub get_daily_stat
{
    my ($c, $filter) = @_;

    my $cpoint_row    = $c->stash->{cpoint_row};
    my $placement_row = $c->stash->{placement_row};
    my $banner_id     = $c->stash->{banner_id};

    my $stat_rs = $c->model('Bampo::Statistics')->search(
        {
            'me.targetLineId' => $cpoint_row->id,
            'me.sourceLineId' => $placement_row->id,
            'me.bannerId'     => $banner_id,
        },
        {
            select => ['me.date'],
            as     => [qw/date/],
        }
    );

    my $result = get_banner_daily_stat($stat_rs, $placement_row, $cpoint_row, $filter);

    return $result;
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
