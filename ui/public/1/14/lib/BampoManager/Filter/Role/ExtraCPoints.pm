package BampoManager::Filter::Role::ExtraCPoints;

use Moose::Role;
use MooseX::Params::Validate;

has cpoint_name => (
    is => 'ro',
    isa => 'Str',
    writer => '_set_cpoint_name',
    clearer => '_clear_cpoint_name',
    predicate => 'has_cpoint_name',
);

has site_paid => (
    is => 'ro',
    isa => 'Bool',
    writer => '_set_site_paid',
    clearer => '_clear_site_paid',
    predicate => 'has_site_paid',
);

has geo_id => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    writer => '_set_geo_id',
    clearer => '_clear_geo_id',
    predicate => 'has_geo_id',
);


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = (ref($_[0]) eq 'HASH') ? shift : { @_ };
    if (exists $args->{geo_id} and not ref($args->{geo_id}))
    {
        $args->{geo_id} = [ $args->{geo_id} ];
    }

    return $class->$orig($args);
};

around unpack => sub {
    my $orig  = shift;
    my $class = shift;
    my $args  = shift;

    if (exists $args->{geo_id} and not ref($args->{geo_id}))
    {
        $args->{geo_id} = [ $args->{geo_id} ];
    }

    return $class->$orig($args);
};

sub is_used_cpoint_extra_filter
{
    my $self = shift;
    return ($self->cpoint_name or $self->site_paid or $self->geo_id);
}

sub copy_cpoint_extra_filter
{
    my $self = shift;
    my ($obj) = pos_validated_list(\@_,
        { does => 'BampoManager::Filter::Role::ExtraCPoints' },
    );

    if ($obj->has_cpoint_name)
    {
        $self->_set_cpoint_name($obj->cpoint_name);
    }
    elsif ($self->has_site_paid)
    {
        $self->_clear_cpoint_name;
    }

    if ($obj->has_site_paid)
    {
        $self->_set_site_paid($obj->site_paid);
    }
    elsif ($self->has_site_paid)
    {
        $self->_clear_site_paid;
    }

    if ($obj->has_geo_id)
    {
        $self->_set_geo_id($obj->geo_id);
    }
    elsif ($self->has_geo_id)
    {
        $self->_clear_geo_id;
    }
}

1;
