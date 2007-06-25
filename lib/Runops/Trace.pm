package Runops::Trace;

use strict;
use warnings;
use Digest::MD5 'md5_hex';

our $VERSION = '0.06';

use DynaLoader ();
our @ISA = qw( DynaLoader Exporter );
Runops::Trace->bootstrap($VERSION);

our @EXPORT_OK = qw( trace_code checksum_code_path trace );
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

sub checksum_code_path {
    my ($f) = @_;

    # Just stash the pointers.
    my $ops = '';
    _trace_function( sub { $ops .= pack 'J', $_[1] }, $f );

    return md5_hex($ops);
}

sub trace_code {
    my ($f) = @_;
    my $ops = '';
    _trace_function( sub { $ops .= sprintf '%s=(0x%x) ', @_ }, $f );
    chop $ops;

    return $ops;
}

sub trace {
    my ( $tracer, $callback ) = @_;

    _trace_function( $tracer, $callback );
    return;
}

1;

__END__

=head1 NAME

Runops::Trace - Trace your program's execution

=head1 SYNOPSIS

  use Runops::Trace 'checksum_code_path';
  sub is_even { shift() % 2 == 0 ? 1 : 0 }

  my %sufficient;
  for my $number ( 0 .. 10 ) {
      # Get a signature for the code 
      my $codepath = checksum_code_path(
          sub { is_even( $number ) }
      );

      if ( not exists $sufficient{$codepath} ) {
          $sufficient{$codepath} = $number;
      }
  }
  print join ' ', keys %sufficient;

=head1 DESCRIPTION

This module traces opcodes as they are executed by the perl VM. The
trace function can be turned on globally or just during the execution
of a single function.

=head1 INTERFACE

=over

=item trace( TRACE, FUNCTION )

This is a generic way of tracing a function. It ensures that your
C<TRACE> function is called before every operation in the C<FUNCTION>
function.

The C<TRACE> function will be given the L<B::OP> object that is about
to be run. The C<TRACE> function will be called in void context and
will not be given any parameters.

The C<FUNCTION> function will be called in void context and will not
be given any parameters.

There is no useful return value from this function.

=item MD5SUM = checksum_code_path( FUNCTION )

This returns a hex MD5 checksum of the ops that were visited. This is
a nice, concise way of representing a unique path through code.

=item STRING = trace_code( FUNCTION )

This returns a string representing the ops that were executed. Each op
is represented as its name and hex address in memory.

=back

=head1 PERL HACKS COMPATIBILITY

This module does not currently implement the interface as described in
the O'Reilly book Perl Hacks.

=head1 ADVANCED NOTES

=over

=item THREAD-UNSAFE

I made no attempt at thread safety. Do not use this module in a
multi-threaded process.

=item WRITE YOUR OWN SUGAR

The C<trace( TRACE, FUNCTION )> function is sufficient to allow any
arbitrary kind of access to running code. This module is included with
two simple functions to return useful values. Consider looking at
their source code and writing your own.

=item ON THE FLY CODE MODIFICATION

If the L<B::Generate> module is loaded, the B:: object that is passed
to the tracing function may also be modified. This would allow you to
modify the perl program as it is running. Thi

=back

=head1 AUTHOR

Rewritten by Joshua ben Jore, originally written by chromatic, based
on L<Runops::Switch> by Rafael Garcia-Suarez.

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl 5.8.x itself.

=cut
