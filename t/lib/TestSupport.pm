package TestSupport;

use strict;
use warnings;
use File::Temp qw(tempdir);
use File::Path;
use File::Basename;
use File::Copy qw(move);
use Test::More;
use autodie;

use Exporter qw(import);
our @EXPORT_OK = qw(create_test_files delete_test_files move_test_files
  modify_attrs_on_test_files $dir received_events receive_event);

our $dir = tempdir( CLEANUP => 1 );
my $size = 1;

sub create_test_files {
    my (@files) = @_;

    for my $file (@files) {
        my $full_file = File::Spec->catfile( $dir, $file );
        my $full_dir = dirname($full_file);

        mkpath $full_dir unless -d $full_dir;

        my $exists = -e $full_file;

        open my $fd, ">", $full_file;
        print $fd "Test\n" x $size++ if $exists;
        close $fd;
    }
}

sub delete_test_files {
    my (@files) = @_;

    for my $file (@files) {
        my $full_file = File::Spec->catfile( $dir, $file );
        if   ( -d $full_file ) { rmdir $full_file; }
        else                   { unlink $full_file; }
    }
}

sub move_test_files {
    my (%files) = @_;

    while ( my ( $src, $dst ) = each %files ) {
        my $full_src = File::Spec->catfile( $dir, $src );
        my $full_dst = File::Spec->catfile( $dir, $dst );
        move $full_src, $full_dst;
    }
}

sub modify_attrs_on_test_files {
    my (@files) = @_;

    for my $file (@files) {
        my $full_file = File::Spec->catfile( $dir, $file );
        chmod 0750, $full_file or die "Error chmod on $full_file: $!";
    }
}

our @received = ();
our @expected = ();
our @msgs     = ();
our $cv;

sub receive_event {
    push @received, @_;
    push @msgs,
      "--- received: " . join( ',', map { $_->type . ":" . $_->path } @_ );
    $cv->end for @_;
}

sub received_events {
    my ( $sub, $desc, @expected ) = @_;

    $cv = AnyEvent->condvar;
    $cv->begin for @expected;

    $sub->();

    my $w =
      AnyEvent->timer( after => 5, cb => sub {
              ok( 0, '... the next test listed timed out' );
              $cv->send;
          } );

    $cv->recv;

    my @received_type = map { $_->type } @received;
    if ( not is_deeply( \@received_type, \@expected, $desc ) ) {
        diag sprintf "... expected: %s\n... received: %s\n",
          join( ',', @expected ), join( ',', @received_type );
        diag join "\n", @msgs;
    }

    @received = ();
    @msgs = ();
}

1;
