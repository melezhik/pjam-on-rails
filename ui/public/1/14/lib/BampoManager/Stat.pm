package BampoManager::Stat;

use strict;
use warnings;

use Exporter 'import';
use DateTime;
use DateTime::Format::Natural;
use Math::Round;
use Readonly;
use BampoManager;
use BampoManager::Schema::Const qw/:PRICE_TYPE :STAT_TYPE/;
use BampoManager::Filter::Const qw/:STAT_PERIOD/;
use BampoManager::Utils::DB qw/filter_by_stat_period/;

our @EXPORT_OK = qw/
    prepare_stat_rs
    check_placement_costs
    calc_leads
    calc_money
    calc_client_stat
    calc_stat
    @STAT_COUNTERS
/;

Readonly our @STAT_COUNTERS => (qw/
    impressions
    clicks
    leads
    our_leads
    profit
    costs_exp
    costs_real_inner
    costs_real_outer
    costs_deviation
    leads_reach
    leads_uniq
    leads_nu
    leads_proper
/);

#/////////////////////////////////////////////////////////////////////
sub prepare_stat_rs
{
    my ($stat_rs, $filter, $options) = @_;

    $stat_rs = $stat_rs->search(undef,
        {
            '+select' => [
                'target.statType',
                'target.supercom',
                'target.priceType',
                'target.priceSale',
                'target.profitability',
                'source.priceType',
                'source.pricePurchase',
                'source.costsSourceId',
                'source.title',
                'source.bannerFormatId',
                'source.priceProductId',
                'source.channelGroupId',
                'source.placementTargetingId',
                { SUM => 'me.impressions'  },  # -as => 'impressions'  },
                { SUM => 'me.clicks'       },  # -as => 'clicks'       },
                { SUM => 'me.leads_reach'  },  # -as => 'leads_reach'  },
                { SUM => 'me.leads'        },  # -as => 'leads_uniq'   },
                { SUM => 'me.leads_nu'     },  # -as => 'leads_nu'     },
                { SUM => 'me.leads_proper' },  # -as => 'leads_proper' },
            ],
            '+as' => [qw/
                stat_type
                supercom
                cp_price_type
                price_sale
                cp_profitability
                placement_price_type
                price_purchase
                placement_costs_source
                placement_title
                banner_format_id
                product_id
                channel_group_id
                placement_targeting_id
                impressions
                clicks
                leads_reach
                leads_uniq
                leads_nu
                leads_proper
            /],
            join => ['target', 'source'],
        }
    );

    $stat_rs = filter_by_stat_period($stat_rs, $filter, 'me');
    if ($options->{add_placement_costs})
    {
        $stat_rs = add_placement_costs($stat_rs, $filter);
    }
    elsif ($options->{add_placement_costs_daily})
    {
        $stat_rs = add_placement_costs_daily($stat_rs);
    }

    return $stat_rs;
}

#/////////////////////////////////////////////////////////////////////
sub add_placement_costs
{
    my ($stat_rs, $filter) = @_;

    # Prepere costs rs
    my $source_costs_rs = BampoManager->model('Bampo::Costs')->search(
        {
            'costs.lineId' => { '=', \'me.sourceLineId' },
        },
        {
            alias => 'costs',
        }
    );

    # We can't filter placement costs only by filter period,
    # we have to considering cpoint start and stop dates to prevent
    # double calculation of the same placements costs for different cpoints
    $source_costs_rs = $source_costs_rs->search( {
            -and => [
                # startDate
                -or => [
                    -and => [
                        { 'target.startDate' => { '>', $filter->start_date->strftime('%F') } },
                        { 'costs.date'       => { '>=', \'target.startDate' } },
                    ],
                    -and => [
                        { 'target.startDate' => { '<=', $filter->start_date->strftime('%F') } },
                        { 'costs.date'       => { '>=', $filter->start_date->strftime('%F') } },
                    ],
                ],
                # stopDate
                -or => [
                    -and => [
                        -or => [
                            { 'target.stopDate' => { '=', undef } },
                            { 'target.stopDate' => { '>', $filter->stop_date->strftime('%F') } },
                        ],
                        { 'costs.date' => { '<=', $filter->stop_date->strftime('%F') } },
                    ],
                    -and => [
                        { 'target.stopDate' => { '!=', undef } },
                        { 'target.stopDate' => { '<=', $filter->stop_date->strftime('%F') } },
                        { 'costs.date' => { '<=', \'target.stopDate' } },
                    ],
                ],
            ],
        }
    );

    # Add costs queries
    $stat_rs = $stat_rs->search(undef,
        {
            '+select' => [ $source_costs_rs->get_column('costs')->sum_rs->as_query, $source_costs_rs->count_rs->as_query ],
            '+as'     => ['placement_costs', 'costs_rows_num'],
        }
    );

    return $stat_rs;
}

