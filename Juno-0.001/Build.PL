
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::Fatal" => 0,
    "Test::Fork" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Asynchronous event-driven checking mechanism",
  "dist_author" => [
    "Sawyer X <xsawyerx\@cpan.org>"
  ],
  "dist_name" => "Juno",
  "dist_version" => "0.001",
  "license" => "perl",
  "module_name" => "Juno",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Any::Moose" => 0,
    "AnyEvent" => 0,
    "AnyEvent::HTTP" => 0,
    "AnyEvent::Util" => 0,
    "Carp" => 0,
    "Class::Load" => 0,
    "JSON" => 0,
    "System::Command" => 0,
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
