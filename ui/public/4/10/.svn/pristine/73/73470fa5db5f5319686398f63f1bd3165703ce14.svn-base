package BampoManager::Controller::Lines::Placement::DailyStat;

use Moose;
use namespace::autoclean;
use BampoManager::Stat::Placement::Daily qw/get_placement_daily_stat/;
use HTTP::Status qw/:constants/;

BEGIN { extends 'BampoManager::Controller::Base' }


#/////////////////////////////////////////////////////////////////////
sub _title :Chained('/lines/placement/_placement') :PathPart('') :CaptureArgs(0)
{
    my ($self, $c) = @_;

    my $cpoint_id = $c->request->params->{cpoint_id};
    $c->forward('/lines/cpoint/_cpoint', [$cpoint_id]);

    my $title_row = $c->model('Bampo::Line')->find($cpoint_id, {
            join   => { mediaplan => [qw/advertiser salesManager accountManager/] },
            select => [
                'me.id',
                'me.title',
                'mediaplan.id',
                'mediaplan.title',
                'advertiser.title',
                'salesManager.title',
                'salesManager.email',
                'accountManager.title',
                'accountManager.email',
            ],
            as => [qw/
                cpoint_id
                cpoint
                mediaplan_id
                mediaplan
                advertiser
                sales_manager
                sales_manager_email
                account_manager
                account_manager_email
            /]
        }
    );
    my $title = { $title_row->get_columns };

    my $placement_row = $c->stash->{placement_row};
    $title->{placement_id} = $placement_row->id;
    $title->{placement}    = $placement_row->title;
    $title->{price_type}   = $placement_row->priceType;

    $c->stash->{title} = $title;
}

#/////////////////////////////////////////////////////////////////////
sub index :Chained('_title') :PathPart('daily_stat') :Args(0)
{
    my ($self, $c) = @_;

    my $title  = $c->stash->{title};
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

    my $placement_row = $c->stash->{placement_row};
    my $cpoint_row    = $c->stash->{cpoint_row};

    my $stat_rs = $c->model('Bampo::Statistics')->search(
        {
            'me.targetLineId' => $cpoint_row->id,
            'me.sourceLineId' => $placement_row->id,
        },
        {
            select => ['me.date'],
            as     => [qw/date/],
        }
    );

    my $result = get_placement_daily_stat($stat_rs, $placement_row, $cpoint_row, $filter);

    return $result;
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
