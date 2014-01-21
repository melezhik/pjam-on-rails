package BampoManager::Filter::Role::ListFormat;

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Storage::Engine;
use Adriver::MooseX::Types::GUID;
use BampoManager::Filter::Const qw/:LIST_FORMAT/;

has list_format => (
    is => 'ro',
    isa => enum([FORMAT_OWN, FORMAT_AGENCY, FORMAT_CLIENT, FORMAT_ALL]),
    writer => '_set_list_format',
    trigger => \&_check_related_attrs,
);

has client_id => (
    is => 'ro',
    isa => 'Adriver::MooseX::Types::GUID',
    coerce => 1,
    clearer => 'clear_client_id',
);

has agency_id => (
    is => 'ro',
    isa => 'Adriver::MooseX::Types::GUID',
    coerce => 1,
    clearer => 'clear_agency_id',
);


after BUILDALL => sub {
    my $self = shift;

    # make sure that triget _check_related_attrs has been called
    $self->_set_list_format($self->list_format);
};

around unpack => sub {
    my $orig = shift;
    my $class = shift;

    my $self = $class->$orig(@_);
    # make sure that triget _check_related_attrs has been called
    $self->_set_list_format($self->list_format);

    return $self;
};


sub _check_related_attrs
{
    my $self = shift;
    my $new_format = shift;
    my $old_format = shift;

    if ($new_format ne FORMAT_CLIENT)
    {
        $self->clear_client_id;
        $self->clear_agency_id;
    }
    elsif (not $self->client_id and not $self->agency_id)
    {
        $self->_set_list_format(FORMAT_OWN);
    }
}

MooseX::Storage::Engine->add_custom_type_handler(
    'Adriver::MooseX::Types::GUID' => (
        expand   => sub { shift },
        collapse => sub { (shift)->as_string },
    )
);


1;
