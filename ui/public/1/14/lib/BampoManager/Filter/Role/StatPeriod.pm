package BampoManager::Filter::Role::StatPeriod;

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use MooseX::Storage;
use DateTime;
use Adriver::MooseX::Types::Date;
use BampoManager::Filter::Const qw/:STAT_PERIOD/;

with Storage;


has stat_period => (
    is => 'ro',
    isa => enum([
        PERIOD_TODAY,
        PERIOD_YESTERDAY,
        PERIOD_WEEK,
        PERIOD_MONTH,
        PERIOD_CUR_MONTH,
        PERIOD_LAST_MONTH,
        PERIOD_CUSTOM,
    ]),
    default => PERIOD_TODAY,
    writer => '_set_stat_period',
    trigger => \&_calc_stat_period,
);

has start_date => (
    is => 'ro',
    isa => 'Adriver::MooseX::Types::Date',
    coerce => 1,
    writer => '_set_start_date',
);

has stop_date => (
    is => 'ro',
    isa => 'Adriver::MooseX::Types::Date',
    coerce => 1,
    writer => '_set_stop_date',
);

after BUILDALL => sub {
    my $self = shift;

    # Make sure that triget _calc_stat_period has been called
    # even when default value was used
    $self->_set_stat_period($self->stat_period);
};

around unpack => sub {
    my $orig = shift;
    my $class = shift;

    my $self = $class->$orig(@_);
    # Make sure that triget _calc_stat_period has been called
    $self->_set_stat_period($self->stat_period);

    return $self;
};

sub set_stat_period
{
    my $self = shift;
    my ($period, $start_dt, $stop_dt) = pos_validated_list(\@_,
        { isa => 'Str' },
        { isa => 'Adriver::MooseX::Types::Date', coerce => 1, optional => 1 },
        { isa => 'Adriver::MooseX::Types::Date', coerce => 1, optional => 1 },
    );

    $self->_set_stat_period($period);
    if ($self->stat_period eq PERIOD_CUSTOM)
    {
        $start_dt = $start_dt || DateTime->today();
        $stop_dt  = $stop_dt  || DateTime->today();
        $self->_set_start_date($start_dt);
        $self->_set_stop_date($stop_dt);
    }
}

sub copy_stat_period
{
    my $self = shift;
    my ($obj) = pos_validated_list(\@_,
        { does => 'BampoManager::Filter::Role::StatPeriod' },
    );

    $self->_set_stat_period($obj->stat_period);
    $self->_set_start_date($obj->start_date) if defined $obj->start_date;
    $self->_set_stop_date($obj->stop_date) if defined $obj->stop_date;
}

sub _calc_stat_period
{
    my $self = shift;
    my $new_period = shift;
    my $old_period = shift;

    my $today = DateTime->today();

    if ($new_period eq PERIOD_TODAY)
    {
        $self->_set_start_date($today->clone);
        $self->_set_stop_date($today->clone);
    }
    elsif ($new_period eq PERIOD_YESTERDAY)
    {
        my $yesterday = $today->clone->subtract(days => 1);
        $self->_set_start_date($yesterday);
        $self->_set_stop_date($yesterday->clone);
    }
    elsif ($new_period eq PERIOD_WEEK)
    {
        my $start_dt = $today->clone->subtract(days => 6);
        $self->_set_start_date($start_dt);
        $self->_set_stop_date($today->clone);
    }
    elsif ($new_period eq PERIOD_MONTH)
    {
        my $start_dt = $today->clone->subtract(days => 29);
        $self->_set_start_date($start_dt);
        $self->_set_stop_date($today->clone);
    }
    elsif ($new_period eq PERIOD_CUR_MONTH)
    {
        my $start_dt = $today->clone->truncate(to => 'month');
        $self->_set_start_date($start_dt);
        $self->_set_stop_date($today->clone);
    }
    elsif ($new_period eq PERIOD_LAST_MONTH)
    {
        my $start_dt = $today->clone->subtract(months => 1)->truncate(to => 'month');
        my $stop_dt  = DateTime->last_day_of_month(
            month => $start_dt->month,
            year  => $start_dt->year
        );
        $self->_set_start_date($start_dt);
        $self->_set_stop_date($stop_dt);
    }
    elsif ($new_period eq PERIOD_CUSTOM)
    {
        # do nothing here
    }
}

MooseX::Storage::Engine->add_custom_type_handler(
    'Adriver::MooseX::Types::Date' => (
        expand   => sub { shift },
        collapse => sub { (shift)->strftime("%F") },
    )
);

1;
