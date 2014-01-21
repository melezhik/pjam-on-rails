package BampoManager::Filter::Role::ExtraPlacements;

use Moose::Role;
use MooseX::Params::Validate;

has advert_name => (
    is => 'ro',
    isa => 'Str',
    writer => '_set_advert_name',
    clearer => '_clear_advert_name',
    predicate => 'has_advert_name',
);

has banner_format_id => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    writer => '_set_banner_format_id',
    clearer => '_clear_banner_format_id',
    predicate => 'has_banner_format_id',
);

has product_id => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    writer => '_set_product_id',
    clearer => '_clear_product_id',
    predicate => 'has_product_id',
);

has channel_group_id => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    writer => '_set_channel_group_id',
    clearer => '_clear_channel_group_id',
    predicate => 'has_channel_group_id',
);

has placement_targeting_id => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    writer => '_set_placement_targeting_id',
    clearer => '_clear_placement_targeting_id',
    predicate => 'has_placement_targeting_id',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = (ref($_[0]) eq 'HASH') ? shift : { @_ };
    if (exists $args->{banner_format_id} and not ref($args->{banner_format_id}))
    {
        $args->{banner_format_id} = [ $args->{banner_format_id} ];
    }

    if (exists $args->{product_id} and not ref($args->{product_id}))
    {
        $args->{product_id} = [ $args->{product_id} ];
    }

    if (exists $args->{channel_group_id} and not ref($args->{channel_group_id}))
    {
        $args->{channel_group_id} = [ $args->{channel_group_id} ];
    }

    if (exists $args->{placement_targeting_id} and not ref($args->{placement_targeting_id}))
    {
        $args->{placement_targeting_id} = [ $args->{placement_targeting_id} ];
    }

    return $class->$orig($args);
};

around unpack => sub {
    my $orig  = shift;
    my $class = shift;
    my $args  = shift;

    if (exists $args->{banner_format_id} and not ref($args->{banner_format_id}))
    {
        $args->{banner_format_id} = [ $args->{banner_format_id} ];
    }

    if (exists $args->{product_id} and not ref($args->{product_id}))
    {
        $args->{product_id} = [ $args->{product_id} ];
    }

    if (exists $args->{channel_group_id} and not ref($args->{channel_group_id}))
    {
        $args->{channel_group_id} = [ $args->{channel_group_id} ];
    }

    if (exists $args->{placement_targeting_id} and not ref($args->{placement_targeting_id}))
    {
        $args->{placement_targeting_id} = [ $args->{placement_targeting_id} ];
    }

    return $class->$orig($args);
};

sub is_used_placement_extra_filter
{
    my $self = shift;
    return ($self->advert_name or $self->banner_format_id or $self->product_id or $self->channel_group_id or $self->placement_targeting_id);
}

sub copy_placement_extra_filter
{
    my $self = shift;
    my ($obj) = pos_validated_list(\@_,
        { does => 'BampoManager::Filter::Role::ExtraPlacements' },
    );

    if ($obj->has_advert_name)
    {
        $self->_set_advert_name($obj->advert_name);
    }
    elsif ($self->has_advert_name)
    {
        $self->_clear_advert_name;
    }

    if ($obj->has_banner_format_id)
    {
        $self->_set_banner_format_id($obj->banner_format_id);
    }
    elsif ($self->has_banner_format_id)
    {
        $self->_clear_banner_format_id;
    }

    if ($obj->has_product_id)
    {
        $self->_set_product_id($obj->product_id);
    }
    elsif ($self->has_product_id)
    {
        $self->_clear_product_id;
    }

    if ($obj->has_channel_group_id)
    {
        $self->_set_channel_group_id($obj->channel_group_id);
    }
    elsif ($self->has_channel_group_id)
    {
        $self->_clear_channel_group_id;
    }

     if ($obj->has_placement_targeting_id)
    {
        $self->_set_placement_targeting_id($obj->placement_targeting_id);
    }
    elsif ($self->has_placement_targeting_id)
    {
        $self->_clear_placement_targeting_id;
    }
}


1;
