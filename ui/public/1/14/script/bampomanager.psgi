#!/usr/bin/perl

use strict;
use warnings;

use Plack::Builder;
use BampoManager;

builder {
    # enable your desired middleware here
    BampoManager->psgi_app;
};


