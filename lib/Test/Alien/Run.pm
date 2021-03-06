package Test::Alien::Run;

use strict;
use warnings;
use Test2::API qw( context );

# ABSTRACT: Run object
# VERSION

=head1 SYNOPSIS

 use Test2::V0;
 use Test::Alien;
 
 run_ok([ $^X, -e => 'print "some output"; exit 22'])
   ->exit_is(22)
   ->out_like(qr{some});

=head1 DESCRIPTION

This class stores information about a process run as performed by
L<Test::Alien#run_ok>.  That function is the I<ONLY> way to create
an instance of this class.

=head1 ATTRIBUTES

=head2 out

 my $str = $run->out;

The standard output from the run.

=head2 err

 my $str = $run->err;

The standard error from the run.

=head2 exit

 my $int = $run->exit;

The exit value of the run.

=head2 signal

 my $int = $run->signal;

The signal that killed the run, or zero if the process was terminated normally.

=cut

sub out    { shift->{out} }
sub err    { shift->{err} }
sub exit   { shift->{exit} }
sub signal { shift->{sig} }

=head1 METHODS

These methods return the run object itself, so they can be chained,
as in the synopsis above.

=head2 success

 $run->success;
 $run->success($message);

Passes if the process terminated normally with an exit value of 0.

=cut

sub success
{
  my($self, $message) = @_;
  $message ||= 'command succeeded';
  my $ok = $self->exit == 0 && $self->signal == 0;
  $ok = 0 if $self->{fail};

  my $ctx = context();
  $ctx->ok($ok, $message);
  unless($ok)
  {
    $ctx->diag("  command exited with @{[ $self->exit   ]}") if $self->exit;
    $ctx->diag("  command killed with @{[ $self->signal ]}") if $self->signal;
    $ctx->diag("  @{[ $self->{fail} ]}") if $self->{fail};
  }
  $ctx->release;
  $self;
}

=head2 exit_is

 $run->exit_is($exit);
 $run->exit_is($exit, $message);

Passes if the process terminated with the given exit value.

=cut

sub exit_is
{
  my($self, $exit, $message) = @_;

  $message ||= "command exited with value $exit";
  my $ok = $self->exit == $exit;

  my $ctx = context();
  $ctx->ok($ok, $message);
  $ctx->diag("  actual exit value was: @{[ $self->exit ]}") unless $ok;
  $ctx->release;
  $self;
}

=head2 exit_isnt

 $run->exit_isnt($exit);
 $run->exit_isnt($exit, $message);

Passes if the process terminated with an exit value of anything
but the given value.

=cut

sub exit_isnt
{
  my($self, $exit, $message) = @_;

  $message ||= "command exited with value not $exit";
  my $ok = $self->exit != $exit;

  my $ctx = context();
  $ctx->ok($ok, $message);
  $ctx->diag("  actual exit value was: @{[ $self->exit ]}") unless $ok;
  $ctx->release;
  $self;
}

=head2 out_like

 $run->out_like($regex);
 $run->out_like($regex, $message);

Passes if the output of the run matches the given pattern.

=cut

sub _like
{
  my($self, $regex, $source, $not, $message) = @_;

  my $ok = $self->{$source} =~ $regex;
  $ok = !$ok if $not;

  my $ctx = context();
  $ctx->ok($ok, $message);
  unless($ok)
  {
    $ctx->diag("  $source:");
    $ctx->diag("    $_") for split /\r?\n/, $self->{$source};
    $ctx->diag($not ? '  matches:' : '  does not match:');
    $ctx->diag("    $regex");
  }
  $ctx->release;

  $self;
}

sub out_like
{
  my($self, $regex, $message) = @_;
  $message ||= "output matches $regex";
  $self->_like($regex, 'out', 0, $message);
}

=head2 out_unlike

 $run->out_unlike($regex);
 $run->out_unlike($regex, $message);

Passes if the output of the run does not match the given pattern.

=cut

sub out_unlike
{
  my($self, $regex, $message) = @_;
  $message ||= "output does not match $regex";
  $self->_like($regex, 'out', 1, $message);
}

=head2 err_like

 $run->err_like($regex);
 $run->err_like($regex, $message);

Passes if the standard error of the run matches the given pattern.

=cut

sub err_like
{
  my($self, $regex, $message) = @_;
  $message ||= "standard error matches $regex";
  $self->_like($regex, 'err', 0, $message);
}

=head2 err_unlike

 $run->err_unlike($regex);
 $run->err_unlike($regex, $message);

Passes if the standard error of the run does not match the given pattern.

=cut

sub err_unlike
{
  my($self, $regex, $message) = @_;
  $message ||= "standard error does not match $regex";
  $self->_like($regex, 'err', 1, $message);
}

=head2 note

 $run->note;

Send the output and standard error as test note.

=cut

sub note
{
  my($self) = @_;
  my $ctx = context();
  $ctx->note("[cmd]");
  $ctx->note("  @{$self->{cmd}}");
  if($self->out ne '')
  {
    $ctx->note("[out]");
    $ctx->note("  $_") for split /\r?\n/, $self->out;
  }
  if($self->err ne '')
  {
    $ctx->note("[err]");
    $ctx->note("  $_") for split /\r?\n/, $self->err;
  }
  $ctx->release;
  $self;
}

=head2 diag

 $run->diag;

Send the output and standard error as test diagnostic.

=cut

sub diag
{
  my($self) = @_;
  my $ctx = context();
  $ctx->diag("[cmd]");
  $ctx->diag("  @{$self->{cmd}}");
  if($self->out ne '')
  {
    $ctx->diag("[out]");
    $ctx->diag("  $_") for split /\r?\n/, $self->out;
  }
  if($self->err ne '')
  {
    $ctx->diag("[err]");
    $ctx->diag("  $_") for split /\r?\n/, $self->err;
  }
  $ctx->release;
  $self;
}

1;

=head1 SEE ALSO

=over 4

=item L<Test::Alien>

=back

=cut
