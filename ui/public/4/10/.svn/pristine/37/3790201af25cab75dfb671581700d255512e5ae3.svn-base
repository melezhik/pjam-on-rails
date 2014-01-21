#!/usr/bin/perl -w

use strict;
use Carp;

use Getopt::Long qw(:config pass_through);
# use Pod::Usage;
use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init($INFO);
# use IO::File;
use DBI;
# use POSIX qw(setlocale LC_NUMERIC);
#use Soloway::Recalc::DataInterface::BuyCost;
#use AdGravity::Recalc::DataInterface::SiteLeadStat;
#use AdGravity::Recalc::DataInterface::SitePrice;
#use BillingDBI::BillingFloat;
#use Recalc::Utils::Log;
use Adriver::Date::SQL qw( Today Yesterday );
use Data::Dumper;
use DateTime;
use Exception::Class;

my %opts = (
    config    => '',
    outfile   => undef,
    site_id   => undef,
    fake      => undef
);

GetOptions(
    'c=s'  => \$opts{config},
    'o=s'  => \$opts{outfile},
    's=s'  => \$opts{site_id},
    'f=s'  => \$opts{fake},
);
my $fake = $opts{fake};

my $dbh_bampo = DBI->connect('dbi:mysql:host=mysql3.adriver.x;database=BampoManager', 'bampomanager', 'JsASRVhSPa5tDQUq');

# start_date = first_day_of_month(TODAY-2)
# end_date = last_day_of_mont(TODAY-2)

my $today = DateTime->today();
my $two_days_ago = $today->clone->subtract(days => 2);
my $last_day_of_month = DateTime->last_day_of_month(year => $two_days_ago->year, month => $two_days_ago->month);
my $start_date = DateTime->new(year => $last_day_of_month->year, month => $last_day_of_month->month, day => 1)->ymd;
my $end_date = $last_day_of_month->ymd;

my $today = Today();
my $yesterday = Yesterday() le $end_date ? Yesterday() : $end_date;


