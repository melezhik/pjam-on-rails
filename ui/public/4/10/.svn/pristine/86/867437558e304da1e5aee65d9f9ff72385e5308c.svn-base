package BampoManager::Stat::Placements;

use strict;
use warnings;

use Exporter 'import';
use BampoManager;
use BampoManager::Filter::Const qw/:PLACEMENT_LIST_FORMAT/;
use BampoManager::Stat qw/
    prepare_stat_rs
    check_placement_costs
    calc_leads
    calc_money
    calc_stat
    @STAT_COUNTERS
/;
use BampoManager::Utils::DB qw/
    filter_by_stat_period
    extra_filter_placements
    is_placement_match_filter
/;

our @EXPORT_OK = qw/
    get_placements_stat
/;

my @COUNTERS = @STAT_COUNTERS;

my @FILTER_EMPTY = (qw/impressions clicks leads_reach leads_uniq leads_nu placement_costs/);

#/////////////////////////////////////////////////////////////////////
sub get_placements_stat
{
    my ($stat_rs, $cpoint_row, $filter) = @_;

    $stat_rs = $stat_rs->search(undef, { group_by => ['me.sourceLineId'] });
    my $line_rs = prepare_stat_rs($stat_rs, $filter, { add_placement_costs => 1 });
    $line_rs = $line_rs->search(undef, { group_by => ['me.sourceLineId'] });

    # total leads by own and client's statistics
    my $total_leads  = 0;
    my $client_leads = get_cpoint_client_stat($cpoint_row, $filter);

    my %lines;
    foreach my $row ($line_rs->all)
    {
        my %data = $row->get_columns();
        next if not $filter->show_empty and not grep { $data{$_} and $data{$_} > 0 } @FILTER_EMPTY;

        # calc total leads value by own statistics and filter placements by hand if needed
        calc_leads(\%data);
        $total_leads += $data{leads};
        next if $filter->is_used_placement_extra_filter and not is_placement_match_filter(\%data, $filter);

        $data{profiles} = {};
        my $line_id = $data{line_id};
        $lines{$line_id} = \%data;
    }

    if ($filter->list_format eq FORMAT_PROFILE or $filter->list_format eq FORMAT_BANNER)
    {
        my $profile_rs = prepare_stat_rs($stat_rs, $filter);
        # we already have total leads value, so we can filter placements in DB
        my ($alias, $join) = ('source', 'source');
        $profile_rs = extra_filter_placements($profile_rs, $filter, $alias, $join);
        $profile_rs = $profile_rs->search(undef,
            {
                '+select' => ['me.profileId'],
                '+as'     => ['profile_id'],
                group_by  => ['me.sourceLineId', 'me.profileId']
            }
        );
        foreach my $row ($profile_rs->all)
        {
            my %data = $row->get_columns();
            next if not $filter->show_empty and not grep { $data{$_} and $data{$_} > 0 } @FILTER_EMPTY;
            $data{banners} = {};
            my $line_id    = $data{line_id};
            my $profile_id = $data{profile_id};
            $lines{$line_id}->{profiles}->{$profile_id} = \%data;
        }
    }

    if ($filter->list_format eq FORMAT_BANNER)
    {
        my $banner_rs = prepare_stat_rs($stat_rs, $filter);
        # we already have total leads value, so we can filter placements in DB
        my ($alias, $join) = ('source', 'source');
        $banner_rs = extra_filter_placements($banner_rs, $filter, $alias, $join);
        $banner_rs = $banner_rs->search(undef,
            {
                '+select' => ['me.profileId', 'me.bannerId'],
                '+as'     => [qw/profile_id banner_id/],
                group_by  => ['me.sourceLineId', 'me.profileId', 'me.bannerId']
            }
        );
        foreach my $row ($banner_rs->all)
        {
            my %data = $row->get_columns();
            next if not $filter->show_empty and not grep { $data{$_} and $data{$_} > 0 } @FILTER_EMPTY;
            my $line_id    = $data{line_id};
            my $profile_id = $data{profile_id};
            my $banner_id  = $data{banner_id};
            my $profile = $lines{$line_id}->{profiles}->{$profile_id};
            $profile->{banners}->{$banner_id} = \%data;
        }
    }

    my $result = [];
    my $total_stat = { map { $_ => 0 } @COUNTERS };
    my $adriver_db = BampoManager->model('Adriver');
    foreach my $line_id (keys %lines)
    {
        my $line = $lines{$line_id};
        calc_leads($line, $client_leads, $total_leads);
        calc_money($line);
        check_placement_costs($line, $filter);
        foreach (@COUNTERS)
        {
            $total_stat->{$_} += $line->{$_} if $line->{$_};
        }
        calc_stat($line);
        my $profiles = [];
        foreach my $profile_id (keys %{$line->{profiles}})
        {
            my $profile = $line->{profiles}->{$profile_id};
            calc_leads($profile, $client_leads, $total_leads);
            calc_money($profile);
            calc_stat($profile);
            my $banners = [];
            foreach my $banner_id (keys %{$profile->{banners}})
            {
                my $banner = $profile->{banners}->{$banner_id};
                calc_leads($banner, $client_leads, $total_leads);
                calc_money($banner);
                calc_stat($banner);
                $banner->{comment} = eval { $adriver_db->get_banner_comment($banner_id) } || $banner_id;
                push @$banners, $banner;
            }
            $profile->{banners} = $banners;
            $profile->{name}    = eval { $adriver_db->profile($profile_id)->name } || $profile_id;
            push @$profiles, $profile;
        }
        $line->{profiles} = $profiles;
        push @$result, $line;
    }

    calc_stat($total_stat);
    push @$result, $total_stat;

    return $result;
}

#/////////////////////////////////////////////////////////////////////
sub get_cpoint_client_stat
{
    my ($cpoint_row, $filter) = @_;

    my $client_stat_rs = $cpoint_row->client_stat;
    $client_stat_rs = filter_by_stat_period($client_stat_rs, $filter);
    my $leads_col = $client_stat_rs->get_column('leads_client');

    return $leads_col->sum();
}

#/////////////////////////////////////////////////////////////////////


1;