#/////////////////////////////////////////////////////////////////////
sub add_placement_costs_daily
{
    my ($stat_rs) = @_;

    $stat_rs = $stat_rs->search(undef,
        {
            '+select' => ['source_costs.costs'],
            '+as'     => [qw/placement_costs/],
            join      => 'source_costs',
        }
    );

    return $stat_rs;
}

#/////////////////////////////////////////////////////////////////////
sub check_placement_costs
{
    my ($placement_stat, $filter) = @_;

    my $stat_duration = $filter->stop_date->delta_days($filter->start_date);
    $stat_duration->add(days => 1);
    my $stat_days_num = $stat_duration->in_units('days');

    if ($placement_stat->{placement_costs_source})
    {
        if ($placement_stat->{impressions} or $placement_stat->{clicks})
        {
            $placement_stat->{costs_check_ok} = ($placement_stat->{costs_rows_num} == $stat_days_num) ? 1 : 0;
        }
        else
        {
            $placement_stat->{costs_check_ok} = 1;
        }
    }
    else
    {
        $placement_stat->{costs_check_ok} = 1;
    }

    return undef;
}

#/////////////////////////////////////////////////////////////////////
sub calc_leads
{
    my ($stat_obj, $client_leads, $total_leads) = @_;

    if ($stat_obj->{cp_price_type} eq PRICE_TYPE_CPV)
    {
        $stat_obj->{our_leads} = $stat_obj->{leads_reach};
    }
    elsif ($stat_obj->{cp_price_type} eq PRICE_TYPE_CPL)
    {
        $stat_obj->{our_leads} = $stat_obj->{leads_uniq};
    }
    else #(cp_price_type eq PRICE_TYPE_CPA or cp_price_type eq PRICE_TYPE_CPC)
    {
        $stat_obj->{our_leads} = $stat_obj->{leads_nu};
    }

    # calc distribution of client leads if we pass more than one parameter
    #  * our_leads - contains only our leads
    #  * leads     - may contain either our leads or distributed client leads
    if (@_ > 1 and $stat_obj->{stat_type} eq STAT_TYPE_CLIENT)
    {
        $client_leads = 0 unless defined $client_leads;
        my $factor = ($total_leads) ? $stat_obj->{our_leads} / $total_leads : 0;
        $stat_obj->{leads} = $client_leads * $factor;
    }
    else
    {
        $stat_obj->{leads} = $stat_obj->{our_leads};
    }
}

#/////////////////////////////////////////////////////////////////////
sub real_price_sale
{
    my ($stat_obj) = @_;
    my $price_sale = $stat_obj->{price_sale} * (100 - $stat_obj->{supercom}) / 100;
    return $price_sale;
}

#/////////////////////////////////////////////////////////////////////
# calc_leads subroutine should be called before calc_money
sub calc_money
{
    my ($stat_obj) = @_;

    $stat_obj->{profit} = real_price_sale($stat_obj) * $stat_obj->{leads};

    # costs_exp        - expected costs (estimated)
    # costs_real_inner - inner real costs
    # costs_real_outer - outer real costs
    # costs_deviation  - special case for calculation Deviation
    if ($stat_obj->{placement_price_type} eq PRICE_TYPE_CPM)
    {
        $stat_obj->{costs_exp} = $stat_obj->{price_purchase} * $stat_obj->{impressions} / 1000;
        $stat_obj->{costs_deviation} = $stat_obj->{costs_exp};
        if (defined $stat_obj->{placement_costs_source})
        {
            $stat_obj->{costs_real_outer} = $stat_obj->{placement_costs};
            $stat_obj->{costs_real_inner} = $stat_obj->{placement_costs};
        }
        else
        {
            $stat_obj->{costs_real_outer} = $stat_obj->{costs_exp};
            $stat_obj->{costs_real_inner} = $stat_obj->{costs_exp};
        }
    }
    elsif ($stat_obj->{placement_price_type} eq PRICE_TYPE_CPC)
    {
        $stat_obj->{costs_exp} = $stat_obj->{price_purchase} * $stat_obj->{clicks};
        if (defined $stat_obj->{placement_costs_source})
        {
            $stat_obj->{costs_real_outer} = $stat_obj->{placement_costs};
            $stat_obj->{costs_real_inner} = $stat_obj->{placement_costs};
            $stat_obj->{costs_deviation}  = $stat_obj->{placement_costs};
        }
        else
        {
            $stat_obj->{costs_real_outer} = $stat_obj->{costs_exp};
            $stat_obj->{costs_real_inner} = $stat_obj->{costs_exp};
            $stat_obj->{costs_deviation}  = $stat_obj->{costs_exp};
        }
    }
    elsif ($stat_obj->{placement_price_type} eq PRICE_TYPE_RS)
    {
        $stat_obj->{costs_exp} = $stat_obj->{price_purchase} * $stat_obj->{impressions} / 1000;
        $stat_obj->{costs_real_outer} = $stat_obj->{placement_costs};
        $stat_obj->{costs_real_inner} = $stat_obj->{costs_exp};
        $stat_obj->{costs_deviation}  = $stat_obj->{costs_exp};
    }

    $stat_obj->{costs_exp}        = 0 unless defined $stat_obj->{costs_exp};
    $stat_obj->{costs_real_outer} = 0 unless defined $stat_obj->{costs_real_outer};
    $stat_obj->{costs_real_inner} = 0 unless defined $stat_obj->{costs_real_inner};
    $stat_obj->{costs_deviation}  = 0 unless defined $stat_obj->{costs_deviation};
}

