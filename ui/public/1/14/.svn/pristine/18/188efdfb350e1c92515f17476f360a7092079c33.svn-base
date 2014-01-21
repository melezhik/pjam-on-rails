package BampoManager::Utils::DB;

use strict;
use warnings;

use DateTime;
use DateTime::Format::Natural;
use Exporter 'import';
use BampoManager::Schema::Const qw/:LINE_STATUS/;
use BampoManager::Filter::Const qw/:LIST_FORMAT :STAT_PERIOD/;
use List::AllUtils qw/any all/;

our @EXPORT_OK = qw/
    get_clients_by_agencies
    get_banner_formats
    get_products
    get_geos
    get_channel_groups
    get_placement_targetings
    update_leads_shipment_data
    update_cpoint_status
    filter_by_list_format
    filter_by_stat_period
    extra_filter_placements
    extra_filter_cpoints
    is_placement_match_filter
/;

#/////////////////////////////////////////////////////////////////////
sub get_clients_by_agencies
{
    my ($c) = @_;

    my %agencies;
    my $rs = $c->model('Bampo::Advertiser')->search(undef,
        {
            join   => 'agency',
            select => ['agency.id', 'agency.title', 'me.id', 'me.title', 'me.archived'],
            as     => [qw/agency_id agency_title ad_id ad_title ad_archived/],
        }
    );

    foreach my $row ($rs->all)
    {
        my $agency_id    = $row->get_column('agency_id');
        my $agency_title = $row->get_column('agency_title');
        my $ad_id        = $row->get_column('ad_id');
        my $ad_title     = $row->get_column('ad_title');
        my $ad_archived  = $row->get_column('ad_archived');

        if (exists $agencies{$agency_id})
        {
            push @{$agencies{$agency_id}->{clients}}, { id => $ad_id, title => $ad_title, archived => $ad_archived };
        }
        else
        {
            $agencies{$agency_id} = {
                id      => $agency_id,
                title   => $agency_title,
                clients => [{ id => $ad_id, title => $ad_title, archived => $ad_archived }],
            };
        }
    }

    my @agencies = values %agencies;

    return \@agencies;
}

#/////////////////////////////////////////////////////////////////////
sub get_banner_formats
{
    my ($c) = @_;

    my @rows = $c->model('Bampo::BannerFormat')->all;
    my @banner_formats = map +{ $_->get_columns }, @rows;

    return \@banner_formats;
}

#/////////////////////////////////////////////////////////////////////
sub get_products
{
    my ($c) = @_;

    my @rows = $c->model('Bampo::Product')->all;
    my @products = map +{ $_->get_columns }, @rows;

    return \@products;
}

#/////////////////////////////////////////////////////////////////////
sub get_channel_groups
{
    my ($c) = @_;

    my @rows = $c->model('Bampo::ChannelGroup')->all;
    my @channel_groups = map +{ $_->get_columns }, @rows;

    return \@channel_groups;
}

#/////////////////////////////////////////////////////////////////////
sub get_placement_targetings
{
    my ($c) = @_;

    my @rows = $c->model('Bampo::PlacementTargeting')->all;
    my @placement_targetings = map +{ $_->get_columns }, @rows;

    return \@placement_targetings;
}

#/////////////////////////////////////////////////////////////////////
sub get_geos
{
    my ($c) = @_;

    my @rows = $c->model('Bampo::Geo')->all;
    my @geos = map +{ $_->get_columns }, @rows;

    return \@geos;
}

#/////////////////////////////////////////////////////////////////////
sub update_leads_shipment_data
{
    my ($c, $line, $date) = @_;
    $date = DateTime->now unless defined $date;

    my $start_date = $date->clone->set_day(1);
    my $stop_date  = DateTime->last_day_of_month(year => $date->year, month => $date->month);

    my $old_leads = $c->model('CRMSoloway')->get_leads_for_period($line->id, $start_date, $stop_date) || 0;
    my $new_leads = $c->model('Bampo::ClientStat')->search({
            lineId => $line->id,
            -and => [
                date => { '>=', $start_date->strftime('%F') },
                date => { '<=', $stop_date->strftime('%F') },
            ],
        })->get_column('leads_client')->sum() || 0;

    my $leads = $new_leads - $old_leads;
    $c->model('CRMSoloway')->update_leads_shipment_data($line, $start_date, $stop_date, $leads);

    return undef;
}

#/////////////////////////////////////////////////////////////////////
sub update_cpoint_status
{
    my ($c, $line) = @_;

    my $max_leads = $line->priceAmount || 0;
    if ($max_leads)
    {
        my $total_leads = $c->model('CRMSoloway')->get_total_leads($line->id);
        if ($total_leads >= $max_leads)
        {
            $line->update({ status => LINE_STATUS_FINISHED }) if $line->status ne LINE_STATUS_FINISHED;
        }
        else
        {
            $line->update({ status => LINE_STATUS_ACTIVE }) if $line->status ne LINE_STATUS_ACTIVE;
        }
    }
    else
    {
        $line->update({ status => LINE_STATUS_ACTIVE }) if $line->status ne LINE_STATUS_ACTIVE;
    }

    return undef;
}

