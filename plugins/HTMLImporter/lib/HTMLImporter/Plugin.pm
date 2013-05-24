package HTMLImporter::Plugin;

use strict;
use warnings;

use MT;

our $plugin = MT->component( 'HTMLImport' );

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
    
    my $import_from = $q->param( 'import_from' );
    my @suffix_list = qw/.html .htm .HTML .HTM/;
    my $filter = sub {
        my ( $filename ) = @_;
        my $suffix = ( File::Basename::fileparse( $filename, @suffix_list ) )[2];
        return $suffix ? 1 : 0;
    };
    
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
        suffix_list => \@suffix_list );
    
    my $process = sub {
        my ( $path ) = @_;
        my $basename = File::Basename::basename( $path, @suffix_list );
        $driver->process( $path ) or die driver()->errstr;
    };
    $driver->trace( $import_from, $filter, $process );
}

1;