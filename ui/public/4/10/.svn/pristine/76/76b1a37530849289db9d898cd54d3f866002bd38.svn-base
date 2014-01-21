package BampoManager::Utils::Misc;

use strict;
use warnings;

use Exporter 'import';
use CGI::Util;
use DateTime;
use List::Util qw/min max/;
use Adriver::Catalyst::Authentication::Credential::Adriver::Util;

our @EXPORT_OK = qw/
    generate_password
    gen_zero_stat
/;


my @STAT_COUNTERS = (qw/impressions clicks leads_reach leads_uniq leads_nu leads_proper placement_costs/);

#/////////////////////////////////////////////////////////////////////
sub generate_password
{
    my ($password, $ip) = @_;

    my $crypted = Adriver::Catalyst::Authentication::Credential::Adriver::Util::encrypt_password($password, $ip);
    my $pass = CGI::Util::escape($crypted);

    return $pass;
}

#/////////////////////////////////////////////////////////////////////
sub gen_zero_stat
{
    my ($stat_data, $filter, $cpoint_row, $placement_row) = @_;

    my %dates_stat = map { $_->{date} => $_ } @$stat_data;

    my (@start_dates, @stop_dates);
    push @start_dates, $cpoint_row->startDate;
    push @start_dates, $filter->start_date if defined $filter->start_date;

    push @stop_dates, $cpoint_row->stopDate if defined $cpoint_row->stopDate;
    push @stop_dates, $filter->stop_date if defined $filter->stop_date;
    push @stop_dates, DateTime->today;

    if (defined $placement_row)
    {
        push @start_dates, $placement_row->startDate;
        push @stop_dates, $placement_row->stopDate if defined $placement_row->stopDate;
    }

    my $start_date = max(@start_dates)->clone;
    my $stop_date  = min(@stop_dates)->clone;
    while ($start_date <= $stop_date)
    {
        my $date_str = $start_date->strftime('%F');
        unless (exists $dates_stat{$date_str})
        {
            # we don't care about sorting array by date here
            # we will do that later in template
            my $zero_stat = { map { $_ => 0 } @STAT_COUNTERS };
            $zero_stat->{date} = $date_str;
            push @$stat_data, $zero_stat;
        }
        $start_date->add(days => 1);
    }

    return undef;
}

#/////////////////////////////////////////////////////////////////////


1;
