package BampoManager::Controller::Base;

use Moose;
use BampoManager::Exceptions;
use Scalar::Util qw/blessed/;
use HTTP::Status qw/:constants/;
use Encode qw/decode_utf8/;

BEGIN { extends 'Catalyst::Controller::HTML::FormFu' }

use constant {
    VERSION_COLLISION_ERROR_MSG   => decode_utf8("Запись редактируется другим пользователем"),
    INTERNAL_SERVER_ERROR_MSG     => decode_utf8("Неизвестная ошибка на сервере"),
    DUPLICATE_CPOINT_ERROR_MSG    => decode_utf8("Такая контрольная точка уже существует"),
    DUPLICATE_PLACEMENT_ERROR_MSG => decode_utf8("Такое размещение уже существует"),
    NOT_FOUND_ERROR_HTML          => 'root/static/404.html',
    SERVER_INTERNAL_ERROR_HTML    => 'root/static/500.html',
};

#/////////////////////////////////////////////////////////////////////
sub begin :Private
{
    my ($self, $c) = @_;

    $c->forward('root','auth');
}

#/////////////////////////////////////////////////////////////////////
sub end :ActionClass('RenderView')
{
    my ($self, $c) = @_;
    my @errors = @{$c->error};
    my $e;

    if (scalar @errors > 1)
    {
        my $e_str = join ", ", @errors;
        $c->log->error("Caught multiple (" . scalar(@errors) . ") exceptions [$e_str]");
        $e = BampoManager::Exception->new(error => $e_str);
    }
    elsif (scalar @errors == 1)
    {
        $e = shift @errors;
        $c->log->error("Caught exception '" . ref($e) . "' [$e]");
        unless (blessed($e) and $e->isa('BampoManager::Exception'))
        {
            $c->log->debug("=== Trace ===\n" . $e->trace) if blessed($e) and $e->can('trace');
            $e = BampoManager::Exception->new("$e");
        }
    }
    $c->clear_errors;

    if (defined $e)
    {
        my $status = (defined $e->status) ? $e->status : HTTP_INTERNAL_SERVER_ERROR;
        $c->log->info("Setting status $status");
        $c->res->status($status);
        if ($e->isa("BampoManager::Exception::FormFu") and exists $c->stash->{form})
        {
            my $form = $c->stash->{form};
            $form->force_error_message(1);
            $form->form_error_message($e->user_msg);
        }
        elsif ($status == HTTP_NOT_FOUND)
        {
            $c->serve_static_file(NOT_FOUND_ERROR_HTML);
        }
        else
        {
            $c->serve_static_file(SERVER_INTERNAL_ERROR_HTML);
        }
    }

    return 1;
}

#/////////////////////////////////////////////////////////////////////
sub get_raw_page_filter
{
    my ($self, $c, $filter_name) = @_;

    if (not exists $c->session->{filters} or ref($c->session->{filters}) ne 'HASH')
    {
        $c->session->{filters} = { $filter_name => { __CLASS__ => $filter_name } };
    }
    elsif (not exists $c->session->{filters}->{$filter_name})
    {
        $c->session->{filters}->{$filter_name} = { __CLASS__ => $filter_name };
    }

    return $c->session->{filters}->{$filter_name};
}

#/////////////////////////////////////////////////////////////////////
sub set_raw_page_filter
{
    my ($self, $c, $filter_name, $filter) = @_;

    $self->get_raw_page_filter($c, $filter_name);
    $c->session->{filters}->{$filter_name} = $filter;
}

#/////////////////////////////////////////////////////////////////////
sub get_page_filter
{
    my ($self, $c, $filter_name) = @_;

    my $filter_data = $self->get_raw_page_filter($c, $filter_name);

    my $params = $c->request->params;
    map { $filter_data->{$_} = $params->{$_} } keys %$params;

    foreach my $k (keys %$filter_data)
    {
        delete $filter_data->{$k} if not defined $filter_data->{$k} or $filter_data->{$k} eq '';
    }

    my $filter = $c->model('Deserializer')->deserialize($filter_data);

    return $filter;
}

#/////////////////////////////////////////////////////////////////////
sub set_page_filter
{
    my ($self, $c, $filter_name, $filter) = @_;

    my $filter_data = $c->model('Serializer')->serialize($filter);
    $self->set_raw_page_filter($c, $filter_name, $filter_data);
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
