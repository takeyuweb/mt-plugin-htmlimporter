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
    
    my $target_type = $q->param( 'target_type' );
    if ( $target_type eq 'file' ) {
        _htmlimport_by_file( $app );
    } elsif ( $target_type eq 'directory' ) {
        _htmlimport_by_directory( $app );
    } else {
        return $app->trans_error( 'Invalid request' );
    }
}

sub _htmlimport_by_directory {
    my $app = shift;
    my $blog = $app->blog;
    my $q = $app->param();
    my $author = $app->user;
    
    my $import_from = File::Spec->canonpath( $q->param( 'import_from' ) );
    my $override = $q->param( 'override' ) eq '1' ? 1 : 0;
    my @target_directories = grep { $_ ne "" } split(/\r?\n/, ( $q->param( 'target_directories' ) || '' ) );
    @target_directories = map{ File::Spec->catdir( $import_from, $_ ) } @target_directories;
    my @exclude_directories = grep { $_ ne "" } split(/\r?\n/, ( $q->param( 'exclude_directories' ) || '' ) );
    @exclude_directories = map{ File::Spec->catdir( $import_from, $_ ) } @exclude_directories;
    
    my @suffix_list = @{ $app->config->HTMLSuffix };
    
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
        MT->log("[$type] path:$path");
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
            MT->log( "suffix:$suffix (@{[Data::Dumper->Dump(\@suffix_list)]})" );
            return $suffix ? 1 : 0;
        }
    };
    my $import_func = sub {
        my $process = sub {
            my ( $path ) = @_;
            my $basename = File::Basename::basename( $path, @suffix_list );
            eval {
                if ( my $page = $driver->process( $path ) ) {
                    push @import_successes, { path => $path, page => { id => $page->id, title => $page->title } };
                } else {
                    die $driver->errstr;
                }
            };
            if ( my $errstr = $@ ) {
                $driver->log( $plugin->translate( "Import Error: '[_1]' ([_2])", $path, $errstr ) );
                push @import_failures, { path => $path, errstr => $errstr };
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
        import_failures     => \@import_failures,
        rules               => \@rules,
        import_from         => $import_from,
        target_type         => 'directory',
        target_directories  => \@target_directories,
        exclude_directories => \@exclude_directories,
        override            => $override,
    };
    $app->build_page( $tmpl, $params );
}


sub _htmlimport_by_file {
    my $app = shift;
    my $blog = $app->blog;
    my $q = $app->param();
    my $author = $app->user;
    
    my $import_from = File::Spec->canonpath( $q->param( 'import_from' ) );
    my $override = $q->param( 'override' ) eq '1' ? 1 : 0;
    my @target_files = grep { $_ ne "" } split(/\r?\n/, ( $q->param( 'target_files' ) || '' ) );
    @target_files = map{ File::Spec->catdir( $import_from, $_ ) } @target_files;
    
    my @suffix_list = @{ $app->config->HTMLSuffix };
    
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

    my $import_func = sub {
        $driver->log( $plugin->translate( 'Start importing from HTML.' ) );
        foreach my $path ( @target_files ) {
            eval {
                if ( my $page = $driver->process( $path ) ) {
                    push @import_successes, { path => $path, page => { id => $page->id, title => $page->title } };
                } else {
                    die $driver->errstr;
                }
            };
            if ( my $errstr = $@ ) {
                $driver->log( $plugin->translate( "Import Error: '[_1]' ([_2])", $path, $errstr ) );
                push @import_failures, { path => $path, errstr => $errstr };
            }
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
        import_failures     => \@import_failures,
        rules               => \@rules,
        import_from         => $import_from,
        target_type         => 'file',
        target_files        => \@target_files,
        override            => $override,
    };
    $app->build_page( $tmpl, $params );
}

1;