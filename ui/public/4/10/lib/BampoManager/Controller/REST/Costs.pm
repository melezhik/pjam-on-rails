package BampoManager::Controller::REST::Costs;

use Moose;
use namespace::autoclean;
use HTTP::Status qw/:constants/;
use Scalar::Util qw/blessed/;
use BampoManager::Exceptions;
use BampoManager::Costs::Exceptions;

BEGIN { extends 'BampoManager::Controller::REST' }


has sources => (
    is => 'ro',
    isa => 'HashRef',
    reader  => '_sources',
    default => sub { {} },
);

#/////////////////////////////////////////////////////////////////////
sub _source :Chained('/') :PathPart('costs/sources') :CaptureArgs(1)
{
    my ($self, $c, $source_id) = @_;

    # doesn't need right now
    #$c->stash->{source_id}  = $source_id;
    $c->stash->{source_api} = $self->get_source_api($c, $source_id);
}

sub _account :Chained('_source') :PathPart('accounts') :CaptureArgs(1)
{
    my ($self, $c, $account_id) = @_;
    my $source_api = $c->stash->{source_api};

    my $account = $source_api->get_account($account_id);
    $c->stash(account => $account);
}

sub accounts :Chained('_source') :PathPart('accounts') :Args(0) :ActionClass('REST') {}

sub capabilities :Chained('_account') :PathPart('caps') :Args(0) :ActionClass('REST') {}

sub campaigns :Chained('_account') :PathPart('campaigns') :Args(0) :ActionClass('REST') {}

sub placement :Chained('_account') :PathPart('placement') :Args(0) :ActionClass('REST') {}

########################## Accounts Resource #########################
#/////////////////////////////////////////////////////////////////////
sub accounts_GET
{
    my ($self, $c) = @_;
    my $source_api = $c->stash->{source_api};

    my %data;
    my $accounts = $source_api->list_accounts();
    foreach my $account (@$accounts)
    {
        my $id   = $account->account_id;
        my $name = $account->account_name;
        $data{$id} = $name;
    }

    my $result = { type => 'BampoManager::Costs::Accounts', data => \%data };
    $self->status_ok($c, entity => $result);
}

######################## Capabilities Resource #######################
#/////////////////////////////////////////////////////////////////////
sub capabilities_GET
{
    my ($self, $c) = @_;

    my $account = $c->stash->{account};
    my $caps = $account->get_caps();

    my $result = { type => 'BampoManager::Costs::Account::Capabilities', data => $caps };
    $self->status_ok($c, entity => $result);
}

########################## Campaigns Resource ########################
#/////////////////////////////////////////////////////////////////////
sub campaigns_GET
{
    my ($self, $c) = @_;

    my $account = $c->stash->{account};
    my $campaigns = eval { $account->list_campaigns(); };
    if (my $e = caught BampoManager::Costs::Exception::BackendDoesNotSupportCampaigns)
    {
        throw BampoManager::Exception::Costs::CampaignsNotSupported($e->error);
    }
    elsif ($e = caught Exception::Class)
    {
        $e->rethrow if blessed($e);
        throw BampoManager::Exception::Costs("unknown exception in the costs api: '$@'");
    }

    my $result = { type => 'BampoManager::Costs::Campaigns', data => $campaigns };
    $self->status_ok($c, entity => $result);
}

########################## Placement Resource ########################
#/////////////////////////////////////////////////////////////////////
sub placement_POST
{
    my ($self, $c) = @_;

    my $account = $c->stash->{account};
    my $params  = $c->request->params;

    my $campaign_id    = $params->{campaign_id};
    my $campaign_name  = $params->{campaign_name};
    my $placement_name = $params->{placement_name};

    my $costs_stat_id = $account->add_placement($campaign_id, $campaign_name, $placement_name);

    $self->status_created(
        $c,
        location => $c->req->uri->as_string,
        entity => { type => 'BampoManager::Costs::StatID', data => $costs_stat_id->as_string },
    );
}

#/////////////////////////////////////////////////////////////////////
sub get_source_api
{
    my ($self, $c, $source_id) = @_;
    my $source_api;

    if (exists $self->_sources->{$source_id})
    {
        $source_api = $self->_sources->{$source_id};
    }
    else
    {
        my $source_row = $c->model('Bampo::CostsSource')->find($source_id);
        if (not defined $source_row)
        {
            throw BampoManager::Exception::Costs::SourceNotFound("Couldn't find costs source with id='$source_id'");
        }
        elsif (not defined $source_row->class)
        {
            my $source_name = $source_row->title;
            throw BampoManager::Exception::Costs::NoAPI("There is no API for source '$source_name' (id=$source_id)");
        }
        else
        {
            $source_api = create_source_api($c, $source_row);
            $self->_sources->{$source_id} = $source_api;
        }
    }

    return $source_api;
}

#/////////////////////////////////////////////////////////////////////
sub create_source_api
{
    my ($c, $source_row) = @_;

    my $source_name  = $source_row->title;
    my $source_class = $source_row->class;
    unless (defined $source_class)
    {
        throw BampoManager::Exception::Costs::SourceClassNotSpecified(
            error => "Source class wasn't specified for source ($source_name)"
        );
    }

    eval "require $source_class";
    if ($@)
    {
        throw BampoManager::Exception::Costs::SourceClassLoadError(
            error => "Could not load class ($source_class) for the costs source ($source_name): '$@'"
        );
    }

    my $source_api;
    my $ldap_login = $c->user->get('username');
    if (exists $c->config->{Costs} and exists $c->config->{Costs}->{$source_name})
    {
        my $config = $c->config->{Costs}->{$source_name};
        $source_api = $source_class->new($ldap_login, $config);
    }
    else
    {
        $source_api = $source_class->new($ldap_login);
    }

    unless ($source_api->does('BampoManager::Costs::Interface::API'))
    {
        throw BampoManager::Exception::Costs::BadSourceClass(
            error => "Costs source class ($source_class) doesn't emplement BampoManager::Costs::Interface::API interface."
        );
    }

    return $source_api;
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
