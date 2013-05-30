package HTMLImporter::Driver;

use strict;
use warnings;
use utf8;
use base qw( MT::ErrorHandler );
use Carp ();
use MT::I18N;
use MT::Util;
use Encode;
use HTML::TreeBuilder::XPath;
use HTML::Selector::XPath 'selector_to_xpath';
use URI;
use LWP::MediaTypes qw(guess_media_type);

our $plugin = MT->component( 'HTMLImporter' );

sub new {
    my $class = shift;
    my $type  = shift;
    $class .= "::" . $type;
    eval "use $class";
    die "Unsupported importer $class: $@" if $@;
    my $driver = bless {}, $class;
    $driver->init(@_)
        or return $class->error( $driver->errstr );
    return $driver;
}

sub init {
    my $driver = shift;
    my %args = @_;
    $driver->{ blog }           = $args{ blog };
    $driver->{ user }           = $args{ user };
    $driver->{ base_path }      = $args{ base_path };
    $driver->{ base_url }       = $args{ base_url };
    $driver->{ rules }          = $args{ rules };
    $driver->{ allow_override } = $args{ allow_override };
    $driver->{ suffix_list }    = $args{ suffix_list };
    $driver;
}

sub process {
    my $driver = shift;
    my ( $path ) = @_;
    my $app = MT->instance;
    my $import_from = $driver->{ base_path };
    return $driver->error( 'file not present.' ) unless $path;
    my $src_relative_path = File::Spec->abs2rel( $path, $import_from );
    my $blog = $driver->{ blog };
    my $blog_id = $blog->id;
    my $author = $driver->{ user };
    my $author_id = $author->id;
    my $rules = $driver->{ rules };
    
    my $text = $driver->get( $path )
        or return $driver->errstr;
    $text = MT::I18N::encode_text( $text, MT::I18N::guess_encoding( $text ), 'utf-8' );
    $text = Encode::is_utf8($text) ? $text : Encode::decode_utf8($text);
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->no_space_compacting( 1 );
    $tree->store_comments( 1 );
    $tree->parse( $text );
    $tree->eof();
    
    my %data;
    $data{ basename } = File::Basename::basename( $path, @{ $driver->{ suffix_list } } ) or return $driver->error( 'basename is not present.' );
    if ( my $title_elem = $tree->find('title') ) {
        $data{ title } = $title_elem->as_text('');
    }
    if ( my $node = ( $tree->look_down( '_tag', 'meta', 'name', 'keywords' ) )[0] ) {
        $data{ keywords } = $node->attr( 'content' );
    }
    if ( my $node = ( $tree->look_down( '_tag', 'meta', 'name', 'description' ) )[0] ) {
        $data{ excerpt } = $node->attr( 'content' );
    }
    foreach my $rule ( @$rules ) {
        my ( $source_type, $source, $target ) = ( $rule->{ source_type },  $rule->{ source }, $rule->{ target } );
        my $html;
        if ( $source_type eq 'css' ) {
            my @elems;
            @elems =  $tree->findnodes( selector_to_xpath( $rule->{ source }  ));
            my @parts;
            foreach my $elem ( @elems ) {
                my @children = $elem->content_list;
                 push @parts, join( "\n", map{ ref( $_ ) ? $_->as_HTML('') : $_ } @children );
            }
            if ( @parts ) {
                $html = join "\n", @parts;
            }
        } elsif ( $source_type eq 'regexp' ) {
            if ( $text =~ m|@{[ $rule->{ source } ]}|si ) {
                $html = $1;
            }
        }
        
        $data{ $target } = $html if defined( $html );
    }
    $tree = $tree->delete;
   
    my @assets;
    my $page;
    my $original;
    my @pages = MT->model( 'page' )->load({ blog_id => $blog->id, basename => $data{ basename } } );
    foreach ( @pages ) {
        if ( $src_relative_path eq $_->im_src_relative_path ) {
            $page = $_;
            last;
        }
    }
    if ( $page ) {
        return $driver->error( $plugin->translate( "'[_1]' has already been imported.", $src_relative_path ) )
            unless $driver->{ allow_override };
        $original = $page->clone;
    } else {
        $page = MT->model( 'page' )->new;
        $page->blog_id( $blog->id );
        $page->author_id( $author->id );
        $page->status( MT->model( 'page' )->RELEASE() );
        $page->allow_comments( $blog->allow_comments_default );
        $page->allow_pings( $blog->allow_pings_default );
        $page->convert_breaks( 'richtext' );
        $page->im_src_relative_path( $src_relative_path );
    }
    my @tl = MT::Util::offset_time_list( time, $blog );
    my $ts = sprintf '%04d%02d%02d%02d%02d%02d', $tl[ 5 ] + 1900, $tl[ 4 ] + 1, @tl[ 3, 2, 1, 0 ];
    $page->modified_on( $ts );
    foreach my $field ( keys %data ) {
        if ( $page->can( $field ) || $field =~ /^field\./ ) {
            $data{ $field } = $driver->_save_assets( $src_relative_path, $data{ $field }, \@assets );
            $page->$field( $data{ $field } );
        }
    }
    
    $app->run_callbacks( 'cms_pre_save.page', $app, $page, $original );
    $page->save or die $page->errstr;
    
    if ( my $relative_path = $src_relative_path ) {
        my $folder = $driver->dir2folder( $relative_path );
        if ( $folder ) {
            my @placements = MT->model( 'placement' )->load(
            { blog_id       => $blog->id,
              entry_id      => $page->id });
            foreach my $placement ( @placements ) {
                $placement->remove or die $placement->errstr;
            }
            my $placement = MT->model( 'placement' )->new;
            $placement->blog_id( $blog->id );
            $placement->entry_id( $page->id );
            $placement->category_id( $folder->id );
            $placement->is_primary( 1 );
            $placement->save or die $placement->errstr;
        }
    }
    foreach my $asset ( @assets ) {
        my $objectasset = MT->model( 'objectasset' )->get_by_key(
            { blog_id   => $blog->id,
              asset_id  => $asset->id,
              object_id => $page->id,
              object_ds => $page->datasource });
        unless ( $objectasset->id ) {
            $objectasset->save or die $objectasset->errstr;
        }
    }
    $app->run_callbacks( 'cms_post_save.page', $app, $page, $original );
    
    $driver->log( $plugin->translate( "imported: '[_1]'", $path ), ( page => $page ) );
    
    1;
}