#/////////////////////////////////////////////////////////////////////
sub calc_client_stat
{
    my $line_stat = shift;
    my $client_line_stat = shift;

    if ($line_stat->{stat_type} eq STAT_TYPE_CLIENT)
    {
        $line_stat->{leads}  = (defined $client_line_stat) ? $client_line_stat->{leads_client} : 0;
        $line_stat->{profit} = real_price_sale($line_stat) * $line_stat->{leads};
    }
}

#/////////////////////////////////////////////////////////////////////
sub calc_stat
{
    my $stat_obj = shift;

    if ($stat_obj->{leads} > 0)
    {
        $stat_obj->{lead_cost_est}  = sprintf("%.2f", $stat_obj->{costs_exp} / $stat_obj->{leads});
        $stat_obj->{lead_cost}      = sprintf("%.2f", $stat_obj->{costs_real_inner} / $stat_obj->{leads});
        $stat_obj->{lead_cost_real} = sprintf("%.2f", $stat_obj->{costs_real_outer} / $stat_obj->{leads});
    }

    if ($stat_obj->{our_leads} > 0)
    {
        $stat_obj->{lead_cost_our} = sprintf("%.2f", $stat_obj->{costs_real_inner} / $stat_obj->{our_leads});
    }

    if ($stat_obj->{clicks} > 0)
    {
        $stat_obj->{lead_rate} = sprintf("%.2f", $stat_obj->{leads} * 100 / $stat_obj->{clicks});
    }

    if ($stat_obj->{impressions} > 0)
    {
        $stat_obj->{CTR} = sprintf("%.2f", $stat_obj->{clicks} * 100 / $stat_obj->{impressions});
        $stat_obj->{CPM} = sprintf("%.2f", $stat_obj->{costs_real_outer} * 1000 / $stat_obj->{impressions});
        $stat_obj->{conversion_rate} = sprintf("%.3f", $stat_obj->{leads} * 100 / $stat_obj->{impressions});
    }

    $stat_obj->{leads} = sprintf("%.2f", $stat_obj->{leads});

    # costs
    $stat_obj->{costs_est}  = round($stat_obj->{costs_exp}) if defined $stat_obj->{costs_exp};
    $stat_obj->{costs}      = round($stat_obj->{costs_real_inner}) if defined $stat_obj->{costs_real_inner};
    $stat_obj->{costs_real} = round($stat_obj->{costs_real_outer}) if defined $stat_obj->{costs_real_outer};

    $stat_obj->{deviation}  = round($stat_obj->{profit} / 2 - $stat_obj->{costs_deviation});
    if ($stat_obj->{profit})
    {
        $stat_obj->{profitability} = sprintf("%.2f",
            ($stat_obj->{profit} - $stat_obj->{costs_real_outer}) / $stat_obj->{profit} * 100);
    }

    highlight_values($stat_obj);
}

#/////////////////////////////////////////////////////////////////////
sub highlight_values
{
    my ($stat_obj) = @_;

    if (defined $stat_obj->{profitability} and defined $stat_obj->{cp_profitability}
        and $stat_obj->{profitability} < $stat_obj->{cp_profitability})
    {
        $stat_obj->{highlight_profitability} = 1;
    }

    if (defined $stat_obj->{price_purchase} and $stat_obj->{placement_price_type} eq PRICE_TYPE_RS
        and $stat_obj->{CPM} < $stat_obj->{price_purchase})
    {
        $stat_obj->{highlight_cpm} = 1;
    }
}

#/////////////////////////////////////////////////////////////////////


1;
