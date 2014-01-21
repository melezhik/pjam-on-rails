package BampoManager::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    CATALYST_VAR => 'C',
    ENCODING     => 'utf-8',
    TIMER        => 0,
    #WRAPPER      => 'site/wrapper',
    #EVAL_PERL    => 1,
);


1;