sub dir2folder {
    my $driver = shift;
    my ( $relative_path ) = @_;
    my @dirs = $driver->parse_dir( $relative_path );
    my $folder;
    foreach my $dir ( @dirs ) {
        next if $dir eq '.';
        $folder = $driver->_get_folder( $dir, $folder );
    }
    $folder;
}

sub _get_folder {
    my $driver = shift;
    my ( $basename, $parent ) = @_;
    my $user = MT->instance->user;
    
    my $folder = MT->model( 'folder' )->get_by_key(
        { blog_id   => $driver->{ blog }->id,
          basename  => $basename,
          parent    => $parent ? $parent->id : 0,
        } );
    unless ( $folder->id ) {
        $folder->label( $basename );
        $folder->author_id( $user->id ) if $user;
        $folder->save or die $folder->errstr;
    }
    $folder;
}

# アセット登録
sub _save_assets {
    my $driver = shift;
    my ( $relative_file, $html, $ref_assets ) = @_;
    my $blog = $driver->{ blog };
    my $user = $driver->{ user };
    my $root_dir = $driver->{ base_path }; 
    my $app = MT->instance;
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->no_space_compacting( 1 );
    $tree->store_comments( 1 );
    my $marker_id = time . '_' . rand( time );
    my $start_marker = '<!--[[START_MARKER_' .  $marker_id . ']]-->';
    my $end_marker = '<!--[[END_MARKER_' .  $marker_id . ']]-->';
    $html = "<div>$start_marker" . ( $html || '' ) . "$end_marker</div>";
    $tree->parse( $html );
    $tree->eof();
    
    my $save_asset = sub {
        my ( $href ) = @_;
        my $absolute_path;
        if ( $href =~ /^https?:/ ) {
            # 
        } elsif ( $href =~ /^\// ) {
            $absolute_path = File::Spec->catfile( $root_dir, $href );
        } else {
            $absolute_path = File::Spec->rel2abs( $href, File::Spec->catdir( $root_dir, File::Basename::dirname( $relative_file ) ) );
        }
        return unless $absolute_path;
        $absolute_path = File::Spec->canonpath( $absolute_path );
        my $relative_path = File::Spec->abs2rel( $absolute_path, $root_dir );
        return unless my $ext = ( File::Basename::fileparse( $absolute_path, qw( .jpg .jpeg .png .gif .JPG .JPEG .PNG .GIF ) ) )[2];
        unless ( $driver->exists( $absolute_path ) ) {
            $driver->log( $plugin->translate( 'Asset file is not found. (href: [_1] / absolute_path: [_2])', $href, $absolute_path ) );
            return;
        }
        my $new_path = File::Spec->catfile( $blog->site_path, $relative_path );
        my $basename = File::Basename::basename( $new_path );
        my $r_path = File::Spec->catfile( '%r', $relative_path );
        my $mime_type = guess_media_type( $new_path );
        my $asset_pkg = MT->model( 'asset' )->handler_for_file( $new_path );
        my $asset = $asset_pkg->get_by_key( { blog_id => $blog->id, file_path => $r_path } );
        if ( $asset->id ) {
            return $asset unless $driver->{ allow_override };
        } else {
            $asset->file_name( $basename );
            $asset->file_ext( $ext );
            $asset->label( $basename );
            $asset->url( $r_path );
            $asset->mime_type( $mime_type || 'application/octet-stream' );
            $asset->created_by( $user->id );
        }
        if ( my $data = $driver->get( $absolute_path ) ) {
            my $fmgr = $blog->file_mgr() || MT::FileMgr->new( 'Local' );
            my $dir = File::Basename::dirname( $new_path );
            $fmgr->mkpath( $dir ) unless $fmgr->exists( $dir );
            $fmgr->put_data( $data, $new_path, 'upload' );
        }
        if ( $asset_pkg->isa( 'MT::Asset::Image' ) ) {
            $asset->image_width( undef );
            $asset->image_height( undef );
        }

        $asset->save() or die $asset->errstr;
        return $asset;
    };
    
    my @anchors = $tree->find( 'a' );
    foreach my $anchor ( @anchors ) {
        my $href = $anchor->attr( 'href' );
        next unless defined( $href );
        $href = MT::Util::decode_url( $href );
        my $asset = $save_asset->( $href ) or next;
        $anchor->attr( 'href', $asset->url );
        push @$ref_assets, $asset;
    }
    my @imgs = $tree->find( 'img' );
    foreach my $img ( @imgs ) {
        my $src = $img->attr( 'src' );
        next unless defined( $src );
        $src = MT::Util::decode_url( $src );
        my $asset = $save_asset->( $src ) or next;
        $img->attr( 'src', $asset->url );
        push @$ref_assets, $asset;
    }
    my $result = $tree->as_HTML( '' );
    $tree = $tree->delete;
    $result =~ s/^.*@{[ quotemeta($start_marker) ]}//m;
    $result =~ s/@{[ quotemeta($end_marker) ]}.*$//m;
    return $result;
}

sub log {
    my $driver = shift;
    my $message = shift;
    my %opts = @_;
    my $page = $opts{ page };
    MT->log({
        blog_id     => $driver->{ blog }->id,
        author_i    => $driver->{ user }->id,
        message     => $message,
        category    => 'HTMLImporter',
        ( $page ? ( metadata    => $page->id )          : () ),
        ( $page ? ( class       => 'MT::Log::Page' )    : () ),
    });
}

sub trace   { Carp::croak("NOT IMPLEMENTED"); }
sub get     { Carp::croak("NOT IMPLEMENTED"); }
sub parse_dir   { Carp::croak("NOT IMPLEMENTED"); }
sub exists  { Carp::croak("NOT IMPLEMENTED"); }

1;