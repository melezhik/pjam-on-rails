package BampoManager::Controller::Lines::CPoint::ClientStat;

use Moose;
use namespace::autoclean;
use DateTime;
use DateTime::Format::Natural;
use HTTP::Status qw/:constants/;
use Encode qw/decode_utf8/;
use Adriver::Mail;
use BampoManager::Utils::DB qw/update_leads_shipment_data update_cpoint_status/;
use BampoManager::Exceptions;

BEGIN { extends 'BampoManager::Controller::Base' }


has send_notify_letter => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has notify_letter => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has smtp => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

around BUILDARGS => sub {
    my $orig   = shift;
    my $class  = shift;
    my $app    = shift;
    my $config = shift;

    my $letter = $config->{notify_letter};
    $letter->{subject} = decode_utf8($letter->{subject});
    $letter->{sign}    = decode_utf8($letter->{sign}) if defined $letter->{sign};
    $letter->{from}    = decode_utf8($letter->{from});
    if (defined $letter->{to} and ref $letter->{to} eq 'ARRAY')
    {
        $_ = decode_utf8($_) foreach @{$letter->{to}};
    }
    elsif (defined $letter->{to} and not ref $letter->{to})
    {
        $letter->{to} = decode_utf8($letter->{to});
    }

    if (defined $letter->{cc} and ref $letter->{cc} eq 'ARRAY')
    {
        $_ = decode_utf8($_) foreach @{$letter->{cc}};
    }
    elsif (defined $letter->{cc} and not ref $letter->{cc})
    {
        $letter->{cc} = decode_utf8($letter->{cc});
    }

    return $class->$orig($app, $config, @_);
};

#/////////////////////////////////////////////////////////////////////
sub edit :Chained('/lines/cpoint/_cpoint') :PathPart('client_stat') :Args(0) :FormConfig('lines/cpoint/client_stat')
{
    my ($self, $c) = @_;
    set_default_values($c) if exists $c->request->params->{reload_form};
}

sub set_default_values
{
    my $c = shift;

    my $form       = $c->stash->{form};
    my $line_id    = $c->stash->{cpoint_row}->id;
    my $line_title = $c->stash->{cpoint_row}->title;
    my $dtf = $c->model('Bampo')->schema->storage->datetime_parser;

    my $date = (exists $c->request->params->{date}) ?
        DateTime::Format::Natural->new->parse_datetime($c->request->params->{date})
        : DateTime->now->subtract(days => 1);
    my $stat_row = $c->model('Bampo::ClientStat')->find($line_id, $dtf->format_date($date));

    if (defined $stat_row)
    {
        $form->model->default_values($stat_row);
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
    set_default_values($c);
}

sub edit_FORM_VALID
{
    my ($self, $c) = @_;

    # do nothing here if we just need to reload the form
    return if exists $c->request->params->{reload_form};

    my $form = $c->stash->{form};
    my $line = $c->stash->{cpoint_row};
    my $dtf  = $c->model('Bampo')->schema->storage->datetime_parser;

    my $date = $form->param_value('date');
    my $stat_row = $c->model('Bampo::ClientStat')->find($line->id, $dtf->format_date($date));
    my $new_leads_value = $form->param_value('leads_client') || 0;
    my $old_leads_value = (defined $stat_row and defined $stat_row->leads_client) ? $stat_row->leads_client : 0;

    eval {
        $c->model('Bampo')->txn_do(sub {
            (defined $stat_row) ? $form->model->update($stat_row) : $form->model->create();
            update_leads_shipment_data($c, $line, $date) if $line->sitePaid;
            update_cpoint_status($c, $line);
        });

        if (defined $stat_row and $new_leads_value < $old_leads_value and $self->send_notify_letter)
        {
            $self->send_letter($c, $date, $old_leads_value, $new_leads_value);
        }
    };
    if (my $e = Exception::Class->caught('DBIx::Class::Exception'))
    {
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Database error while modifying client statistics: '$e'",
            user_msg => $self->INTERNAL_SERVER_ERROR_MSG
        );
    }
    elsif ($e = caught Exception::Class)
    {
        throw BampoManager::Exception::FormFu(
            status   => HTTP_INTERNAL_SERVER_ERROR,
            error    => "Unknown error while modifying client statistics: '$e'",
            user_msg => $self->INTERNAL_SERVER_ERROR_MSG
        );
    }
}

sub edit_FORM_NOT_VALID
{
    my ($self, $c) = @_;
    set_default_values($c);
    $c->res->status(HTTP_BAD_REQUEST);
}

#/////////////////////////////////////////////////////////////////////
sub send_letter
{
    my ($self, $c, $date, $old_leads_value, $new_leads_value) = @_;

    my $email = $self->notify_letter;
    my $smtp  = $self->smtp;

    my $head_conf = {
        from    => $email->{from},
        to      => $email->{to},
        subject => $email->{subject},
        charset => $email->{charset},
    };
    $head_conf->{cc} = $email->{cc} if defined $email->{cc};

    my $body_conf = {};
    $body_conf->{sign} = $email->{sign} if defined $email->{sign};

    my $smtp_conf = {
        hostname => $smtp->{server},
        timeout  => $smtp->{timeout},
    };

    my $date_str = $date->strftime("%F");
    my $mediaplan_title = $c->stash->{cpoint_row}->mediaplan->title;
    my $line_title      = $c->stash->{cpoint_row}->title;
    my $line_id         = $c->stash->{cpoint_row}->id;
    my $user = $c->user;
    my $username   = ($user->can('username')) ? $user->username : $user->get('username');
    my $user_title = ($user->can('title'))    ? $user->title    : $user->get('title');
    my $user_email = ($user->can('email'))    ? $user->email    : $user->get('email');

    # Compose the body
    my $text = "Modification of client leads value on $date_str.\n\n";
    $text .= "Mediaplan title: '$mediaplan_title'\n";
    $text .= "Line title: '$line_title'\n";
    $text .= "Line id:    '$line_id'\n";
    $text .= "Old value:  '$old_leads_value'\n";
    $text .= "New value:  '$new_leads_value'\n";
    $text .= "User name:  '$username'\n";
    $text .= "User title: '$user_title'\n";
    $text .= "User email: '$user_email'\n\n";
    $c->log->info($text);

    $body_conf->{data} = $text;
    my $message = Adriver::Mail->compose_message({ head => $head_conf, body => $body_conf });
    Adriver::Mail->send_mail($message, $smtp_conf);

    return 1;
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
