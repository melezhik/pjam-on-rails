package BampoManager::Controller::Mediaplan;

use Moose;
use namespace::autoclean;
use HTTP::Status qw/:constants/;
use BampoManager::Schema::Const qw/:LINE_TYPE :MEDIAPLAN_STATUS :LINE_STATUS/;
use BampoManager::Stat::ControlPoints qw/get_cpoints_stat/;
use BampoManager::Utils::DB qw/
    get_banner_formats
    get_products
    get_channel_groups
    get_placement_targetings
    get_geos
    extra_filter_placements
    extra_filter_cpoints
/;
use BampoManager::Exceptions;
use DateTime;

BEGIN { extends 'BampoManager::Controller::Base' }


#/////////////////////////////////////////////////////////////////////
sub _mediaplan :Chained('/') :PathPart('mediaplans') :CaptureArgs(1)
{
    my ($self, $c, $id) = @_;
    $c->stash->{mediaplan_row} = $c->model('Bampo::Mediaplan')->find($id);
    unless ($c->stash->{mediaplan_row})
    {
        throw BampoManager::Exception::MediaplanNotFound(
            status => HTTP_NOT_FOUND,
            error  => "Couldn't find mediaplan with id='$id'"
        );
    }
}

#/////////////////////////////////////////////////////////////////////
sub index :Chained('_mediaplan') :PathPart('') :Args(0)
{
    my ($self, $c) = @_;

    my $filter = $self->get_filter($c);
    my $mediaplan_id = $c->stash->{mediaplan_row}->id;

    my $title_row = $c->model('Bampo::Mediaplan')->find($mediaplan_id, {
            join   => [qw/advertiser salesManager accountManager/],
            select => [
                'me.title',
                'me.id',
                'advertiser.title',
                'salesManager.title',
                'salesManager.email',
                'accountManager.title',
                'accountManager.email',
            ],
            as => [qw/
                mediaplan
                mediaplan_id
                advertiser
                sales_manager
                sales_manager_email
                account_manager
                account_manager_email
            /]
        }
    );

    $c->stash->{group_api_domain_name} = $c->config->{group_api_domain_name};
    $c->stash->{title}          = { $title_row->get_columns };
    $c->stash->{banner_formats} = get_banner_formats($c);
    $c->stash->{products}       = get_products($c);
    $c->stash->{channel_groups} = get_channel_groups($c);
    $c->stash->{placement_targetings}   = get_placement_targetings($c);
    $c->stash->{geos}           = get_geos($c);
    $c->stash->{data}           = get_statistics($c, $mediaplan_id, $filter);
    $c->stash->{filter}         = $filter;
}

#/////////////////////////////////////////////////////////////////////
sub get_filter
{
    my ($self, $c) = @_;

    my $filter_class = 'BampoManager::Filter::Mediaplan';
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
    my ($c, $mediaplan_id, $filter) = @_;

    my ($line_rs, $stat_rs, $leads_rs, $client_stat_rs) = prepare_stat_queries($c, $mediaplan_id, $filter);

    # Get lines info
    my %lines;
    foreach my $row ($line_rs->all)
    {
        my %line = $row->get_columns();
        $line{leads_auto_import} = (defined $line{lead_stat_id}) ? 1 : 0;
        delete $line{lead_stat_id};

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
    push @$result, @$lines_stat, values %lines, $total_stat;

    return $result;
}

#/////////////////////////////////////////////////////////////////////
sub prepare_stat_queries
{
    my ($c, $mediaplan_id, $filter) = @_;

    my $line_rs        = prepare_line_rs($c, $mediaplan_id, $filter);
    my $stat_rs        = prepare_stat_rs($c, $mediaplan_id, $filter);
    my $leads_rs       = prepare_leads_rs($c, $mediaplan_id, $filter);
    my $client_stat_rs = prepare_client_stat_rs($c, $mediaplan_id, $filter);

    return ($line_rs, $stat_rs, $leads_rs, $client_stat_rs);
}

#/////////////////////////////////////////////////////////////////////
sub prepare_line_rs
{
    my ($c, $mediaplan_id, $filter) = @_;

    my $line_rs = $c->model('Bampo::Line')->search(
        {
            'type'        => LINE_TYPE_PIXEL,
            'mediaplanId' => $mediaplan_id,
        },
        {
            select => [qw/ title id status startDate stopDate statType leadStatId /],
            as     => [qw/ line_title line_id line_status start_date stop_date stat_type lead_stat_id /],
        }
    );

    my $alias = 'me';
    $line_rs = extra_filter_cpoints($line_rs, $filter, $alias);

    return $line_rs;
}

#/////////////////////////////////////////////////////////////////////
sub prepare_stat_rs
{
    my ($c, $mediaplan_id, $filter) = @_;

    my $stat_rs = $c->model('Bampo::Statistics')->search(
        {
            'target.type'        => LINE_TYPE_PIXEL,
            'target.mediaplanId' => $mediaplan_id,
        },
        {
            join   => 'target',
            select => [qw/ me.targetLineId /],
            as     => [qw/ line_id /],
        }
    );

    # Don't filter placements in DB, we'll filter them later by hand when calc stat.
    # We don't filter placements in DB because we need all information to calc client
    # leads stat distribution.
    #my ($alias, $join) = ('source', 'source');
    #$stat_rs = extra_filter_placements($stat_rs, $filter, $alias, $join);

    my $alias = 'target';
    $stat_rs = extra_filter_cpoints($stat_rs, $filter, $alias);

    return $stat_rs;
}

#/////////////////////////////////////////////////////////////////////
sub prepare_leads_rs
{
    my ($c, $mediaplan_id, $filter) = @_;

    my $leads_rs = $c->model('Bampo::LeadStats')->search(
        {
            'line.mediaplanId' => $mediaplan_id
        },
        {
            join => 'line'
        }
    );

    # Apply filters
    my $alias = 'line';
    $leads_rs = extra_filter_cpoints($leads_rs, $filter, $alias);

    return $leads_rs;
}

#/////////////////////////////////////////////////////////////////////
sub prepare_client_stat_rs
{
    my ($c, $mediaplan_id, $filter) = @_;

    my $client_stat_rs = $c->model('Bampo::ClientStat')->search(
        {
            'line.mediaplanId' => $mediaplan_id
        },
        {
            join => 'line'
        }
    );

    # Apply filters
    my $alias = 'line';
    $client_stat_rs = extra_filter_cpoints($client_stat_rs, $filter, $alias);

    return $client_stat_rs;
}

#/////////////////////////////////////////////////////////////////////
sub create :Path('/mediaplans/create') :FormConfig {}

sub create_FORM_NOT_SUBMITTED
{
    my ($self, $c) = @_;
    $c->stash->{form}->default_values({ agencyId => $c->user->get('agencyId') });
}

sub create_FORM_VALID
{
    my ($self, $c) = @_;

    eval { $c->stash->{form}->model->create() };
    if (my $e = caught Exception::Class)
    {
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Unknown error while creating a mediaplan: '$e'",
            user_msg => $self->INTERNAL_SERVER_ERROR_MSG
        );
    }
}

