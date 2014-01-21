package BampoManager::Controller::Root;

use Moose;
use namespace::autoclean;
use HTTP::Status qw/:constants/;

BEGIN { extends 'Catalyst::Controller' }

use constant {
    ACCESS_DENIED_HTML => 'root/static/401.html'
};

__PACKAGE__->config(namespace => '');


#/////////////////////////////////////////////////////////////////////
sub default :Path
{
    my ($self, $c) = @_;
    $c->response->status(HTTP_NOT_FOUND);
    $c->serve_static_file('root/static/404.html');
}

#/////////////////////////////////////////////////////////////////////
sub auth :Private{
    my ($self,$c) = @_;

    if( !$c->user_exists ) {
        my $mk_redirect = $c->req->header( 'CasXNoRedirect' ) ? 0 : 1;
        unless( $c->authenticate({ with_redirect => $mk_redirect ,
            ticket => $c->req->param( 'ticket' ) || undef })) {
            if( !$mk_redirect ) {
                $c->res->body( 'access denied' );
                $c->res->status( 401 );
            }

            return 0;
        }
    }else{
        my $user = $c->user;
        my $bampo_user = $c->find_user({ username => $user->username },'db');
        if($bampo_user){
            $user->{title} = $bampo_user->title;
            $user->{email} = $bampo_user->email;
            $user->{revision} = $bampo_user->revision;
            $user->{id} = $bampo_user->id;
            $user->{agencyId} = $bampo_user->agencyId;
            my $roles = [$bampo_user->roles];
            $user->{roles} = $roles;
            $c->log->info("User '".($user->username)."' allowed to use interface with roles:'@$roles' ");
        }else{
            $c->log->info("User '".($user->username)."' not allow to use interface ");
            $c->serve_static_file(ACCESS_DENIED_HTML);
        }
    }

}

#/////////////////////////////////////////////////////////////////////
sub index :Path :Args(0)
{
    my ($self, $c) = @_;
    $c->forward('root','auth');
    $c->response->redirect($c->uri_for_action('/lines/controlpoints/index'));
}

#/////////////////////////////////////////////////////////////////////
sub logout :Global
{
    my ($self, $c) = @_;
    $c->logout();

    if( $c->config->{'Plugin::Authentication'}->{default_realm} eq 'cas' ){
        my $cas_logout_uri = $c->config->{'Plugin::CasX'}->{cas_url}."/logout";
        $c->log->warn( $cas_logout_uri);
        $c->res->redirect( $cas_logout_uri );
    }

}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