# select auto paid leads from BampoManager
my $paid_leads = $dbh_bampo->selectall_arrayref(
"
SELECT l.id as target_id, l.title as title, m.title as mediaplan, l.priceAmount as total, l.priceType as priceType,
l.priceSale as price, l.supercom as supercomm, l.statType as statType, sum(impressions) as exposures
sum( s.leads ) as leads , sum( s.leads_nu ) as leads_nu, sum( s.leads_reach ) as leads_reach,
( SELECT SUM( leads_client ) FROM ClientStat WHERE lineId = l.id AND date >= ? AND date <=  ? ) AS leads_client
FROM Line AS l
JOIN Mediaplan AS m ON l.mediaplanId = m.Id
JOIN Statistics AS s ON l.id = s.targetLineId
WHERE (l.statType = 'own' OR ( l.statType =  'client' AND l.leadStatId IS NOT NULL ))
AND l.sitePaid = '1' OR (l.sitePaid = '0' AND l.billingType = 'commercial' AND l.priceType = 'CPM')
AND s.date >= ? AND s.date <= ?
GROUP BY l.id
", { Slice => {} }, $start_date, $yesterday, $start_date, $yesterday );


foreach my $lead (@$paid_leads)
{
    eval {
        my $already_paid =  $dbh_bampo->selectall_arrayref("
        SELECT target_id, start_date, end_date, sum(leads) as leads, price, type from LeadShipmentData
        WHERE target_id = ? and start_date = ? AND end_date = ? group by target_id", { Slice => {} }, $lead->{target_id}, $start_date, $end_date)->[0];
        my $total_paid =  $dbh_bampo->selectall_arrayref("
        SELECT target_id, start_date, end_date, sum(leads) as leads, price, type from LeadShipmentData
        WHERE target_id = ?  group by target_id", { Slice => {} }, $lead->{target_id})->[0];
        my $already_paid_leads = 0;
        if ( ref $already_paid eq 'HASH' and  (event_type($lead) eq $already_paid->{type}) ) {
            $already_paid_leads = $already_paid->{leads};
        } #else { die " Lead type missmatch! old type = $already_paid->{type} new type = " . event_type($lead); }
        my $add_leads_today = events_by_type($lead) - $already_paid_leads;
        if ($add_leads_today > 0) {
            my $new_leads_total = $total_paid->{leads} + $add_leads_today;
            # undef $lead->{total} means unlimited
            # if new leads total more than purchased (limited) by $lead->{total} we pay only for $lead->{total}
            if (defined $lead->{total} and $new_leads_total > $lead->{total})
            {
                #do not pay to site more than purchased leads
                $add_leads_today = $add_leads_today - ($new_leads_total - $lead->{total});
                if ($add_leads_today < 0) {
                    my $diff = $new_leads_total - $lead->{total};
                    $add_leads_today = 0;
                    print  "$today;NOPAYMENTTOTALREACHED;Date;$yesterday;LEAD;$lead->{target_id};\"$lead->{title}\";\"$lead->{mediaplan}\";START;$start_date;STOP;$end_date;TYPE;$lead->{priceType};LEADS_BEFORE;$already_paid_leads;DIFF;$diff;PRICE;$lead->{price};SUPERCOMM;$lead->{supercomm}\n";
                }
            }
            if ($add_leads_today > 0) {
                print  "$today;PAY;Date;$yesterday;LEAD;$lead->{target_id};\"$lead->{title}\";\"$lead->{mediaplan}\";START;$start_date;STOP;$end_date;TYPE;$lead->{priceType};LEADS_BEFORE;$already_paid_leads;AMOUNT;$add_leads_today;TOTAL;".($lead->{total}||"unlimited").";PRICE;$lead->{price};SUPERCOMM;$lead->{supercomm}\n";
                unless ($fake) {
                    my ($status) = $dbh_bampo->selectrow_array('call update_leads_shipment_data3(?, ?, ?, ?, ?, ?, ?, ?)', undef,
                    $lead->{target_id}, $start_date, $end_date, event_type($lead), $add_leads_today, $lead->{price}, $lead->{supercomm}, $lead->{total}) or
                        die "CRMSoloway Model Error: couldn't call update_leads_shipment_data3 procedure: '" . $dbh_bampo->errstr . "'";
                    die "CRMSoloway Model Error: update_leads_shipment_data3 procedure error: '$status'" unless ($status =~ m/^success/);
		            ### check finished flag
		            $total_paid =  $dbh_bampo->selectall_arrayref("
                                SELECT target_id, start_date, end_date, sum(leads) as leads, price, type from LeadShipmentData
                                WHERE target_id = ?  group by target_id", { Slice => {} }, $lead->{target_id})->[0];
		            if (defined $lead->{total} and $lead->{total} > 0 and $lead->{total} <= $total_paid->{leads}) { # set finished flag
			            $dbh_bampo->do("update Line set status = 'finished' where id = ?", {}, $lead->{target_id});
		            }
                }
	        }
        } else {
            if ( defined $lead->{total} and $lead->{total} > 0 and $lead->{total} <= $total_paid->{leads} ) {
                print  "$today;FINISHED;Date;$yesterday;LEAD;$lead->{target_id};\"$lead->{title}\";\"$lead->{mediaplan}\";START;$start_date;STOP;$end_date;TYPE;$lead->{priceType};LEADS_BEFORE;$already_paid_leads;AMOUNT;$add_leads_today;TOTAL;". ($lead->{total}||"unlimited").";PRICE;$lead->{price};SUPERCOMM;$lead->{supercomm}\n";
            } else {
                print  "$today;NOPAYMENT;Date;$yesterday;LEAD;$lead->{target_id};\"$lead->{title}\";\"$lead->{mediaplan}\";START;$start_date;STOP;$end_date;TYPE;$lead->{priceType};LEADS_BEFORE;$already_paid_leads;AMOUNT;$add_leads_today;TOTAL;".($lead->{total}||"unlimited").";PRICE;$lead->{price};SUPERCOMM;$lead->{supercomm}\n";
            }
        }
    };
    if (my $e = Exception::Class->caught())
    {
        print "Error processing lead id=$lead->{target_id} : $e";
    }
}

sub event_type {
    my $lead = shift;
    my $map = {'CPA' => 'leads_nu', 'CPL' => 'leads', 'CPV' => 'leads_reach', 'CPC' => 'leads_nu', 'CPM' => 'CPM'};
    return $map->{$lead->{priceType}};
}

sub events_by_type {
    my $lead = shift;
    my $amount = 0;
    if ($lead->{statType} eq 'client') {
        $amount = $lead->{leads_client} || 0;
    } elsif ($lead->{priceType} eq 'CPA') {
        $amount = $lead->{leads_nu};
    } elsif ($lead->{priceType} eq 'CPL') {
        $amount = $lead->{leads};
    } elsif ($lead->{priceType} eq 'CPV') {
        $amount = $lead->{leads_reach};
    } elsif ($lead->{priceType} eq 'CPC') {
        $amount = $lead->{leads_nu};
    } elsif ($lead->{priceType} eq 'CPM') {
        $amount = $lead->{exposures};
    } else { die "Unknown lead event type: $lead->{priceType}"; }
    return $amount;
}
