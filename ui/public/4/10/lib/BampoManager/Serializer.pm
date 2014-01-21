package BampoManager::Serializer;

use Moose;
use MooseX::Params::Validate;
use MooseX::Storage;
use namespace::autoclean;


has class_marker => (
    is => 'rw',
    isa => 'Str',
    default => '__CLASS__',
);

sub serialize
{
    my ($self, $object) = pos_validated_list(\@_,
        { isa => __PACKAGE__ },
        { does => Storage },
    );

    local $MooseX::Storage::Engine::CLASS_MARKER = $self->class_marker;
    return $object->pack;
}

__PACKAGE__->meta->make_immutable;
