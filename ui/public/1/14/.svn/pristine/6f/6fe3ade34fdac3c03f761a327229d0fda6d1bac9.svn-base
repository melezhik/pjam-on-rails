use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name   => 'BampoManager',
    dist_author   => 'Dmitry Bigunyak (dima@adriver.ru)',
    dist_abstract => 'Manager interface for Bampo',
    license       => 'perl',
    requires => {
        'perl'                                     => '5.8.7',
        'Catalyst'                                 => '5.7007',
        'Catalyst::Runtime'                        => 0,
        'Catalyst::Authentication::Store::DBIx::Class'   => 0,
        'Catalyst::Authentication::Store::LDAPx'         => 0,
        'Catalyst::Authentication::Credential::Password' => 0,
        'Catalyst::Controller::HTML::FormFu'       => '0.09003',
        'Catalyst::Model::DBIC::Schema'            => '0.40',
        'Catalyst::Plugin::Authentication'         => 0,
        'Catalyst::Plugin::Authorization::Roles'   => 0,
        'Catalyst::Plugin::ConfigLoader'           => 0,
        'Catalyst::Plugin::ConfigurablePathTo'     => 0,
        'Catalyst::Plugin::Session'                => 0,
        'Catalyst::Plugin::Session::Store::DBIC'   => 0,
        'Catalyst::Plugin::Session::State::Cookie' => 0,
        'Catalyst::Plugin::Static::Simple'         => 0,
        'Catalyst::Plugin::Unicode::Encoding'      => 0,
        'Catalyst::View::TT'                       => 0,
        'Catalyst::Controller::REST'               => 0,
        'CGI::Util'                                => 0,
        'DateTime'                                 => 0,
        'DateTime::Format::Natural'                => 0,
        'DBIx::Class'                              => '0.08126',
        'Encode'                                   => '2.21',
        'Exception::Class'                         => 0,
        'Exporter'                                 => 0,
        'File::ShareDir'                           => 0,
        'File::Temp'                               => 0,
        'HTML::FormFu'                             => '0.09004',
        'HTML::FormFu::Model::DBIC'                => '0.09002',
        'HTTP::Status'                             => 0,
        'List::AllUtils'                           => 0,
        'List::MoreUtils'                          => '0.33',
        'List::Util'                               => '1.23',
        'Log::Log4perl::Catalyst'                  => 0,
        'Math::Round'                              => 0,
        'MIME::Types'                              => 0,
        'MooseX::Params::Validate'                 => '0.16',
        'MooseX::Storage'                          => 0,
        'namespace::autoclean'                     => 0,
        'Readonly'                                 => 0,
        'Scalar::Util'                             => 0,
        'Text::CSV'                                => 0,
        'Test::Deep'                               => 0,
        # OUR modules
        'Catalyst::CasX'                           => 0,
        'Adriver::API'                             => '1.0.1',
        'Adriver::Date'                            => 0,
        'Adriver::Mail'                            => 0,
        'Adriver::MooseX::TypeMap'                 => 0,
        'Adriver::MooseX::Types'                   => 0,
        'Adriver::Catalyst::Authentication::Store::Adriver' => 0,
        'Adriver::Catalyst::Plugin::ReliableChainedAction'  => 0,
        'Adriver::DBI'                             => '0.2.9',
        'BampoManager::Schema'                     => '0.16.6',
        'BampoManager::Costs::Interface'           => '0.1.4',
        'Adriver::Dictionary::Schema' => 0,
        'Adriver::Dictionary::API'    => '0.1.2',
        'Adriver::Mime::Type'         => 0,

	# missed dependencies:
        'Adriver::MooseX::Types' => 0,
        'Test::Most' => 0,
        'FCGI' => 0,
        'Adriver::FCGI::ProcManager' => 0,
        'CatalystX::Component::Traits' => '0.14',
        'Tie::IxHash' => 0,
        'Mail::IMAPClient' => 0,
        'MIME::Tools' => '3.0',
        'HTML::FormatText' => '2.01',
        'JSON::Any' => 0,
        'MooseX::SetOnce' => '0.200001',


    },
    requires_build => {
        'Data::Dumper'   => 0,
        'Module::Build'  => '0.36',
        'Test::More'     => 0,
    },
    recommends => {
        'Adriver::ForeignLeads::GoogleAnalytics'        => 0,
        'BampoManager::Costs::Statistics::CPM'          => 0,
        'BampoManager::Costs::Statistics::Soloway'      => 0,
        'BampoManager::Costs::Statistics::Vkontakte'    => 0,
        'BampoManager::Costs::Statistics::GoogleBanner' => 0,
        'BampoManager::Costs::Statistics::YandexDirect' => 0,
        'BampoManager::Costs::Statistics::Luxup'        => 0,
    },
    #share_dir    => 'root',
    script_files => {
        'script/bampomanager_cgi.pl'     => undef,
        'script/bampomanager_fastcgi.pl' => undef,
        'script/bampomanager_server.pl'  => undef,
        'script/bampomanager.psgi'       => undef,
    },
    conf_files => {
        'bampomanager.conf'     => 'conf/bampomanager.conf.in',
        'bampomanager_log.conf' => 'conf/bampomanager_log.conf.in',
    },
    install_base => '/usr/local/rle/',
);

$build->add_build_element('conf');
$build->install_path(conf => $build->install_base . "/etc");
$build->install_path(script => $build->install_base . "/cgi-bin");
$build->create_build_script();

