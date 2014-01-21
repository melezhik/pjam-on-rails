package BampoManager::Filter::Const;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = (qw/
    PERIOD_TODAY
    PERIOD_YESTERDAY
    PERIOD_WEEK
    PERIOD_MONTH
    PERIOD_CUR_MONTH
    PERIOD_LAST_MONTH
    PERIOD_CUSTOM

    FORMAT_OWN FORMAT_AGENCY FORMAT_CLIENT FORMAT_ALL

    FORMAT_CAMPAIGN FORMAT_PROFILE FORMAT_BANNER

/);

our %EXPORT_TAGS = (
    STAT_PERIOD => [qw/
        PERIOD_TODAY
        PERIOD_YESTERDAY
        PERIOD_WEEK
        PERIOD_MONTH
        PERIOD_CUR_MONTH
        PERIOD_LAST_MONTH
        PERIOD_CUSTOM
    /],

    LIST_FORMAT => [qw/
        FORMAT_OWN
        FORMAT_AGENCY
        FORMAT_CLIENT
        FORMAT_ALL
    /],

    PLACEMENT_LIST_FORMAT => [qw/
        FORMAT_CAMPAIGN
        FORMAT_PROFILE
        FORMAT_BANNER
    /],
);

use constant {
    PERIOD_TODAY      => 'today',
    PERIOD_YESTERDAY  => 'yesterday',
    PERIOD_WEEK       => 'week',
    PERIOD_MONTH      => 'month',
    PERIOD_CUR_MONTH  => 'cur_month',
    PERIOD_LAST_MONTH => 'last_month',
    PERIOD_CUSTOM     => 'custom',
};


use constant {
    FORMAT_OWN    => 'own',
    FORMAT_AGENCY => 'agency',
    FORMAT_CLIENT => 'client',
    FORMAT_ALL    => 'all',
};

use constant {
    FORMAT_CAMPAIGN => 'campaign',
    FORMAT_PROFILE  => 'profile',
    FORMAT_BANNER   => 'banner',
};

1;