#/////////////////////////////////////////////////////////////////////
sub filter_by_list_format
{
    my ($c, $rs, $filter, $alias, $join) = @_;

    if ($filter->list_format eq FORMAT_OWN)
    {
        my $account_manager = "accountManagerId";
        $account_manager = "$alias.$account_manager" if defined $alias;
        $rs = $rs->search({ $account_manager => $c->user->get('id') });
    }
    elsif ($filter->list_format eq FORMAT_AGENCY)
    {
        my $agency = "agencyId";
        $agency = "$alias.$agency" if defined $alias;
        $rs = $rs->search({ $agency => $c->user->get('agencyId') });
    }
    elsif ($filter->list_format eq FORMAT_CLIENT)
    {
        if ($filter->client_id)
        {
            my $advertiser = "advertiserId";
            $advertiser = "$alias.$advertiser" if defined $alias;
            $rs = $rs->search({ $advertiser => $filter->client_id });
        }
        elsif ($filter->agency_id)
        {
            my $agency = "agencyId";
            $agency = "$alias.$agency" if defined $alias;
            $rs = $rs->search({ $agency => $filter->agency_id });
        }
    }

    if ($filter->list_format ne FORMAT_ALL and defined $join)
    {
        $rs = $rs->search(undef, { join => $join });
    }

    return $rs;
}

#/////////////////////////////////////////////////////////////////////
sub filter_by_stat_period
{
    my ($rs, $filter, $alias) = @_;

    my $date = ($alias) ? "$alias.date" : 'date';
    $rs = $rs->search( {
            $date => [ -and =>
                { '>=', $filter->start_date->strftime('%F') },
                { '<=', $filter->stop_date->strftime('%F') }
            ],
        }
    );

    return $rs;
}

#/////////////////////////////////////////////////////////////////////
sub extra_filter_placements
{
    my ($rs, $filter, $alias, $join) = @_;

    if ($filter->advert_name)
    {
        my $title = "title";
        $title = "$alias.$title" if defined $alias;
        $rs = $rs->search({ $title => { -like => '%'.$filter->advert_name.'%' } });
        $rs = $rs->search(undef, { join => $join }) if defined $join;
    }

    if ($filter->banner_format_id)
    {
        my $banner_format = "bannerFormatId";
        $banner_format = "$alias.$banner_format" if defined $alias;
        $rs = $rs->search({ $banner_format => $filter->banner_format_id });
        $rs = $rs->search(undef, { join => $join }) if defined $join;
    }

    if ($filter->product_id)
    {
        my $product = "priceProductId";
        $product = "$alias.$product" if defined $alias;
        $rs = $rs->search({ $product => $filter->product_id });
        $rs = $rs->search(undef, { join => $join }) if defined $join;
    }

    if ($filter->channel_group_id)
    {
        my $channel_group = "channelGroupId";
        $channel_group = "$alias.$channel_group" if defined $alias;
        $rs = $rs->search({ $channel_group => $filter->channel_group_id });
        $rs = $rs->search(undef, { join => $join }) if defined $join;
    }

    if ($filter->placement_targeting_id)
    {
        my $placement_targeting = "placementTargetingId";
        $placement_targeting = "$alias.$placement_targeting" if defined $alias;
        $rs = $rs->search({ $placement_targeting => $filter->placement_targeting_id });
        $rs = $rs->search(undef, { join => $join }) if defined $join;
    }

    return $rs;
}

#/////////////////////////////////////////////////////////////////////
sub is_placement_match_filter
{
    my ($placement, $filter) = @_;

    my @result;
    if ($filter->advert_name)
    {
        my $name = $filter->advert_name;
        push @result, scalar($placement->{placement_title} =~ /$name/i);
    }

    if ($filter->banner_format_id)
    {
        push @result, any { $_ == $placement->{banner_format_id} } @{$filter->banner_format_id};
    }

    if ($filter->product_id)
    {
        push @result, any { $_ == $placement->{product_id} } @{$filter->product_id};
    }

    if ($filter->channel_group_id)
    {
        push @result, any { $_ == $placement->{channel_group_id} } @{$filter->channel_group_id};
    }

    if ($filter->placement_targeting_id)
    {
        push @result, any { $_ == $placement->{placement_targeting_id} } @{$filter->placement_targeting_id};
    }

    return all { $_ } @result;
}

#/////////////////////////////////////////////////////////////////////
sub extra_filter_cpoints
{
    my ($rs, $filter, $alias, $join) = @_;

    if ($filter->cpoint_name)
    {
        my $title = "title";
        $title = "$alias.$title" if defined $alias;
        $rs = $rs->search({ $title => { -like => '%'.$filter->cpoint_name.'%' } });
        $rs = $rs->search(undef, { join => $join }) if defined $join;
    }

    if ($filter->site_paid)
    {
        my $site_paid = "sitePaid";
        $site_paid = "$alias.$site_paid" if defined $alias;
        $rs = $rs->search({ -bool => $site_paid });
        $rs = $rs->search(undef, { join => $join }) if defined $join;
    }

    if ($filter->geo_id)
    {
        my $geo = "geoId";
        $geo = "$alias.$geo" if defined $alias;
        $rs = $rs->search({ $geo => $filter->geo_id });
        $rs = $rs->search(undef, { join => $join }) if defined $join;
    }

    return $rs;
}

#/////////////////////////////////////////////////////////////////////


1;
