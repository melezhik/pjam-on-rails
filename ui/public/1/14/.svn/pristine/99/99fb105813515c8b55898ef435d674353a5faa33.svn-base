package BampoManager::FormFu::Validator::Placement::Profile;

use strict;
use warnings;

use base 'HTML::FormFu::Validator';

#/////////////////////////////////////////////////////////////////////
sub validate_value
{
    my ($self, $value, $params) = @_;

    my $result = 1;
    my $c = $self->form->stash->{context};

    # This parameter is not mandatory, so check if it was set
    if (defined $value and $value ne "")
    {
        my $profile = eval { $c->model('Adriver')->profile($value); };
        if ($@)
        {
            my $error = $@;
            if ($error =~ /not found/)
            {
                $c->log->error("Couldn't create a placement: '$error'");
            }
            else
            {
                $c->log->error("Couldn't check if exists profileId=$value. Skip checking. Unknown exception: '$error'");
            }
            $result = 0;
        }
    }

    return $result;
}

#/////////////////////////////////////////////////////////////////////

1;
