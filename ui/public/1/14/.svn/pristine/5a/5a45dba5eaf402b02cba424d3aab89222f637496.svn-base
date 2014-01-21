package BampoManager::Controller::Lines::CPoint;

use Moose;
use namespace::autoclean;
use HTTP::Status qw/:constants/;
use BampoManager::Schema::Const qw/:LINE_TYPE :STAT_TYPE/;
use BampoManager::Stat::Placements qw/get_placements_stat/;
use BampoManager::Utils::DB qw/
    get_banner_formats
    get_products
    get_channel_groups
    get_placement_targetings
    update_leads_shipment_data
    update_cpoint_status
    extra_filter_placements
/;
use BampoManager::Utils::Misc qw/generate_password/;
use BampoManager::Exceptions;

BEGIN { extends 'BampoManager::Controller::Base' }


#/////////////////////////////////////////////////////////////////////
sub _cpoint :Chained('/') :PathPart('lines/controlpoints') :CaptureArgs(1)
{
    my ($self, $c, $id) = @_;
    $c->stash->{cpoint_row} = $c->model('Bampo::Line')->find($id);
    unless ($c->stash->{cpoint_row})
    {
        throw BampoManager::Exception::CPointNotFound(
            status => HTTP_NOT_FOUND,
            error  => "Couldn't find control point with id='$id'"
        );
    }
}

#/////////////////////////////////////////////////////////////////////
sub _title :Chained('_cpoint') :PathPart('') :CaptureArgs(0)
{
    my ($self, $c) = @_;

    my $cpoint_id = $c->stash->{cpoint_row}->id;
    my $title_row = $c->model('Bampo::Line')->find($cpoint_id, {
            join   => { mediaplan => [qw/advertiser salesManager accountManager/] },
            select => [
                'me.id',
                'me.id',
                'me.title',
                'mediaplan.id',
                'mediaplan.title',
                'advertiser.title',
                'salesManager.title',
                'salesManager.email',
                'accountManager.title',
                'accountManager.email',
                'me.priceType',
                'me.statType',
            ],
            as => [qw/
                id
                line_id
                line
                mediaplan_id
                mediaplan
                advertiser
                sales_manager
                sales_manager_email
                account_manager
                account_manager_email
                price_type
                stat_type
            /]
        }
    );

    $c->stash(title_row => $title_row);
}

#/////////////////////////////////////////////////////////////////////
sub index :Chained('_title') :PathPart('') :Args(0)
{
    my ($self, $c) = @_;

    my $filter = $self->get_filter($c);
    my $title  = { $c->stash->{title_row}->get_columns };

    $c->stash->{filter}         = $filter;
    $c->stash->{title}          = $title;
    $c->stash->{data}           = get_statistics($c, $filter);
    $c->stash->{banner_formats} = get_banner_formats($c);
    $c->stash->{products}       = get_products($c);
    $c->stash->{channel_groups} = get_channel_groups($c);
    $c->stash->{placement_targetings}   = get_placement_targetings($c);
    $c->stash->{banner_link_password} = generate_password(
        $c->config->{banner_link}->{user_password}, $c->request->address
    );
    $c->stash->{group_api_domain_name} = $c->config->{group_api_domain_name};
}

