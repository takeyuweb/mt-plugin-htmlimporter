package HTMLImporter::Plugin;

use strict;
use warnings;

use MT;
use MT::Util;

our $plugin = MT->component( 'HTMLImporter' );

sub _start_htmlimport {
    my $app = shift;
    my $blog = $app->blog or return $app->trans_error( 'Invalid request' );
    
    my @fields = (
        [ 'text',           'Page Body' ],
        [ 'text_more',      'Extended' ],
        [ 'created_on',     'Created On' ],
        [ 'modified_on',    'Last update' ],
        [ 'authored_on',    'Published Date' ],
        [ 'title',          'Title(Override)' ],
        [ 'keywords',       'Keywords(Override)' ],
        [ 'excerpt',        'Description(Override)' ],
    );
    
    eval{ require CustomFields::Field; };
    unless( $@ ){
        my $field_iter = MT->model( 'field' )->load_iter(
            { blog_id   => [0, $blog->id],
              obj_type  => 'page' },
        );
        while ( my $field = $field_iter->() ) {
            push @fields, [ 'field.' . $field->basename, $field->name ];
        }
    };

    my $tmpl = $app->load_tmpl( 'start_htmlimport.tmpl' );
    my $params = {
        fields => [],
    };
    grep{ push @{$params->{ fields }}, { label => $app->translate( $_->[1] ), field => $_->[0] }; } @fields;
    $app->build_page( $tmpl, $params );
}


sub _htmlimport {
    my $app = shift;
    my $blog = $app->blog or return $app->trans_error( 'Invalid request' );
    $app->validate_magic or return $app->trans_error( 'Invalid request' );
    my $q = $app->param();
    my $author = $app->user;
    
    my $import_from = File::Spec->canonpath( $q->param( 'import_from' ) );
    my $override = $q->param( 'override' ) eq '1' ? 1 : 0;
    my @target_directories = grep { $_ ne "" } split(/\r?\n/, ( $q->param( 'target_directories' ) || '' ) );
    @target_directories = map{ File::Spec->catdir( $import_from, $_ ) } @target_directories;
    my @exclude_directories = grep { $_ ne "" } split(/\r?\n/, ( $q->param( 'exclude_directories' ) || '' ) );
    @exclude_directories = map{ File::Spec->catdir( $import_from, $_ ) } @exclude_directories;
    
    my @suffix_list = qw/.html .htm .HTML .HTM/;
    
    my @rules = ();
    foreach my $key ( $q->param ) {
        next unless $key =~ /^source_type\[(\d+)\]/;
        my $cursor = $1;
        my $source_type = $q->param( "source_type[$cursor]" );
        my $source = $q->param( "source[$cursor]" );
        my $target = $q->param( "target[$cursor]" );
        push @rules, { source_type => $source_type, source => $source, target => $target };
    }
    
    require HTMLImporter::Driver;
    my $driver = HTMLImporter::Driver->new( 'Local',
        blog        => $blog,
        user        => $author,
        base_path   => $import_from,
        rules       => \@rules,
        allow_override  => $override,
        suffix_list => \@suffix_list );
    
    my $can_background_task = MT::Util::launch_background_tasks();
    my @import_successes = ();
    my @import_failures = ();
    my $filter;
    $filter = sub {
        my ( $type, $path ) = @_;
        if ( $type eq 'directory' ) {
            foreach ( @exclude_directories ) {
                my $exclude_directory = quotemeta( $_ );
                if ( $path =~ /^$exclude_directory($|\/)/ ) {
                    return 0;
                }
            };
            return 1;
        } elsif ( $type eq 'file' ) {
            my @parts = ( File::Basename::fileparse( $path, @suffix_list ) );
            my $suffix = $parts[2];
            return $suffix ? 1 : 0;
        }
    };
    my $import_func = sub {
        my $process = sub {
            my ( $path ) = @_;
            my $basename = File::Basename::basename( $path, @suffix_list );
            eval {
                if ( $driver->process( $path ) ) {
                    push @import_successes, $path;
                } else {
                    die $driver->errstr;
                }
            };
            if ( my $errstr = $@ ) {
                $driver->log( $plugin->translate( "Import Error: '[_1]' ([_2])", $path, $errstr ) );
                push @import_failures, $path;
            }
        };
        $driver->log( $plugin->translate( 'Start importing from HTML.' ) );
        foreach my $target_directory ( @target_directories ) {
            $driver->trace( $target_directory, $filter, $process );
        }
        $driver->log( $plugin->translate( 'Finish importing from HTML.' ) );
    };
    if ( $can_background_task ) {
        MT::Util::start_background_task( $import_func );
    } else {
        $import_func->();
    }
    
    my $tmpl = $app->load_tmpl( 'htmlimport.tmpl' );
    my $params = {
        can_background_task => $can_background_task,
        import_successes    => \@import_successes,
        rules               => \@rules,
        import_from         => $import_from,
        target_directories  => \@target_directories,
        exclude_directories => \@exclude_directories,
        override            => $override,
    };
    $app->build_page( $tmpl, $params );
}

1;