package BampoManager::Exceptions;

use strict;
use warnings;

use Exception::Class (
    'BampoManager::Exception' => {
        description => "Base BampoManager interface exception.",
        fields      => 'status',
    },
    'BampoManager::Exception::UnAuthorized' => {
        isa         => 'BampoManager::Exception',
        description => "The user is not authorized.",
    },
    'BampoManager::Exception::BadRequest' => {
        isa         => 'BampoManager::Exception',
        description => "General exception for bad requests.",
    },
    'BampoManager::Exception::DBI' => {
        isa         => 'BampoManager::Exception',
        description => "General database run-time exception.",
    },
    'BampoManager::Exception::AdriverAPI' => {
        isa         => 'BampoManager::Exception',
        description => "Exceptions from Adriver::API module.",
    },
    'BampoManager::Exception::MediaplanNotFound' => {
        isa         => 'BampoManager::Exception',
    },
    'BampoManager::Exception::CouldNotDeleteMediaplan' => {
        isa         => 'BampoManager::Exception',
    },
    'BampoManager::Exception::AdvertiserNotFound' => {
        isa         => 'BampoManager::Exception',
    },
    'BampoManager::Exception::CouldNotDeleteAdvertiser' => {
        isa         => 'BampoManager::Exception',
    },
    'BampoManager::Exception::PlacementNotFound' => {
        isa         => 'BampoManager::Exception',
    },
    'BampoManager::Exception::CouldNotDeletePlacement' => {
        isa         => 'BampoManager::Exception',
    },
    'BampoManager::Exception::CPointNotFound' => {
        isa         => 'BampoManager::Exception',
    },
    'BampoManager::Exception::CouldNotDeleteCPoint' => {
        isa         => 'BampoManager::Exception',
    },
    'BampoManager::Exception::FormFu' => {
        isa         => 'BampoManager::Exception',
        description => "Base exception for errors arised in the forms.",
        fields      => 'user_msg',
    },
    'BampoManager::Exception::FormFu::VersionCollision' => {
        isa         => 'BampoManager::Exception::FormFu',
    },
    'BampoManager::Exception::FormFu::DuplicateEntry' => {
        isa         => 'BampoManager::Exception::FormFu',
    },
    'BampoManager::Exception::Costs' => {
        isa         => 'BampoManager::Exception',
    },
    'BampoManager::Exception::Costs::SourceNotFound' => {
        isa         => 'BampoManager::Exception::Costs',
    },
    'BampoManager::Exception::Costs::NoAPI' => {
        isa         => 'BampoManager::Exception::Costs',
    },
    'BampoManager::Exception::Costs::SourceClassNotSpecified' => {
        isa         => 'BampoManager::Exception::Costs',
    },
    'BampoManager::Exception::Costs::SourceClassLoadError' => {
        isa         => 'BampoManager::Exception::Costs',
    },
    'BampoManager::Exception::Costs::BadSourceClass' => {
        isa         => 'BampoManager::Exception::Costs',
    },
    'BampoManager::Exception::Costs::CampaignsNotSupported' => {
        isa         => 'BampoManager::Exception::Costs',
    },
    'BampoManager::Exception::Costs::Upload' => {
        isa         => 'BampoManager::Exception::Costs',
    },
    'BampoManager::Exception::Costs::Upload::File' => {
        isa         => 'BampoManager::Exception::Costs::Upload',
    },
    'BampoManager::Exception::Costs::Upload::File::Format' => {
        isa         => 'BampoManager::Exception::Costs::Upload::File',
    },
    'BampoManager::Exception::Costs::Upload::File::Size' => {
        isa         => 'BampoManager::Exception::Costs::Upload::File',
    },
    'BampoManager::Exception::Costs::Upload::File::Line' => {
        isa         => 'BampoManager::Exception::Costs::Upload::File',
        fields      => 'line_num',
    },
    'BampoManager::Exception::Costs::Upload::NotFoundPlacements' => {
        isa         => 'BampoManager::Exception::Costs::Upload',
        fields      => 'ids',
    },
    'BampoManager::Exception::Catalog' => {
        isa         => 'BampoManager::Exception',
    }
);

1;

