package BampoManager::Controller::REST::Costs::Upload;

use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;
use HTTP::Status qw/:constants/;
use File::Temp qw/mktemp/;
use Text::CSV;
use DateTime;
use MIME::Types;
use Test::Deep::NoTest qw/eq_deeply bag re/;
use Adriver::MooseX::Types::Date;
use Adriver::MooseX::Types::GUID;
use BampoManager::Schema::Const qw/:LINE_TYPE :STAT_TYPE/;
use BampoManager::Exceptions;

BEGIN { extends 'BampoManager::Controller::REST' }

use constant TMP_TEMPLATE => '/tmp/bampo_costs_XXXXXXX';

#/////////////////////////////////////////////////////////////////////
sub upload_costs :Chained('/') :PathPart('costs/upload') :Args(0)
{
    my ($self, $c) = @_;

    my $upload = get_upload($c);

    # Parse file again just to ensure that it is well formatted and
    # to know if header presents or don't
    my ($csv_data, $header_flag) = parse_csv($upload->fh);

    my $rows_num = load_data($c, $upload->tempname, $header_flag);

    $self->status_ok($c, entity => { affected_rows_num => $rows_num });
}

#/////////////////////////////////////////////////////////////////////
sub check_costs :Chained('/') :PathPart('costs/check_upload') :Args(0)
{
    my ($self, $c) = @_;

    my $upload   = get_upload($c);
    my $csv_data = parse_csv($upload->fh);

    my %placement_dates;
    foreach my $line (@$csv_data)
    {
        my ($placement_id, $date, $costs) = @$line{qw/placement_id date costs/};
        $placement_dates{$placement_id}->{$date} = $costs;
    }

    my @placement_ids = keys %placement_dates;
    my $placements = get_placements($c, \@placement_ids);
    if (keys %$placements < @placement_ids)
    {
        my @not_found_ids = grep { not exists $placements->{$_} } @placement_ids;
        throw BampoManager::Exception::Costs::Upload::NotFoundPlacements(
            error  => "Couldn't find some placements",
            status => HTTP_BAD_REQUEST,
            ids    => \@not_found_ids,
        );
    }

    my @data;
    foreach my $id (keys %placement_dates)
    {
        my @dates = keys %{$placement_dates{$id}};
        my $costs = get_placement_costs($c, $id, \@dates);
        foreach my $date (@dates)
        {
            my %line = %{$placements->{$id}};
            $line{date}      = $date;
            $line{costs}     = $placement_dates{$id}->{$date};
            $line{old_costs} = $costs->{$date} if exists $costs->{$date};
            push @data, \%line;
        }
    }

    # keep tmp file
    my $tmp_filename = mktemp(TMP_TEMPLATE);
    $upload->link_to($tmp_filename) or
        throw BampoManager::Exception::Costs::Upload(
            error => "Couldn't copy tmp file: [".$upload->tempname." -> $tmp_filename]");

    my $result = {
        type     => 'BampoManager::Costs::UploadedData',
        data     => \@data,
        filename => $tmp_filename,
    };

    $self->status_ok($c, entity => $result);
}

#/////////////////////////////////////////////////////////////////////
sub approve_upload :Chained('/') :PathPart('costs/upload/approve') :Args(0)
{
    my ($self, $c) = @_;

    my $filename = $c->request->params->{filename} or
        throw BampoManager::Exception::Costs::Upload("You didn't specify uploaded file name");

    open my $csv_fh, "<", $filename or throw BampoManager::Exception::Costs::Upload(
        error => "Couldn't open uploaded file ($filename): '$!'");

    # Parse file again just to ensure that it is well formatted and
    # to know if header presents or don't
    my ($csv_data, $header_flag) = parse_csv($csv_fh);

    my $rows_num = load_data($c, $filename, $header_flag);

    unlink $filename or throw BampoManager::Exception::Costs::Upload(
        error => "Couldn't delete uploaded file ($filename): '$!'");

    $self->status_ok($c, entity => { affected_rows_num => $rows_num });
}

#/////////////////////////////////////////////////////////////////////
sub get_upload
{
    my $c = shift;

    my $upload = $c->request->upload('file');
    unless ($upload)
    {
        throw BampoManager::Exception::Costs::Upload(
            error  => "Couldn't find any uploaded files",
            status => HTTP_BAD_REQUEST,
        );
    }

    # check file type
    my $mimetypes = new MIME::Types;
    my $mime_type = $mimetypes->mimeTypeOf($upload->filename);
    if ($mime_type ne 'text/comma-separated-values' and $mime_type ne 'text/csv')
    {
        my $filename = $upload->filename;
        throw BampoManager::Exception::Costs::Upload::File::Format(
            error  => "Uploaded file ($filename) has bad file format ($mime_type), you can upload only CSV files",
            status => HTTP_BAD_REQUEST,
        );
    }

    # check file size
    unless ($upload->size)
    {
        throw BampoManager::Exception::Costs::Upload::File::Size(
            error  => "Empty file",
            status => HTTP_BAD_REQUEST
        );
    }

    return $upload;
}

