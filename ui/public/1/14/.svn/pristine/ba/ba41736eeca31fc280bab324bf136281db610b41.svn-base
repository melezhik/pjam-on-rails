package BampoManager::Filter::CPoint;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use BampoManager::Filter::Const qw/:PLACEMENT_LIST_FORMAT/;

extends 'BampoManager::Filter';

with (
    'BampoManager::Filter::Role::Sortable',
    'BampoManager::Filter::Role::StatPeriod',
    'BampoManager::Filter::Role::ExtraPlacements',
);

has '+sorted_column' => (
    default => 'name',
);

has show_empty => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has list_format => (
    is => 'ro',
    isa => enum([FORMAT_CAMPAIGN, FORMAT_PROFILE, FORMAT_BANNER]),
    default => FORMAT_CAMPAIGN,
);


__PACKAGE__->meta->make_immutable;
