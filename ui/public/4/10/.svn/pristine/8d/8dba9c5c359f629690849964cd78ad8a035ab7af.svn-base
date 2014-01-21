package BampoManager::Filter::Mediaplans;

use Moose;
use BampoManager::Filter::Const;
use namespace::autoclean;

extends 'BampoManager::Filter';

with (
    'BampoManager::Filter::Role::Sortable',
    'BampoManager::Filter::Role::ListFormat',
);

has '+sorted_column' => (
    default => 'title',
);

has '+list_format' => (
    default => BampoManager::Filter::Const::FORMAT_OWN,
);

has hide_archived => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
);

__PACKAGE__->meta->make_immutable;
