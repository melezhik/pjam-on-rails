package BampoManager::Controller::REST;

use Moose;
use namespace::autoclean;
use HTTP::Status qw/:constants/;
use Scalar::Util qw/blessed/;
use BampoManager::Exceptions;

BEGIN { extends 'Catalyst::Controller::REST' }


__PACKAGE__->config(
    default => 'application/json',
    map => {
        'application/json' => 'JSON',
    },
);

sub deserialize :ActionClass('Deserialize') {}

sub serialize :ActionClass('Serialize') {}

#/////////////////////////////////////////////////////////////////////
sub begin :Private
{
    my ($self, $c) = @_;
    $c->forward('auth');
    $c->forward('deserialize');
}

#/////////////////////////////////////////////////////////////////////
sub auth :Private
{
    my ($self, $c) = @_;

    return if $c->user_exists;

    my $login    = $c->req->header('X-Auth-Login')    || $c->req->params->{login};
    my $password = $c->req->header('X-Auth-Password') || $c->req->params->{password};
    $c->log->info("REST AUTH: LOGIN='$login'");

    my $authenticated = eval { $c->authenticate({ username => $login, password => $password }) };
    if (my $e = caught Exception::Class)
    {
        throw BampoManager::Exception(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Unknown error in REST authentication precess: '$e'",
        );
    }

    if (not $authenticated)
    {
        throw BampoManager::Exception::UnAuthorized(
            status   => HTTP_UNAUTHORIZED,
            error    => "REST LOGIN FAILED: bad login ($login) or password.",
        );
    }
    elsif (not defined $c->user->get('username'))
    {
        $c->logout();
        throw BampoManager::Exception::BadRequest(
            status   => HTTP_BAD_REQUEST,
            error    => "REST LOGIN FAILED: user ($login) doesn't exist in the internal database.",
        );
    }
}

#/////////////////////////////////////////////////////////////////////
sub end :Private
{
    my ($self, $c) = @_;
    my @errors = @{$c->error};
    my $e;

    if (scalar @errors > 1)
    {
        my $e_msg = join ";; ", @errors;
        $c->log->error("Caught multiple (" . scalar(@errors) . ") exceptions [$e_msg]");
        $e = BampoManager::Exception->new($e_msg);
    }
    elsif (scalar @errors == 1)
    {
        $e = shift @errors;
        $c->log->error("Caught exception '" . ref($e) . "' [$e]");
        unless (blessed($e) and $e->isa('BampoManager::Exception'))
        {
            $c->log->debug("=== TRACE ===\n" . $e->trace) if blessed($e) and $e->can('trace');
            $e = BampoManager::Exception->new("$e");
        }
    }
    $c->clear_errors;

    if (defined $e)
    {
        my $status = ($e->can('status') and defined $e->status) ? $e->status : HTTP_INTERNAL_SERVER_ERROR;
        $c->log->info("Setting status $status");
        $c->res->status($status);

        my $stash_key = $self->{stash_key};
        my $err_data  = $c->model('Deflator')->deflate($e);
        $c->stash->{$stash_key} = $err_data;
    }

    $c->forward('serialize');
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
