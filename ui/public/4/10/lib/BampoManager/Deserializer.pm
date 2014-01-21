package BampoManager::Deserializer;

use Moose;
use Class::MOP;
use MooseX::Params::Validate;
use MooseX::Storage::Engine;
use MooseX::Storage::Util;
use namespace::autoclean;


has class_marker => (
    is => 'rw',
    isa => 'Str',
    default => '__CLASS__'
);

sub deserialize
{
    my ($self, $packed) = pos_validated_list(\@_,
        { isa => __PACKAGE__ },
        { isa => 'HashRef' },
    );

    local $MooseX::Storage::Engine::CLASS_MARKER = $self->class_marker;
    my $class = MooseX::Storage::Util->peek($packed);
    Class::MOP::load_class($class);
    return $class->unpack($packed);
}

__PACKAGE__->meta->make_immutable;
