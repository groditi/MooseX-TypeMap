package MooseX::TypeMap;

use Moose;
use MooseX::TypeMap::Entry;
use Scalar::Util qw(refaddr);
use MooseX::Types::Moose qw(ArrayRef);

our $VERSION = '0.001000';

has entries => (
  is => 'ro',
  isa => ArrayRef['MooseX::TypeMap::Entry'],
  lazy => 1,
  builder => '_build_entries',
);

has subtype_entries => (
  is => 'ro',
  isa => ArrayRef['MooseX::TypeMap::Entry'],
  lazy => 1,
  builder => '_build_subtype_entries',
);

has _sorted_entries => (
  is => 'ro',
  isa => ArrayRef[ArrayRef['MooseX::TypeMap::Entry']],
  lazy => 1,
  init_arg => undef,
  builder => '_build__sorted_entries',
);

sub _build_entries { [] }
sub _build_subtype_entries { [] }

sub _build__sorted_entries {
  my $self = shift;
  my @entries = @{ $self->subtype_entries };

  my %subtypes;
  my %tc_entry_map;
  for my $entry (@entries) {
    my $entry_tc = $entry->type_constraint;
    my $entry_addr = refaddr $entry_tc;
    $subtypes{$entry_addr} = {};
    $tc_entry_map{$entry_addr} = $entry;

    for my $other (@entries) {
      my $other_tc = $other->type_constraint;
      if( $other_tc->is_subtype_of($entry_tc) ){
        $subtypes{$entry_addr}->{refaddr $other_tc} = undef
      }
    }
  }

  my @sorted;
  while (keys %subtypes) {
    my @slot;
    for my $addr (keys %subtypes) {
      if (!keys %{ $subtypes{$addr} }) {
        delete $subtypes{$addr};
        push(@slot, $addr);
      }
    }

    map { delete @{$_}{@slot} } values %subtypes;
    push @sorted, [ @tc_entry_map{@slot} ];
  }

  return \@sorted;
}

sub find_matching_entry {
  my($self, $type) = @_;
  for my $entry (@{ $self->entries }) {
    return $entry if $entry->type_constraint->equals($type);
  }

  for my $family (@{ $self->_sorted_entries }) {
    for my $entry (@{ $family }) {
      my $tc = $entry->type_constraint;
      return $entry if $type->equals($tc) || $type->is_subtype_of($tc);
    }
  }
  return;
}

sub has_entry_for {
  my($self, $type) = @_;
  return defined $self->find_matching_entry($type);
}

sub resolve  {
  my($self, $type) = @_;
  if( my $entry = $self->find_matching_entry($type) ){
    return $entry->data;
  }
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

MooseX::TypeMap - A type-constraint-to-data map

=head1 SYNOPSIS

    use MooseX::Types::Moose qw(Str Int Num Value);

    my $map = MooseX::TypeMap->new(
      entries => [
        MooseX::TypeMap::Entry->new(
          data => 'number',
          type_constraint => Num,
        )
      ],
      subtype_entries => [
        MooseX::TypeMap::Entry->new(
          data => 'string',
          type_constraint => Str,
        )
      ]
    );

    $map->resolve(Int); #returns 'string'
    $map->resolve(Num); #returns 'number'
    $map->resolve(Str); #returns 'string'
    $map->resolve(Value); #returns an undefined value

=head1 ATTRIBUTES

=head2 entries

A read-only ArrayRef of L<Entry|MooseX::TypeMap::Entry> objects. These entry
objects will only match on L</resolve> when the type constraint given is equal
to the type constraint in the entry.

The following methods are associated with this attribute:

=over 4

=item B<entries> - reader

=item B<_build_entries> - builder, defaults to C<[]>

=back

=head2 subtype_entries

A read-only ArrayRef of L<Entry|MooseX::TypeMap::Entry> objects. These entry
objects will match on L</resolve> when the type constraint given is equal
to, or a sub-type of, the type constraint in the entry.

The following methods are associated with this attribute:

=over 4

=item B<subtype_entries> - reader

=item B<_build_subtype_entries> - builder, defaults to C<[]>

=back

=head2 _sorted_entries

A private attribute that mantains a sorted array of arrays of entries in the
order in which they will be looked at if there is no matching entry in C<entries>
This attribute can not be set from the constructor, has no public methods and is
only being documented for the benefit of future contributors.

The following methods are associated with this attribute:

=over 4

=item B<_sorted_entries> - reader

=item B<_build__sorted_entries> - builder

=back

=head1 METHODS

=head2 new

=over 4

=item B<arguments:> C<\%arguments>

=item B<return value:> C<$object_instance>

=back

Constructor.
Accepts the following keys: C<entries>, C<subtype_entries>.

=head2 find_matching_entry

=over 4

=item B<arguments:> C<$type>

=items B<return value:> C<$entry>

=back

Will return the C<$entry> C<$type> resolves to, or an undefined value if no
matching entry is found.

=head2 has_entry_for

=over 4

=item B<arguments:> C<$type>

=items B<return value:> boolean C<$has_entry>

=back

Will return true if the given C<$type> resolves to an entry and false otherwise.

=head2 resolve

=over 4

=item B<arguments:> C<$type>

=items B<return value:> C<$data_from_matching_entry>

=back

Will find the closest matching entry for C<$type> and return the contents of
the entries L<data|MooseX::typeMap::Entry/data> attribute;

=head1 AUTHORS

=over 4

=item Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=item Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=item Guillermo Roditi E<lt>groditi@cpan.orgE<gt>

=back

=head1 AUTHORS, COPYRIGHT AND LICENSE

This software is copyright (c) 2008, 2009 by its authos as listed in the
L</AUTHORS> section.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
