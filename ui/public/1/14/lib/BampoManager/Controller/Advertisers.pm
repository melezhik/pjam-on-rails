package BampoManager::Controller::Advertisers;

use Moose;
use namespace::autoclean;
use HTTP::Status qw/:constants/;
use BampoManager::Exceptions;
use utf8;

BEGIN { extends 'BampoManager::Controller::Base' }


#/////////////////////////////////////////////////////////////////////
sub _advertiser :Chained('/') :PathPart('advertisers') :CaptureArgs(1)
{
    my ($self, $c, $id) = @_;
    $c->stash->{advert_row} = $c->model('Bampo::Advertiser')->find($id);
    unless ($c->stash->{advert_row})
    {
        throw BampoManager::Exception::AdvertiserNotFound(
            status => HTTP_NOT_FOUND,
            error  => "Couldn't find advertiser with id='$id'"
        );
    }
}

#/////////////////////////////////////////////////////////////////////
sub index :Path
{
    my ($self, $c) = @_;

    my $filter_class = 'BampoManager::Filter::Advertisers';
    my $filter = $self->get_page_filter($c, $filter_class);

    my @rows = $c->model('Bampo::Agency')->search(undef, { order_by => 'title' });

    my $agency_row;
    if (defined $filter->agency_id)
    {
        my $agency_id = $filter->agency_id->as_string;
        ($agency_row) = grep { uc($_->id) eq $agency_id } @rows;
    }
    elsif (@rows)
    {
        # just take the first one
        $agency_row = $rows[0];
    }
    $c->stash->{agencies} = [ map +{ $_->get_columns }, @rows ];

    if (defined $agency_row)
    {
        my @client_rows = ($filter->hide_archived) ?
            $agency_row->search_related('clients', { archived => 0 }) : $agency_row->clients;
        $c->stash->{clients} = [ map +{ $_->get_columns }, @client_rows ];
        $filter->agency_id($agency_row->id);
    }
    else
    {
        $c->stash->{clients} = [];
        $filter->clear_agency_id;
    }

    $self->set_page_filter($c, $filter_class, $filter);
    $c->stash->{filter} = $filter;
}

#/////////////////////////////////////////////////////////////////////
sub create :Local :FormConfig('advertiser/create.yaml') {}

sub create_FORM_NOT_SUBMITTED
{
    my ($self, $c) = @_;

    my $default_agency_id = $c->request->params->{agency_id} || $c->user->get('agencyId');
    $c->stash->{form}->default_values({ agencyId => $default_agency_id });
}

sub create_FORM_VALID
{
    my ($self, $c) = @_;

    eval { $c->stash->{form}->model->create() };
    if (my $e = caught Exception::Class)
    {
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Unknown error while creating an advertiser: '$e'",
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
sub edit :Chained('_advertiser') :PathPart('edit') :Args(0) :FormConfig('advertiser/edit.yaml') {}

sub edit_FORM_NOT_SUBMITTED
{
    my ($self, $c) = @_;
    $c->stash->{form}->model->default_values($c->stash->{advert_row});
}

sub edit_FORM_VALID
{
    my ($self, $c) = @_;

    my $form = $c->stash->{form};
    my $obj  = $c->stash->{advert_row};

    eval { $form->model->update($obj) };
    if (my $e = Exception::Class->caught('DBIx::Class::Exception'))
    {
        if ($e =~ /version collision on update/){
            throw BampoManager::Exception::FormFu::VersionCollision(
                status   => HTTP_BAD_REQUEST,
                error    => "Version collision while editing an advertiser.",
                user_msg => $self->VERSION_COLLISION_ERROR_MSG
            );
        }elsif( $e =~ /Duplicate entry \'(.+)\' for key \'Advertiser_username\'/ ){
            throw BampoManager::Exception::FormFu(
                status   => HTTP_INTERNAL_SERVER_ERROR,
                error    => "Database error while editing an advertiser: '$e'",
                user_msg => 'Клиент с таким логином уже существует.'
            );
        }else
        {
            throw BampoManager::Exception::FormFu(
                status   => HTTP_INTERNAL_SERVER_ERROR,
                error    => "Database error while editing an advertiser: '$e'",
                user_msg => $self->INTERNAL_SERVER_ERROR_MSG
            );
        }
    }
    elsif ($e = caught Exception::Class)
    {
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Unknown error while editing an advertiser: '$e'",
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
sub delete :Chained('_advertiser') :PathPart('delete') :Args(0)
{
    my ($self, $c) = @_;
    my $advertiser = $c->stash->{advert_row};

    my $mediaplans_counter = $c->model('Bampo::Mediaplan')->search({ advertiserId => $advertiser->id })->count;
    if ($mediaplans_counter)
    {
        throw BampoManager::Exception::CouldNotDeleteAdvertiser(
            status => HTTP_BAD_REQUEST,
            error  => "Couldn't delete advertiser which has active mediaplans"
        );
    }
    else
    {
        $advertiser->delete();
        $c->res->body('The advertisers has been deleted successfully.');
        $c->res->status(HTTP_OK);
    }
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
