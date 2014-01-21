package BampoManager::Model::Deflator;

use Moose;
use namespace::autoclean;
use BampoManager::TypeDeflator;

extends 'Catalyst::Model';


has deflator => (
    is => 'ro',
    isa => 'BampoManager::TypeDeflator',
    builder => '_build_deflator',
);


sub _build_deflator
{
    return BampoManager::TypeDeflator->new;
}

sub ACCEPT_CONTEXT
{
    my ($self, $c) = @_;
    return $self->deflator;
}

__PACKAGE__->meta->make_immutable;
