package BampoManager::Model::API;

use Moose;
use namespace::autoclean;
use MooseX::Params::Validate;
use Adriver::Dictionary::API;

extends 'Catalyst::Model';
with 'Catalyst::Component::ApplicationAttribute';

has schema => (
    is => 'ro',
    isa => 'Adriver::Dictionary::Schema',
    lazy_build => 1
);

has api => (
    is => 'ro',
    isa => 'Adriver::Dictionary::API',
    lazy_build => 1
);

#/////////////////////////////////////////////////////////////////////
sub _build_api
{
    my $self = shift;
    my $api = Adriver::Dictionary::API->new($self->schema);
    return $api;
}

#/////////////////////////////////////////////////////////////////////
sub _build_schema
{
    my $self = shift;
    my $schema = $self->_application->model('Storages::Items')->schema;
    return $schema;
}

1;

