
use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN { use_ok('MooseX::TypeMap') }

use MooseX::TypeMap::Entry;
use MooseX::Types::Moose (
  qw(Str Int Num Ref Object Value Defined HashRef ArrayRef Undef),
);


my %entries;
lives_ok {
  %entries = (
    Defined => MooseX::TypeMap::Entry->new( type_constraint => Defined, data => 'defined'),
    Str => MooseX::TypeMap::Entry->new( type_constraint => Str, data => 'str'),
    Int => MooseX::TypeMap::Entry->new( type_constraint => Int, data => 'int'),
    Num => MooseX::TypeMap::Entry->new( type_constraint => Num, data => 'num'),
    Ref => MooseX::TypeMap::Entry->new( type_constraint => Ref, data => 'ref'),
    Obj => MooseX::TypeMap::Entry->new( type_constraint => Object, data => 'obj'),
    Value => MooseX::TypeMap::Entry->new( type_constraint => Value, data => 'value'),
    HashRef => MooseX::TypeMap::Entry->new( type_constraint => HashRef, data => 'HashRef'),
  );
} 'Entries build normally';


my $type_map = MooseX::TypeMap->new( subtype_entries => [ values %entries ] );
is( $type_map->resolve(ArrayRef), 'ref' );
is( $type_map->resolve(HashRef), 'HashRef' );
ok( !defined $type_map->resolve(Undef) );


__END__;
