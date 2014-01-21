package BampoManager::Filter::Advertisers;

use Moose;
use MooseX::Storage::Engine;
use Adriver::MooseX::Types::GUID;
use namespace::autoclean;
use BampoManager::Filter::Const;

extends 'BampoManager::Filter';

with (
    'BampoManager::Filter::Role::Sortable',
);

has '+sorted_column' => (
    default => 'title',
);

has agency_id => (
    is => 'rw',
    isa => 'Adriver::MooseX::Types::GUID',
    coerce => 1,
    clearer => 'clear_agency_id',
);

has hide_archived => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
);

MooseX::Storage::Engine->add_custom_type_handler(
    'Adriver::MooseX::Types::GUID' => (
        expand   => sub { shift },
        collapse => sub { (shift)->as_string },
    )
);


__PACKAGE__->meta->make_immutable;
