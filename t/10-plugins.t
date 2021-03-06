use Test::More;
use Test::Exception;
use strict;
use warnings;

use AnyEvent::Filesys::Notify;

# Used to shorten the tests
my $AEFN = 'AnyEvent::Filesys::Notify';

subtest 'Try to load the correct backend for this O/S' => sub {
    if ( $^O eq 'linux' and eval { require Linux::Inotify2; 1 } ) {
        my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
        isa_ok( $w, $AEFN );
        ok( !$w->does("${AEFN}::Role::Fallback"), '... Fallback' );
        ok( $w->does("${AEFN}::Role::Inotify2"),  '... Inotify2' );
        ok( !$w->does("${AEFN}::Role::FSEvents"), '... FSEvents' );
        ok( !$w->does("${AEFN}::Role::KQueue"),   '... KQueue' );

    } elsif (
        $^O eq 'darwin' and eval {
            require Mac::FSEvents;
            1;
        } )
    {
        my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
        isa_ok( $w, $AEFN );
        ok( !$w->does("${AEFN}::Role::Fallback"), '... Fallback' );
        ok( !$w->does("${AEFN}::Role::Inotify2"), '... Inotify2' );
        ok( $w->does("${AEFN}::Role::FSEvents"),  '... FSEvents' );
        ok( !$w->does("${AEFN}::Role::KQueue"),   '... KQueue' );

    } elsif (
        $^O =~ /bsd/ and eval {
            require IO::KQueue;
            1;
        } )
    {
        my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
        isa_ok( $w, $AEFN );
        ok( !$w->does("${AEFN}::Role::Fallback"), '... Fallback' );
        ok( !$w->does("${AEFN}::Role::Inotify2"), '... Inotify2' );
        ok( !$w->does("${AEFN}::Role::FSEvents"), '... FSEvents' );
        ok( $w->does("${AEFN}::Role::KQueue"),    '... KQueue' );

    } else {
        my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
        isa_ok( $w, $AEFN );
        ok( $w->does("${AEFN}::Role::Fallback"),  '... Fallback' );
        ok( !$w->does("${AEFN}::Role::Inotify2"), '... Inotify2' );
        ok( !$w->does("${AEFN}::Role::FSEvents"), '... FSEvents' );
        ok( !$w->does("${AEFN}::Role::KQueue"),   '... KQueue' );
    }
};

subtest 'Try to load the fallback backend via no_external' => sub {
    my $w = AnyEvent::Filesys::Notify->new(
        dirs        => ['t'],
        cb          => sub { },
        no_external => 1,
    );
    isa_ok( $w, $AEFN );
    ok( $w->does("${AEFN}::Role::Fallback"),  '... Fallback' );
    ok( !$w->does("${AEFN}::Role::Inotify2"), '... Inotify2' );
    ok( !$w->does("${AEFN}::Role::FSEvents"), '... FSEvents' );
    ok( !$w->does("${AEFN}::Role::KQueue"),   '... KQueue' );
};

subtest 'Try to specify Fallback via the backend arguement' => sub {
    my $w = AnyEvent::Filesys::Notify->new(
        dirs    => ['t'],
        cb      => sub { },
        backend => 'Fallback',
    );
    isa_ok( $w, $AEFN );
    ok( $w->does("${AEFN}::Role::Fallback"),  '... Fallback' );
    ok( !$w->does("${AEFN}::Role::Inotify2"), '... Inotify2' );
    ok( !$w->does("${AEFN}::Role::FSEvents"), '... FSEvents' );
    ok( !$w->does("${AEFN}::Role::KQueue"),   '... KQueue' );
};

subtest 'Try to specify +AEFNR::Fallback via the backend arguement' => sub {
    my $w = AnyEvent::Filesys::Notify->new(
        dirs    => ['t'],
        cb      => sub { },
        backend => "+${AEFN}::Role::Fallback",
    );
    isa_ok( $w, $AEFN );
    ok( $w->does("${AEFN}::Role::Fallback"),  '... Fallback' );
    ok( !$w->does("${AEFN}::Role::Inotify2"), '... Inotify2' );
    ok( !$w->does("${AEFN}::Role::FSEvents"), '... FSEvents' );
    ok( !$w->does("${AEFN}::Role::KQueue"),   '... KQueue' );
};

if ( $^O eq 'darwin' and eval { require IO::KQueue; 1; } ) {

    subtest 'Try to force KQueue on Mac with IO::KQueue installed' => sub {
        my $w = eval {
            AnyEvent::Filesys::Notify->new(
                dirs    => ['t'],
                cb      => sub { },
                backend => 'KQueue'
            );
        };
        isa_ok( $w, $AEFN );
        ok( !$w->does("${AEFN}::Role::Fallback"), '... Fallback' );
        ok( !$w->does("${AEFN}::Role::Inotify2"), '... Inotify2' );
        ok( !$w->does("${AEFN}::Role::FSEvents"), '... FSEvents' );
        ok( $w->does("${AEFN}::Role::KQueue"),    '... KQueue' );
      }
}

done_testing;
