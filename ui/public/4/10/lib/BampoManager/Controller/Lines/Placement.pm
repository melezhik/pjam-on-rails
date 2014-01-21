package BampoManager::Controller::Lines::Placement;

use Moose;
use namespace::autoclean;
use HTTP::Status qw/:constants/;
use BampoManager::Exceptions;
use BampoManager::Costs::Exceptions;

BEGIN { extends 'BampoManager::Controller::Base' }


#/////////////////////////////////////////////////////////////////////
sub _placement :Chained('/') :PathPart('lines/placements') :CaptureArgs(1)
{
    my ($self, $c, $id) = @_;
    $c->stash->{placement_row} = $c->model('Bampo::Line')->find($id);
    unless ($c->stash->{placement_row})
    {
        throw BampoManager::Exception::PlacementNotFound(
            status => HTTP_NOT_FOUND,
            error  => "Couldn't find placement with id='$id'"
        );
    }
}

#/////////////////////////////////////////////////////////////////////
sub create :Path('/lines/placements/create') :FormConfig {}

sub create_FORM_NOT_SUBMITTED
{
    my ($self, $c) = @_;

    my $mediaplan_id = $c->request->params->{mediaplan_id};
    $c->stash->{form}->default_values({ mediaplanId => $mediaplan_id });
    initialize_costs_fieldset($c);
    initialize_select_fields($c);
}

sub create_FORM_VALID
{
    my ($self, $c) = @_;

    my $form = $c->stash->{form};
    eval
    {
        if (defined $form->param_value('costsSourceId') and defined $form->param_value('costsAccountId'))
        {
            my $source_id = $form->param_value('costsSourceId');
            my $source_api = $c->controller('REST::Costs')->get_source_api($c, $source_id);

            my $account_id     = $form->param_value('costsAccountId');
            my $campaign_id    = $form->param_value('costsCampaignId');
            my $campaign_name  = $form->param_value('costsCampaignName');
            my $placement_name = $form->param_value('costsPlacementName');

            my $account = $source_api->get_account($account_id);
            my $costs_stat_id = $account->add_placement($campaign_id, $campaign_name, $placement_name);
            my $placement_row = $form->model->create();
            $placement_row->update({ costsStatId => $costs_stat_id });
        }
        else
        {
           $form->model->create();
        }
    };
    if (my $e = Exception::Class->caught('DBIx::Class::Exception'))
    {
        initialize_costs_fieldset($c, ref($e));
        if ($e =~ /duplicate line in mediaplan/)
        {
            throw BampoManager::Exception::FormFu::DuplicateEntry(
                status   => HTTP_BAD_REQUEST,
                error    => "Duplicate placement in the mediaplan.",
                user_msg => $self->DUPLICATE_PLACEMENT_ERROR_MSG
            );
        }
        else
        {
            throw BampoManager::Exception::FormFu(
                status   => HTTP_INTERNAL_SERVER_ERROR,
                error    => "Database error while creating a placement: '$e'",
                user_msg => $self->INTERNAL_SERVER_ERROR_MSG
            );
        }
    }
    elsif ($e = Exception::Class->caught('BampoManager::Costs::Exception'))
    {
        if ($e->isa('BampoManager::Costs::Exception::DuplicateCampaign'))
        {
            initialize_costs_fieldset($c, 'BampoManager::Costs::Exception::DuplicateCampaign');
        }
        elsif ($e->isa('BampoManager::Costs::Exception::DuplicatePlacement'))
        {
            initialize_costs_fieldset($c, 'BampoManager::Costs::Exception::DuplicatePlacement');
        }
        elsif ($e->isa('BampoManager::Costs::Exception::BackendPermissionDenied'))
        {
            initialize_costs_fieldset($c, 'BampoManager::Costs::Exception::BackendPermissionDenied');
        }
        else
        {
            initialize_costs_fieldset($c, 'BampoManager::Costs::Exception');
        }
        throw BampoManager::Exception::FormFu(
            status => HTTP_BAD_REQUEST,
            error  => "Error while tuning foreign costs parameters: '$e'",
        );
    }
    elsif ($e = caught Exception::Class)
    {
        initialize_costs_fieldset($c, ref($e));
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Unknown error while creating a placement: '$e'",
            user_msg => $self->INTERNAL_SERVER_ERROR_MSG
        );
    }
}

sub create_FORM_NOT_VALID
{
    my ($self, $c) = @_;
    initialize_costs_fieldset($c);
    initialize_select_fields($c);
    $c->res->status(HTTP_BAD_REQUEST);
}

sub initialize_select_fields
{
    my $c = shift;
    my $form = $c->stash->{form};

    my $product_field = $form->get_all_element({ name => 'priceProductId' });
    my $options = get_field_options($c->model('Bampo::Product'));
    $product_field->options($options);

    my $banner_format_field = $form->get_all_element({ name => 'bannerFormatId' });
    $options = get_field_options($c->model('Bampo::BannerFormat'));
    $banner_format_field->options($options);

    my $channel_group_field = $form->get_all_element({ name => 'channelGroupId' });
    $options = get_field_options($c->model('Bampo::ChannelGroup'));
    $channel_group_field->options($options);

    my $placement_targeting_field = $form->get_all_element({ name => 'placementTargetingId' });
    $options = get_field_options($c->model('Bampo::PlacementTargeting'));
    $placement_targeting_field->options($options);
}

