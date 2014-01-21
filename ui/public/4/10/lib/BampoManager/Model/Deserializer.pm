package BampoManager::Model::Deserializer;

use Moose;
use namespace::autoclean;
use BampoManager::Deserializer;

extends 'Catalyst::Model';


has deserializer => (
    is => 'ro',
    isa => 'BampoManager::Deserializer',
    builder => '_build_deserializer',
);


sub _build_deserializer
{
    return new BampoManager::Deserializer;
}

sub ACCEPT_CONTEXT
{
    my ($self, $c) = @_;
    return $self->deserializer;
}


__PACKAGE__->meta->make_immutable;