#/////////////////////////////////////////////////////////////////////
sub parse_csv
{
    my $csv_fh = shift;

    my $csv = Text::CSV->new({ sep_char => ';' }) or
        throw BampoManager::Exception::Costs::Upload("Cannot use CSV: " . Text::CSV->error_diag());

    my @data;
    my $header_flag = 0;
    my $line_num = 1;
    if (my $head = $csv->getline($csv_fh))
    {
        my $expected_head = [qw/placement_id date costs/];
        if (eq_deeply($head, bag(@$expected_head)))
        {
            $csv->column_names($head);
            $header_flag = 1;
        }
        else
        {
            my %line;
            @line{@$expected_head} = @$head;
            check_csv_line($line_num, \%line);
            $csv->column_names($expected_head);
            push @data, \%line;
        }
    }
    else
    {
        throw BampoManager::Exception::Costs::Upload::File("Couldn't read the head: " . $csv->error_diag());
    }

    while (my $line = $csv->getline_hr($csv_fh))
    {
        $line_num++;
        check_csv_line($line_num, $line);
        push @data, $line;
    }

    return wantarray ? (\@data, $header_flag) : \@data;
}

#/////////////////////////////////////////////////////////////////////
sub check_csv_line
{
    my $line_num = shift;
    my %line = eval {
        validated_hash(\@_,
            # It's better to use Adriver::MooseX::Types::GUID in validation process,
            # but coercion works too long here
            #placement_id => { isa => 'Adriver::MooseX::Types::GUID', coerce => 1 },
            placement_id => { isa => 'Str' },
            date         => { isa => 'Adriver::MooseX::Types::Date', coerce => 1 },
            costs        => { isa => 'Num' },
        );
    };
    if (my $e = caught Exception::Class)
    {
        throw BampoManager::Exception::Costs::Upload::File::Line(
            error    => "Bad data in a row [$line_num]: '$e'",
            status   => HTTP_BAD_REQUEST,
            line_num => $line_num,
        );
    }

    if ($line{date} >= DateTime->today)
    {
        my $date = $line{date}->strftime('%F');
        throw BampoManager::Exception::Costs::Upload::File::Line(
            error    => "Date can't be older than yesterday (line:$line_num; date:'$date)",
            status   => HTTP_BAD_REQUEST,
            line_num => $line_num,
        );
    }

    return \%line;
}

#/////////////////////////////////////////////////////////////////////
sub get_placements
{
    my ($c, $ids) = @_;

    my $rs = $c->model('Bampo::Line')->search(
        {
            'me.id'   => { -in => $ids },
            'me.type' => LINE_TYPE_ADRIVER,
        },
        {
            join   => { mediaplan => 'advertiser' },
            select => [
                'me.id',
                'me.title',
                'mediaplan.id',
                'mediaplan.title',
                'advertiser.title',
            ],
            as => [qw/
                placement_id
                placement_title
                mediaplan_id
                mediaplan_title
                advertiser_title
            /],
        }
    );

    my %placements = map { $_->get_column('placement_id') => { $_->get_columns } } $rs->all;

    return \%placements;
}

#/////////////////////////////////////////////////////////////////////
sub get_placement_costs
{
    my ($c, $placement_id, $dates) = @_;

    my $rs = $c->model('Bampo::Costs')->search(
        {
            'lineId' => $placement_id,
            date     => { in => $dates },
        },
        {
            select => [qw/date costs/],
            as     => [qw/date costs/],
        }
    );

    my %dates = map { $_->date->strftime('%F') => $_->costs } $rs->all;
    return \%dates;
}

#/////////////////////////////////////////////////////////////////////
sub load_data
{
    my ($c, $filename, $header_flag) = @_;

    my $dbh = $c->model('Bampo')->storage->dbh;
    my $statement = qq/LOAD DATA LOCAL INFILE '$filename' REPLACE INTO TABLE Costs/;
    $statement .= q/ FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'/;
    $statement .= q/ IGNORE 1 LINES/ if $header_flag;
    $statement .= q/ (lineId, date, costs)/;
    #warn "******** LOAD DATA STATEMENT: '$statement'\n";   # debug output

    my $rows_num = eval { $dbh->do($statement) } or throw BampoManager::Exception::Costs::Upload(
        error => "Database error on while loading data: '".$dbh->errstr."'");
    # 'do' always returs true, so we need to set it to the zero value ourself
    $rows_num = ($rows_num eq '0E0') ? 0 : $rows_num;

    return $rows_num;
}

#/////////////////////////////////////////////////////////////////////

__PACKAGE__->meta->make_immutable;
