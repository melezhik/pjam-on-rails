package BampoManager::Controller::Lines::Costs;

use Moose;
use namespace::autoclean;
use DateTime;
use DateTime::Format::Natural;
use HTTP::Status qw/:constants/;
use BampoManager::Exceptions;

BEGIN { extends 'BampoManager::Controller::Base' }


#/////////////////////////////////////////////////////////////////////
sub _line :Chained('/') :PathPart('lines') :CaptureArgs(1)
{
    my ($self, $c, $id) = @_;
    $c->stash->{line_row} = $c->model('Bampo::Line')->find($id);
    unless ($c->stash->{line_row})
    {
        throw BampoManager::Exception::CPointNotFound(
            status => HTTP_NOT_FOUND,
            error  => "Couldn't find control point with id='$id'"
        );
    }
}

#/////////////////////////////////////////////////////////////////////
sub edit :Chained('_line') :PathPart('costs') :Args(0) :FormConfig('lines/costs')
{
    my ($self, $c) = @_;
    $self->set_default_values($c) if exists $c->request->params->{reload_form};
}

sub set_default_values
{
    my ($self, $c) = @_;

    my $form       = $c->stash->{form};
    my $line_id    = $c->stash->{line_row}->id;
    my $line_title = $c->stash->{line_row}->title;
    my $dtf = $c->model('Bampo')->schema->storage->datetime_parser;

    my $date = (exists $c->request->params->{date}) ?
        DateTime::Format::Natural->new->parse_datetime($c->request->params->{date})
        : DateTime->now->subtract(days => 1);
    my $costs_row = $c->model('Bampo::Costs')->find($line_id, $dtf->format_date($date));

    if (defined $costs_row)
    {
        $form->model->default_values($costs_row);
        $form->default_values({ line_title => $line_title });
    }
    else
    {
        $form->default_values({ lineId => $line_id, line_title => $line_title, date => $date });
    }
}

sub edit_FORM_NOT_SUBMITTED
{
    my ($self, $c) = @_;
    $self->set_default_values($c);
}

sub edit_FORM_VALID
{
    my ($self, $c) = @_;

    # do nothing here if we just need to reload the form
    return if exists $c->request->params->{reload_form};

    my $form = $c->stash->{form};
    my $line = $c->stash->{line_row};
    my $dtf  = $c->model('Bampo')->schema->storage->datetime_parser;

    my $date = $form->param_value('date');
    my $costs_row = $c->model('Bampo::Costs')->find($line->id, $dtf->format_date($date));
    eval {

        if (defined $costs_row)
        {
            $form->model->update($costs_row);
        }
        else
        {
            $form->model->create();
        }
    };
    if (my $e = Exception::Class->caught('DBIx::Class::Exception'))
    {
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Database error while modifying line costs: '$e'",
            user_msg => $self->INTERNAL_SERVER_ERROR_MSG
        );
    }
    elsif ($e = caught Exception::Class)
    {
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Unknown error while modifying line costs: '$e'",
            user_msg => $self->INTERNAL_SERVER_ERROR_MSG
        );
    }
}

sub edit_FORM_NOT_VALID
{
    my ($self, $c) = @_;
    $self->set_default_values($c);
    $c->res->status(HTTP_BAD_REQUEST);
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
