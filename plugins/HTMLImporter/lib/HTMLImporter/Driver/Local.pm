package HTMLImporter::Driver::Local;

use strict;
use warnings;
use base qw(  HTMLImporter::Driver );

use MT::FileMgr;

sub trace {
    my $driver = shift;
    my ( $dir, $filter, $handler ) = @_;
    return unless -d $dir;
    
    my @items;
    opendir DIR, $dir;
    foreach my $item (readdir(DIR)) {
        next if $item =~ /^\.{1,2}$/;
        push @items, $item;
    }
    closedir DIR;
    foreach my $item ( @items ) {
        my $path = File::Spec->catfile( $dir, $item );
        if ( -d $path ) {
            $driver->trace( $path, $filter, $handler );
        } elsif( -f $path ) {
            if ( $filter->( $item ) ) {
                $handler->( $path );
            }
        }
    }
}

sub get {
    my $driver = shift;
    my ( $path ) = @_;
    my $fmgr = MT::FileMgr->new( 'Local' );
    $fmgr->get_data( $path, 'upload' );
}

sub parse_dir {
    my $driver = shift;
    my ( $path ) = @_;
    my $sep;
    if ( $^O =~  /^MSWin/ ) {
        $sep = '\\';
    } else {
        $sep = '/';
    }
    my @dirs = split $sep, File::Basename::dirname( $path );
}

sub exists {
    my $driver = shift;
    my ( $path ) = @_;
    my $fmgr = MT::FileMgr->new( 'Local' );
    $fmgr->exists( $path );
}

1;