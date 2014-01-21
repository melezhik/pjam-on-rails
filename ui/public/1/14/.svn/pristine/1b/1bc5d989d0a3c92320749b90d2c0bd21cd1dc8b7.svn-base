package BampoManager;

use Moose;
use namespace::autoclean;
use Catalyst::Runtime 5.80;
use Catalyst;
use Log::Log4perl::Catalyst;
use File::ShareDir qw/dist_dir/;

extends 'Catalyst';

use version; our $VERSION = version->declare("v0.19.6");

__PACKAGE__->config(
    name => 'BampoManager',
    disable_component_resolution_regex_fallback => 1,
    'View::TT' => {
        INCLUDE_PATH => '__path_to(templates)__',
    },
    static => {
        dirs  => ['static', qw/css img js html/],
        ignore_extensions => [qw/tt2/],
        include_path      => ['__path_to(templates)__/static'],
    },
    session => {
        dbic_class     => 'Bampo::Session',
        expires        => '80000',
        id_field       => 'id',
        data_field     => 'session_data',
        expires_field  => 'expires',
        verify_address => '1',
    },
    'Controller::HTML::FormFu' => {
        'default_action_use_path' => 1,
        'constructor' => {
            'config_file_path' => '__path_to(templates)__/forms',
            'render_method' => 'tt',
            'tt_args' => {
                'ENCODING' => 'UTF-8',
                'INCLUDE_PATH' => '__path_to(templates)__/formfu',
            },
        },
        'model_stash' => {
            'schema' => 'Bampo',
        },
    },
    'Plugin::ConfigLoader' => {
        driver => {
            General => {
                -UseApacheInclude => 1,
                -IncludeRelative  => 1,
                -InterPolateVars  => 1,
                -InterPolateEnv   => 1,
                -ForceArray       => 1,
            }
        },
    },

);


__PACKAGE__->setup(qw/
    ConfigLoader
    ConfigurablePathTo
    Static::Simple
    Unicode::Encoding
    CasX

    Authentication
    Authorization::Roles
    Session
    Session::Store::DBIC
    Session::State::Cookie
    +Adriver::Catalyst::Plugin::ReliableChainedAction
/);


__PACKAGE__->log(Log::Log4perl::Catalyst->new(__PACKAGE__->config->{'log4perl'}));

__PACKAGE__->model('Bampo')->storage->debug(1) if __PACKAGE__->config->{'Model::Bampo'}->{'debug'};

1;
