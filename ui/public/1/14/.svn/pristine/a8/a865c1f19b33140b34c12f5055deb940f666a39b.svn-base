package BampoManager::Controller::REST::GetProfileByPlacements;

use Moose;
use namespace::autoclean;
use HTTP::Status qw/:constants/;
use Scalar::Util qw/blessed/;
use BampoManager::Exceptions;
use Adriver::Mime::Types::Constants qw/ :all /;
use List::AllUtils qw( uniq );

use constant {
    AD_TYPE    => 'simple',
    NETAD_TYPE => 'network'
};

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
    unless ($c->forward('root','auth') ){
        throw BampoManager::Exception::UnAuthorized(
            status   => HTTP_UNAUTHORIZED,
            error    => "Access denied",
        );
    }
    $c->forward('deserialize');
}


sub _create_placements_profiles :Chained('') PathPart('create_placements_profiles') :CaptureArgs(0) {}

sub create_placements_profiles :Chained('_create_placements_profiles') :PathPart('') :Args(0) :ActionClass('REST') {}

sub create_placements_profiles_POST{
    my ($self, $c) = @_;

    my $result = {};

    my $lines = $c->req->data->{lines};
    throw BampoManager::Exception::BadRequest( error => 'lines must be ARRAY ' , status => HTTP_BAD_REQUEST)
        unless (ref $lines eq 'ARRAY' );


    my $res_lines = $c->model('Bampo::Line::Adriver')->search({
        id => $lines,
    });

    my $profile_ids = [];

    while( my $line = $res_lines->next ){

        if( $line->profileId ){
            push @$profile_ids, $line->profileId;
        }elsif( $line->adId ){
            if( $line->adType eq AD_TYPE ){
                eval{
                    my $ad = $c->model('Adriver')->ad( $line->adId );
                    push @$profile_ids , @{$ad->profiles};
                };
                if(my $e = Exception::Class->caught ){
                    $c->log->warn((ref $e)?$e->error:$e);
                }
            }elsif( $line->adType eq NETAD_TYPE){
                eval{
                    my $net_ad = $c->model('Adriver')->net_ad( $line->adId );
                    push @$profile_ids , @{$net_ad->profiles};
                };
                if(my $e = Exception::Class->caught ){
                    $c->log->warn((ref $e)?$e->error:$e);
                }
            }
        }
    }

    my @sort_profiles_ids = sort { $a <=> $b } @$profile_ids;
    my @uniq_profiles_ids = uniq(@sort_profiles_ids);

    my $data = { 
        type => $GROUP_PROFILE_TYPE,
        ids => \@uniq_profiles_ids
    };

    my $item;
    eval{
       $item = $c->model('API')->api->create($data,'temporary');
    };
    if (my $e = caught Exception::Class)
    {
        throw BampoManager::Exception::Catalog( error => " Some error occured while creating resource.Reasone:$e .");
    }

    $self->status_created($c, location => $c->req->uri->as_string, entity => {data => $item->value , GUID => $item->GUID});
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
