package BampoManager::Controller::Mediaplans;

use Moose;
use namespace::autoclean;
use HTTP::Status qw/:constants/;
use BampoManager::Schema::Const qw/:LINE_TYPE :MEDIAPLAN_STATUS/;
use BampoManager::Utils::DB qw/get_clients_by_agencies filter_by_list_format/;

BEGIN { extends 'BampoManager::Controller::Base' }


#/////////////////////////////////////////////////////////////////////
sub index :Path
{
    my ($self, $c) = @_;
    my $filter = $self->get_filter($c);

    $c->stash->{filter}   = $filter;
    $c->stash->{agencies} = get_clients_by_agencies($c);
    $c->stash->{data}     = get_mediaplans($c, $filter);
}

#/////////////////////////////////////////////////////////////////////
sub get_filter
{
    my ($self, $c) = @_;

    my $filter_class = 'BampoManager::Filter::Mediaplans';
    my $filter = $self->get_page_filter($c, $filter_class);
    $self->set_page_filter($c, $filter_class, $filter);

    return $filter;
}

#/////////////////////////////////////////////////////////////////////
sub get_mediaplans
{
    my ($c, $filter) = @_;

    my $line_rs = $c->model('Bampo::Line')->search(
        {
            'line.type'        => { '=' => LINE_TYPE_PIXEL },
            'line.mediaplanId' => { '=' => \'me.id' },
        },
        { alias => 'line' }
    );

    my $mediaplan_rs = $c->model('Bampo::Mediaplan')->search( { },
        {
            join   => [qw/advertiser salesManager accountManager/],
            select => [
                'me.title',
                'me.id',
                'me.status',
                'advertiser.title',
                'salesManager.title',
                'accountManager.title',
                $line_rs->get_column('startDate')->min_rs->as_query,   #min_date
                $line_rs->get_column('stopDate')->max_rs->as_query,    #max_date
            ],
            as => [qw/
                title
                id
                status
                advertiser
                sales_manager
                account_manager
                min_date
                max_date
            /],
        }
    );

    if ($filter->hide_archived)
    {
        $mediaplan_rs = $mediaplan_rs->search({ 'me.status' => { '!=' => MEDIAPLAN_STATUS_ARCHIVED } });
    }

    my $alias = 'me';
    $mediaplan_rs = filter_by_list_format($c, $mediaplan_rs, $filter, $alias);

    my $result = [ map +{ $_->get_columns() }, $mediaplan_rs->all ];
    return $result;
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
