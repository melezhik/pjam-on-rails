package BampoManager::Filter::Mediaplan;

use Moose;
use BampoManager::Filter::Const;
use namespace::autoclean;

extends 'BampoManager::Filter';

with (
    'BampoManager::Filter::Role::Sortable',
    'BampoManager::Filter::Role::StatPeriod',
    'BampoManager::Filter::Role::ExtraPlacements',
    'BampoManager::Filter::Role::ExtraCPoints',
);

has '+sorted_column' => (
    default => 'line_title',
);

__PACKAGE__->meta->make_immutable;
