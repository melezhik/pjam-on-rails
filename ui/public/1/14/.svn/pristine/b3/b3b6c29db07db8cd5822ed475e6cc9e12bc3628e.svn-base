package BampoManager::Model::Serializer;

use Moose;
use namespace::autoclean;
use BampoManager::Serializer;

extends 'Catalyst::Model';


has serializer => (
    is => 'ro',
    isa => 'BampoManager::Serializer',
    builder => '_build_serializer',
);


sub _build_serializer
{
    return new BampoManager::Serializer;
}

sub ACCEPT_CONTEXT
{
    my ($self, $c) = @_;
    return $self->serializer;
}


__PACKAGE__->meta->make_immutable;
