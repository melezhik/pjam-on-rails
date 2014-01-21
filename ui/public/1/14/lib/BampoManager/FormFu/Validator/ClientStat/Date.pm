package BampoManager::FormFu::Validator::ClientStat::Date;

use strict;
use warnings;

use base 'HTML::FormFu::Validator';

use DateTime;

#/////////////////////////////////////////////////////////////////////
sub validate_value
{
    my ($self, $value, $params) = @_;

    my $result = 1;
    my $c = $self->form->stash->{context};

    my $yesterday = DateTime->now->subtract(days => 1);
    if ($value > $yesterday)
    {
        $c->log->error("It's not allowed to enter client statistics on today and future dates: $value");
        $result = 0;
    }

    return $result;
}

#/////////////////////////////////////////////////////////////////////

1;
