package BampoManager::Model::Holidays;

use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;
use Adriver::MooseX::Types::Date;
use Adriver::Date::Holidays;
use BampoManager::Exceptions;

extends 'Catalyst::Model';

has holy => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has work => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has api => (
    is => 'ro',
    isa => 'Adriver::Date::Holidays',
    lazy_build => 1,
);


#/////////////////////////////////////////////////////////////////////
sub _build_api
{
    my $self = shift;
    return Adriver::Date::Holidays->new({ holy => $self->holy, work => $self->work });
}

#/////////////////////////////////////////////////////////////////////
sub is_holiday
{
    my ($self, $date) = pos_validated_list( \@_,
        { isa => __PACKAGE__ },
        { isa => 'Adriver::MooseX::Types::Date', coerce => 1 },
    );

    return $self->api->is_holiday($date);
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
