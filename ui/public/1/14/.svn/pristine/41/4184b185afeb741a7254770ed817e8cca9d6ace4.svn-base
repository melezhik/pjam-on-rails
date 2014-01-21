package BampoManager::FormFu::Validator::Placement::Ad;

use strict;
use warnings;

use base 'HTML::FormFu::Validator';

#/////////////////////////////////////////////////////////////////////
sub validate_value
{
    my ($self, $value, $params) = @_;

    my $result = 1;
    my $c = $self->form->stash->{context};

    my $ad;
    eval
    {
        if ($params->{adType} eq 'network')
        {
            $ad = $c->model('Adriver')->net_ad($value);
        }
        else #($params->{adType} eq 'simple')
        {
            $ad = $c->model('Adriver')->ad($value);
        }
    };
    if ($@)
    {
        my $error = $@;
        if ($error =~ /not found/)
        {
            $c->log->error("Couldn't create a placement: '$error'");
        }
        else
        {
            $c->log->error("Couldn't check if exists adId=$value. Skip checking. Unknown exception: '$error'");
        }
        $result = 0;
    }

    return $result;
}

#/////////////////////////////////////////////////////////////////////

1;