#/////////////////////////////////////////////////////////////////////
sub get_filter
{
    my ($self, $c) = @_;

    my $filter_class = 'BampoManager::Filter::CPoint';
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
sub get_statistics
{
    my ($c, $filter) = @_;

    my ($placement_rs, $stat_rs) = prepare_stat_queries($c, $filter);

    # Get placements info
    my %placements;
    foreach my $row ($placement_rs->all)
    {
        my %placement = $row->get_columns();
        my $placement_id = $placement{line_id};
        $placements{$placement_id} = \%placement;
    }

    # Get placements stat
    my $cpoint_row = $c->stash->{cpoint_row};
    my $placements_stat = get_placements_stat($stat_rs, $cpoint_row, $filter);

    # Add information to the stat objects
    my $total_stat = pop @$placements_stat;
    foreach my $placement_stat (@$placements_stat)
    {
        my $placement_id = $placement_stat->{line_id};
        my $placement_info = $placements{$placement_id};
        my @fields = keys %$placement_info;
        @{$placement_stat}{@fields} = @{$placement_info}{@fields};
        delete $placements{$placement_id};
    }

    my $result = [];
    if ($filter->show_empty)
    {
        push @$result, @$placements_stat, values %placements;
    }
    else
    {
        push @$result, @$placements_stat;
    }
    push @$result, $total_stat;

    return $result;
}

#/////////////////////////////////////////////////////////////////////
sub prepare_stat_queries
{
    my ($c, $filter) = @_;

    my $cpoint_row   = $c->stash->{cpoint_row};
    my $cpoint_id    = $cpoint_row->id;
    my $mediaplan_id = $cpoint_row->mediaplanId;

    my $placement_rs  = prepare_placement_rs($c, $mediaplan_id, $filter);
    my $stat_rs       = prepare_stat_rs($c, $cpoint_id, $filter);

    return ($placement_rs, $stat_rs);
}

#/////////////////////////////////////////////////////////////////////
sub prepare_placement_rs
{
    my ($c, $mediaplan_id, $filter) = @_;

    my $placement_rs = $c->model('Bampo::Line')->search(
        {
            'me.type'        => LINE_TYPE_ADRIVER,
            'me.mediaplanId' => $mediaplan_id,
        },
        {
            select => [qw/
                me.adId
                me.profileId
                me.title
                me.id
                me.startDate
                me.stopDate
                me.costsSourceId
                costs_source.manual
            /],
            as => [qw/
                adriver_ad_id
                adriver_profile_id
                line_title
                line_id
                start_date
                stop_date
                placement_costs_source
                costs_source_manual
            /],
            join => 'costs_source'
        }
    );

    my $alias = 'me';
    $placement_rs = extra_filter_placements($placement_rs, $filter, $alias);

    return $placement_rs;
}

#/////////////////////////////////////////////////////////////////////
sub prepare_stat_rs
{
    my ($c, $cpoint_id, $filter) = @_;

    my $stat_rs = $c->model('Bampo::Statistics')->search(
        {
            'source.type'     => LINE_TYPE_ADRIVER,
            'me.targetLineId' => $cpoint_id,
        },
        {
            join   => { 'source' => 'costs_source' },
            select => ['me.sourceLineId', 'costs_source.manual'],
            as     => [qw/line_id costs_source_manual/],
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
sub create :Path('/lines/controlpoints/create') :FormConfig {}

sub create_FORM_NOT_SUBMITTED
{
    my ($self, $c) = @_;

    my $mediaplan_id = $c->request->params->{mediaplan_id};
    $c->stash->{form}->default_values({ mediaplanId => $mediaplan_id });
}

sub create_FORM_VALID
{
    my ($self, $c) = @_;

    eval { $c->stash->{form}->model->create() };
    if (my $e = Exception::Class->caught('DBIx::Class::Exception'))
    {
        if ($e =~ /duplicate line in mediaplan/)
        {
            throw BampoManager::Exception::FormFu::DuplicateEntry(
                status   => HTTP_BAD_REQUEST,
                error    => "Duplicate control point in the mediaplan.",
                user_msg => $self->DUPLICATE_CPOINT_ERROR_MSG
            );
        }
        else
        {
            throw BampoManager::Exception::FormFu(
                status   => HTTP_INTERNAL_SERVER_ERROR,
                error    => "Database error while creating a control point: '$e'",
                user_msg => $self->INTERNAL_SERVER_ERROR_MSG
            );
        }
    }
    elsif ($e = caught Exception::Class)
    {
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Unknown error while creating a control point: '$e'",
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
sub edit :Chained('_cpoint') :PathPart('edit') :Args(0) :FormConfig
{
    my ($self, $c) = @_;
    disable_edit_form_fields($c);
}

sub edit_FORM_NOT_SUBMITTED
{
    my ($self, $c) = @_;
    $c->stash->{form}->model->default_values($c->stash->{cpoint_row});
}

sub edit_FORM_VALID
{
    my ($self, $c) = @_;

    my $form   = $c->stash->{form};
    my $cpoint = $c->stash->{cpoint_row};

    my $new_site_paid = $form->param_value('sitePaid') || 0;
    my $old_site_paid = $cpoint->sitePaid;

    my $new_max_leads = $form->param_value('priceAmount') || 0;
    my $old_max_leads = $cpoint->priceAmount || 0;

    eval {
        $form->model->update($cpoint);
        if ($cpoint->statType eq STAT_TYPE_CLIENT and $new_site_paid == 1 and $old_site_paid == 0)
        {
            update_leads_shipment_data($c, $cpoint);
        }
        if ($new_max_leads != $old_max_leads)
        {
            update_cpoint_status($c, $cpoint);
        }
    };
    if (my $e = Exception::Class->caught('DBIx::Class::Exception'))
    {
        if ($e =~ /duplicate line in mediaplan/)
        {
            throw BampoManager::Exception::FormFu::DuplicateEntry(
                status   => HTTP_BAD_REQUEST,
                error    => "Duplicate control point in the mediaplan.",
                user_msg => $self->DUPLICATE_CPOINT_ERROR_MSG
            );
        }
        elsif ($e =~ /version collision on update/)
        {
            throw BampoManager::Exception::FormFu::VersionCollision(
                status   => HTTP_BAD_REQUEST,
                error    => "Version collision while editing a control point.",
                user_msg => $self->VERSION_COLLISION_ERROR_MSG
            );
        }
        else
        {
            throw BampoManager::Exception::FormFu(
                status   => HTTP_INTERNAL_SERVER_ERROR,
                error    => "Database error while editing a control point: '$e'",
                user_msg => $self->INTERNAL_SERVER_ERROR_MSG
            );
        }
    }
    elsif ($e = caught Exception::Class)
    {
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Unknown error while editing a control point: '$e'",
            user_msg => $self->INTERNAL_SERVER_ERROR_MSG
        );
    }
}

sub edit_FORM_NOT_VALID
{
    my ($self, $c) = @_;

    my $form       = $c->stash->{form};
    my $cpoint_row = $c->stash->{cpoint_row};

    my $id_field = $form->get_all_element({ name => 'id' });
    $id_field->default($cpoint_row->id);

    $c->res->status(HTTP_BAD_REQUEST);
}

sub disable_edit_form_fields
{
    my $c = shift;
    my $form       = $c->stash->{form};
    my $cpoint_row = $c->stash->{cpoint_row};

    my $id_field = $form->get_all_element({ name => 'id' });
    $id_field->attributes->{readonly} = 1;
    $id_field->model_config->{read_only} = 1;

    my $stat_type_field = $form->get_all_element({ name => 'statType' });
    $stat_type_field->model_config->{read_only} = 1;
    disable_options($stat_type_field);
    $form->element({ name => 'statType', type => 'Hidden' });

    my $site_id_field = $form->get_all_element({ name => 'siteId' });
    $site_id_field->attributes->{readonly} = 1;
    $site_id_field->model_config->{read_only} = 1;

    my $sz_id_field = $form->get_all_element({ name => 'siteZoneId' });
    $sz_id_field->attributes->{readonly} = 1;
    $sz_id_field->model_config->{read_only} = 1;

    my $pages_field = $form->get_all_element({ name => 'leadPagesNum' });
    $pages_field->attributes->{readonly} = 1;
    $pages_field->model_config->{read_only} = 1;

    my $price_type_field = $form->get_all_element({ name => 'priceType' });
    $price_type_field->model_config->{read_only} = 1;
    disable_options($price_type_field);
    $form->element({ name => 'priceType', type => 'Hidden' });

    if (not $c->check_user_roles('admin'))
    {
        my $billing_type_field = $form->get_all_element({ name => 'billingType' });
        $billing_type_field->model_config->{read_only} = 1;
        disable_options($billing_type_field);
        $form->element({ name => 'billingType', type => 'Hidden' });

        my $start_date_field = $form->get_all_element({ name => 'startDate' });
        $start_date_field->model_config->{read_only} = 1;
        $start_date_field->attributes->{readonly} = 1;

        my $price_field = $form->get_all_element({ name => 'priceSale' });
        if (defined $cpoint_row->priceSale and $cpoint_row->priceSale != 0)
        {
            $price_field->attributes->{readonly} = 1;
            $price_field->model_config->{read_only} = 1;
        }

        my $order_number_field = $form->get_all_element({ name => 'orderNumber' });
        if (defined $cpoint_row->orderNumber  and $cpoint_row->orderNumber ne ''){
            $order_number_field->model_config->{read_only} = 1;
            $order_number_field->attributes->{readonly} = 1;
        }
    }

    sub disable_options
    {
        my $field = shift;
        my $options = $field->options;
        $_->{attributes}->{disabled} = 1 foreach @$options;
        $field->options($options);
    }
}

#/////////////////////////////////////////////////////////////////////
sub delete :Chained('_cpoint') :PathPart('delete') :Args(0)
{
    my ($self, $c) = @_;
    my $cpoint = $c->stash->{cpoint_row};
    if ($c->check_user_roles('admin') or $cpoint->target_stat->count == 0)
    {
        $cpoint->delete();
        $c->res->body('The control point has been deleted successfully.');
        $c->res->status(HTTP_OK);
    }
    else
    {
        throw BampoManager::Exception::CouldNotDeleteCPoint(
            status => HTTP_BAD_REQUEST,
            error  => "Couldn't delete the control point with statistics"
        );
    }
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
