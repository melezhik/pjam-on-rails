package BampoManager::Filter::ControlPoints;

use Moose;
use BampoManager::Filter::Const;
use namespace::autoclean;

extends 'BampoManager::Filter';

with (
    'BampoManager::Filter::Role::Sortable',
    'BampoManager::Filter::Role::ListFormat',
    'BampoManager::Filter::Role::StatPeriod',
    'BampoManager::Filter::Role::ExtraPlacements',
    'BampoManager::Filter::Role::ExtraCPoints',
);

has '+sorted_column' => (
    default => 'line_title',
);

has '+list_format' => (
    default => BampoManager::Filter::Const::FORMAT_OWN,
);

has show_empty => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);


__PACKAGE__->meta->make_immutable;
