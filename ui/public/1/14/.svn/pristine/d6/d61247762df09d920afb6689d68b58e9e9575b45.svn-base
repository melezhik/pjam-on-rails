package BampoManager::Model::Adriver;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

use Adriver::API;
use Adriver::API::Ad;
use Adriver::API::NetAd;
use Adriver::API::Site;
use Adriver::API::User;
use Adriver::API::Profile;
use Adriver::API::Banner;
use utf8;


has host => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has port => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

has api => (
    is => 'ro',
    isa => 'Adriver::API',
    lazy_build => 1,
);

sub _build_api
{
    my $self = shift;
    return Adriver::API->new({ host => $self->host, port => $self->port });
}

#/////////////////////////////////////////////////////////////////////
sub ad
{
    my ($self, $id) = @_;
    my $ad = Adriver::API::Ad->new(id => $id);
    $self->api->ad->read($ad);
    return $ad;
}

#/////////////////////////////////////////////////////////////////////
sub profile
{
    my ($self, $id) = @_;
    my $profile = Adriver::API::Profile->new(id => $id);
    $self->api->profile->read($profile);
    return $profile;
}

#/////////////////////////////////////////////////////////////////////
sub banner
{
    my ($self, $id) = @_;
    my $banner = Adriver::API::Banner->new(id => $id);
    $self->api->banner->read($banner);
    return $banner;
}

#/////////////////////////////////////////////////////////////////////
sub get_banner_comment
{
    my ($self, $banner_id) = @_;

    my $comment = $self->banner($banner_id)->comment;
    $comment =~ s/Креатив://;
    $comment =~ s/\s*\(ID:\d+\)\s*//;
    $comment =~ s/\s*Copied from banner #\d+\s*//g;

    return $comment;
}

#/////////////////////////////////////////////////////////////////////
sub net_ad
{
    my ($self, $id) = @_;
    my $net_ad = Adriver::API::NetAd->new(id => $id);
    $self->api->net_ad->read($net_ad);
    return $net_ad;
}

#/////////////////////////////////////////////////////////////////////
sub site
{
    my ($self, $id) = @_;
    my $site = Adriver::API::Site->new(id => $id);
    $self->api->site->read($site);
    return $site;
}

#/////////////////////////////////////////////////////////////////////
sub user
{
    my ($self, $id) = @_;
    my $user = Adriver::API::User->new(id => $id);
    $self->api->user->read($user);
    return $user;
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
