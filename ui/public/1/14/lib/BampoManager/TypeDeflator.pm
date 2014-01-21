package BampoManager::TypeDeflator;

use Moose;
use Moose::Util::TypeConstraints;
use BampoManager::Exceptions;

extends 'Adriver::MooseX::TypeMap::Deflator';


my $e_type;

#/////////////////////////////////////////////////////////////////////
$e_type = find_type_constraint('BampoManager::Exception') ||
    Moose::Util::TypeConstraints::create_class_type_constraint('BampoManager::Exception');

__PACKAGE__->meta->add_handler($e_type => sub {
    my ($self, $e) = @_;
    return { type => ref($e), error => "$e" };
});

#/////////////////////////////////////////////////////////////////////
$e_type = find_type_constraint('BampoManager::Exception::Costs::Upload::NotFoundPlacements') ||
    Moose::Util::TypeConstraints::create_class_type_constraint('BampoManager::Exception::Costs::Upload::NotFoundPlacements');

__PACKAGE__->meta->add_handler($e_type => sub {
    my ($self, $e) = @_;
    return { type => ref($e), error => "$e", ids => $e->ids };
});

#/////////////////////////////////////////////////////////////////////
$e_type = find_type_constraint('BampoManager::Exception::Costs::Upload::File::Line') ||
    Moose::Util::TypeConstraints::create_class_type_constraint('BampoManager::Exception::Costs::Upload::File::Line');

__PACKAGE__->meta->add_handler($e_type => sub {
    my ($self, $e) = @_;
    return { type => ref($e), error => "$e", line_num => $e->line_num };
});

#/////////////////////////////////////////////////////////////////////


1;
