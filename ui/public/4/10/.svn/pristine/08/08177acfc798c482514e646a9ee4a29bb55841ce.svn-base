package BampoManager::Model::CRMSoloway;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

use Params::Validate qw/:all/;
use DBI;
use DateTime;
use BampoManager::Exceptions;
use BampoManager::Schema::Const qw/:PRICE_TYPE/;


validation_options(
    on_fail => sub {
        BampoManager::Exception->throw(error => $_[0]);
    },
);

has connect_info => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has dbh => (
    is => 'ro',
    isa => 'Object',
    lazy_build => 1,
);


#/////////////////////////////////////////////////////////////////////
sub _build_dbh
{
    my $self = shift;
    return $self->connect($self->connect_info);
}

#/////////////////////////////////////////////////////////////////////
sub connect
{
    my ($self, $conf) = validate_pos(@_,
        { type => OBJECT, isa => __PACKAGE__ },
        { type => HASHREF },
    );

    # Validate configuration hash
    my %config = validate_with(
        params => $conf,
        spec   => {
            dsn        => { type => SCALAR },
            user       => { type => SCALAR },
            password   => { type => SCALAR },
            attributes => { type => HASHREF, optional => 1 },
        },
        allow_extra => 1,
        called => 'The <connect> method in the package <'.__PACKAGE__.'>',
    );

    my $attributes = { AutoCommit => 1 };
    $attributes = { %$attributes, %{$config{attributes}} } if exists $config{attributes};

    my $dbh = DBI->connect_cached($config{dsn}, $config{user}, $config{password}, $attributes);

    return $dbh;
}

#/////////////////////////////////////////////////////////////////////
sub get_leads_for_period
{
    my ($self, $line_id, $start_date, $stop_date) = validate_pos(@_,
        { type => OBJECT, isa => __PACKAGE__ },
        { type => SCALAR },
        { type => OBJECT, isa => 'DateTime' },
        { type => OBJECT, isa => 'DateTime' },
    );

    my ($leads) = $self->dbh->selectrow_array('call leads_for_period(?, ?, ?)', undef,
        $line_id, $start_date, $stop_date) or
        die "CRMSoloway Model Error: couldn't call leads_for_period procedure: '" . $self->dbh->errstr . "'";

    return $leads;
}

#/////////////////////////////////////////////////////////////////////
sub update_leads_shipment_data
{
    my ($self, $line, $start_date, $stop_date, $leads) = validate_pos(@_,
        { type => OBJECT, isa => __PACKAGE__ },
        { type => OBJECT, isa => 'BampoManager::Schema::Line::Pixel' },
        { type => OBJECT, isa => 'DateTime' },
        { type => OBJECT, isa => 'DateTime' },
        { type => SCALAR, regex => qr/^(-)?\d+$/ },
    );

    if ($leads and defined $line->priceSale and $line->priceSale != 0)
    {
        my $leads_type = $self->define_leads_type($line->priceType);
        my $max_leads = $line->priceAmount || 0;
        my ($status) = $self->dbh->selectrow_array('call update_leads_shipment_data3(?, ?, ?, ?, ?, ?, ?, ?)', undef,
            $line->id, $start_date, $stop_date, $leads_type, $leads, $line->priceSale, $line->supercom, $max_leads) or
            die "CRMSoloway Model Error: couldn't call update_leads_shipment_data3 procedure: '" . $self->dbh->errstr . "'";

        unless ($status =~ /success/)
        {
            die "CRMSoloway Model Error: update_leads_shipment_data3: '$status'";
        }
    }

    return undef;
}

#/////////////////////////////////////////////////////////////////////
sub define_leads_type
{
    my ($self, $price_type) = validate_pos(@_,
        { type => OBJECT, isa => __PACKAGE__ },
        { type => SCALAR },
    );

    my $leads_type;
    if ($price_type eq PRICE_TYPE_CPV)
    {
        $leads_type = 'leads_reach';
    }
    elsif ($price_type eq PRICE_TYPE_CPL)
    {
        $leads_type = 'leads';
    }
    else  #($price_type eq PRICE_TYPE_CPA or $price_type eq PRICE_TYPE_CPC)
    {
        $leads_type = 'leads_nu';
    }

    return $leads_type;
}

#/////////////////////////////////////////////////////////////////////
sub get_total_leads
{
    my ($self, $line_id) = validate_pos(@_,
        { type => OBJECT, isa => __PACKAGE__ },
        { type => SCALAR },
    );

    my ($total_leads) = $self->dbh->selectrow_array('call lead_shipment_data_total(?)', undef, $line_id) or
        die "CRMSoloway Model Error: couldn't call lead_shipment_data_total function: '" . $self->dbh->errstr . "'";

    return $total_leads;
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
