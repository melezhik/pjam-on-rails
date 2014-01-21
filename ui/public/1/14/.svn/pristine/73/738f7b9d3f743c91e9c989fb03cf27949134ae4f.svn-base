package BampoManager::FormFu::Validator::ClientStat::Amount;

use strict;
use warnings;

use base 'HTML::FormFu::Validator';

#/////////////////////////////////////////////////////////////////////
sub validate_value
{
    my ($self, $value, $params) = @_;

    my $result = 1;
    my $c = $self->form->stash->{context};

    # we don't allow to save null values
    if (not $params->{reload_form} and $value eq '')
    {
        $result = 0;
    }

    return $result;
}

#/////////////////////////////////////////////////////////////////////

1;