sub create_FORM_NOT_VALID
{
    my ($self, $c) = @_;
    $c->res->status(HTTP_BAD_REQUEST);
}

#/////////////////////////////////////////////////////////////////////
sub edit :Chained('_mediaplan') :PathPart('edit') :Args(0) :FormConfig {}

sub edit_FORM_NOT_SUBMITTED
{
    my ($self, $c) = @_;
    $c->stash->{form}->model->default_values($c->stash->{mediaplan_row});
}

sub edit_FORM_VALID
{
    my ($self, $c) = @_;

    my $form = $c->stash->{form};
    my $obj  = $c->stash->{mediaplan_row};

    if ( ( $form->param_value('status') eq  MEDIAPLAN_STATUS_ARCHIVED ) and ( $obj->status ne MEDIAPLAN_STATUS_ARCHIVED ) ){
        my $lines = $c->model('Bampo::Line')->search({ mediaplanId => $obj->id , stopDate => undef });
        $lines->update_all({ status => LINE_STATUS_FINISHED , stopDate => DateTime->today()});
    }
    elsif( ( $form->param_value('status') eq  MEDIAPLAN_STATUS_NEW ) and ( $obj->status ne MEDIAPLAN_STATUS_NEW )){
        my $lines = $c->model('Bampo::Line')->search(
          { 
            mediaplanId => $obj->id , 
            type => LINE_TYPE_ADRIVER , 
          }
        );

        $lines = $lines->search(
          {
            stopDate => $lines->get_column('stopDate')->max()
          }
        );

        $lines->update_all({ status => LINE_STATUS_NEW , stopDate => undef });
    }

    eval { $form->model->update($obj) };
    if (my $e = Exception::Class->caught('DBIx::Class::Exception'))
    {
        if ($e =~ /version collision on update/)
        {
            throw BampoManager::Exception::FormFu::VersionCollision(
                status   => HTTP_BAD_REQUEST,
                error    => "Version collision while editing a mediaplan.",
                user_msg => $self->VERSION_COLLISION_ERROR_MSG
            );
        }
        else
        {
            throw BampoManager::Exception::FormFu(
                status   => HTTP_INTERNAL_SERVER_ERROR,
                error    => "Database error while editing a mediaplan: '$e'",
                user_msg => $self->INTERNAL_SERVER_ERROR_MSG
            );
        }
    }
    elsif ($e = caught Exception::Class)
    {
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Unknown error while editing a mediaplan: '$e'",
            user_msg => $self->INTERNAL_SERVER_ERROR_MSG
        );
    }
}

sub edit_FORM_NOT_VALID
{
    my ($self, $c) = @_;
    $c->res->status(HTTP_BAD_REQUEST);
}

#/////////////////////////////////////////////////////////////////////
sub delete :Chained('_mediaplan') :PathPart('delete') :Args(0)
{
    my ($self, $c) = @_;
    my $mediaplan = $c->stash->{mediaplan_row};
    if ($mediaplan->lns->count)
    {
        throw BampoManager::Exception::CouldNotDeleteMediaplan(
            status => HTTP_BAD_REQUEST,
            error  => "Couldn't delete mediaplan with lines"
        );
    }
    else
    {
        $mediaplan->delete();
        $c->res->body('The mediaplan has been deleted successfully.');
        $c->res->status(HTTP_OK);
    }
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
