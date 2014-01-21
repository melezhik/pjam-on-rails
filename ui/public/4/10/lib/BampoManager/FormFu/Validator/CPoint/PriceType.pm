package BampoManager::FormFu::Validator::CPoint::PriceType;

use strict;
use warnings;

use BampoManager::Schema::Const qw/:PRICE_TYPE/;

use base 'HTML::FormFu::Validator';

#/////////////////////////////////////////////////////////////////////
sub validate_value
{
    my ($self, $value, $params) = @_;

    my $result = 1;
    my $c = $self->form->stash->{context};

    if ($value eq PRICE_TYPE_CPC)
    {
        if ($params->{siteZoneId} != '' or $params->{leadPagesNum} != '')
        {
            $c->log->error("Couldn't create a cpoint: siteZoneId and leadPagesNum fields should be empty "
                . "when priceType == CPC");
            $result = 0;
        }
    }
    elsif ( $value eq  PRICE_TYPE_CPM)
    {
        if ($params->{url} eq '' )
        {
            $c->log->error("Couldn't create a cpoint: Url field should be set "
                . "when priceType == CPM");
            $result = 0;
        }
    }
    else
    {
        if ($params->{siteZoneId} == '' and $params->{leadPagesNum} == '')
        {
            $c->log->error("Couldn't create a cpoint: siteZoneId or leadPagesNum field should be set "
                . "when priceType != CPC and != CPM");
            $result = 0;
        }
    }

    return $result;
}

#/////////////////////////////////////////////////////////////////////

1;