sub get_field_options
{
    my $rs = shift;

    my @options;
    foreach my $row ($rs->all)
    {
        my $option = { label => $row->title, value => $row->id };
        $option->{attributes} = { 'data-archived' => 1 } if $row->can('archived') and $row->archived;
        push @options, $option;
    }

    return \@options;
}

sub initialize_costs_fieldset
{
    my ($c, $err_type) = @_;

    my $form = $c->stash->{form};
    return unless defined $form;

    $err_type ||= '';
    my $account_id     = $form->param_value('costsAccountId') || '';
    my $campaign_id    = $form->param_value('costsCampaignId') || '';
    my $campaign_name  = $form->param_value('costsCampaignName') || '';
    my $placement_name = $form->param_value('costsPlacementName') || '';
    my $js_str = "window.costs_values={accountId: '$account_id', campaignId: '$campaign_id', campaignName: '$campaign_name', placementName: '$placement_name', error: '$err_type'};";
    $form->javascript($js_str);
}

#/////////////////////////////////////////////////////////////////////
sub edit :Chained('_placement') :PathPart('edit') :Args(0) :FormConfig
{
    my ($self, $c) = @_;
    disable_edit_form_fields($c);
}

sub edit_FORM_NOT_SUBMITTED
{
    my ($self, $c) = @_;
    $c->stash->{form}->model->default_values($c->stash->{placement_row});
    initialize_select_fields($c);
}

sub edit_FORM_VALID
{
    my ($self, $c) = @_;

    my $form = $c->stash->{form};
    my $obj  = $c->stash->{placement_row};

    eval { $form->model->update($obj) };
    if (my $e = Exception::Class->caught('DBIx::Class::Exception'))
    {
        if ($e =~ /duplicate line in mediaplan/)
        {
            throw BampoManager::Exception::FormFu::DuplicateEntry(
                status   => HTTP_BAD_REQUEST,
                error    => "Duplicate placement in the mediaplan.",
                user_msg => $self->DUPLICATE_PLACEMENT_ERROR_MSG
            );
        }
        elsif ($e =~ /version collision on update/)
        {
            throw BampoManager::Exception::FormFu::VersionCollision(
                status   => HTTP_BAD_REQUEST,
                error    => "Version collision while editing a placement.",
                user_msg => $self->VERSION_COLLISION_ERROR_MSG
            );
        }
        else
        {
            throw BampoManager::Exception::FormFu(
                status   => HTTP_INTERNAL_SERVER_ERROR,
                error    => "Database error while editing a placement: '$e'",
                user_msg => $self->INTERNAL_SERVER_ERROR_MSG
            );
        }
    }
    elsif ($e = caught Exception::Class)
    {
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Unknown error while editing a placement: '$e'",
            user_msg => $self->INTERNAL_SERVER_ERROR_MSG
        );
    }
}

sub edit_FORM_NOT_VALID
{
    my ($self, $c) = @_;

    my $form = $c->stash->{form};
    my $placement_row = $c->stash->{placement_row};

    my $id_field = $form->get_all_element({ name => 'id' });
    $id_field->default($placement_row->id);

    my $costs_source_field = $form->get_all_element({ name => 'costsSourceId' });
    $costs_source_field->default($placement_row->costsSourceId);

    initialize_select_fields($c);

    $c->res->status(HTTP_BAD_REQUEST);
}

sub disable_edit_form_fields
{
    my $c = shift;
    my $form = $c->stash->{form};

    my $id_field = $form->get_all_element({ name => 'id' });
    $id_field->attributes->{readonly} = 1;
    $id_field->model_config->{read_only} = 1;

    my $exp2clk = $form->get_all_element({ name => 'exp2clk' });
    $exp2clk->attributes->{disabled} = 1;
    $exp2clk->model_config->{read_only} = 1;

    if (not $c->check_user_roles('admin'))
    {
        my $costs_source_field = $form->get_all_element({ name => 'costsSourceId' });
        $costs_source_field->attributes->{disabled} = 1;
        $costs_source_field->model_config->{read_only} = 1;
    }
}

#/////////////////////////////////////////////////////////////////////
sub delete :Chained('_placement') :PathPart('delete') :Args(0)
{
    my ($self, $c) = @_;
    my $placement = $c->stash->{placement_row};

    if ($c->check_user_roles('admin') or $placement->source_stat->count == 0)
    {
        $placement->delete();
        $c->res->body('The placement has been deleted successfully.');
        $c->res->status(HTTP_OK);
    }
    else
    {
        throw BampoManager::Exception::CouldNotDeletePlacement(
            status => HTTP_BAD_REQUEST,
            error  => "Couldn't delete placement with statistics"
        );
    }
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
