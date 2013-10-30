package SyncCheck::Plugin;

use strict;
use warnings;

use MT;
use MT::Util;

our $plugin = MT->component( 'SyncCheck' );

# 下書き以外で保存した場合、インポート対象から外す
sub _cb_cms_post_save_page {
    my ( $cb, $app, $obj, $original ) = @_;
    return 1 unless ref($app) =~ /^MT::App::CMS/;
    my $field = 'field.page_skip_htmlimport';
    if ( $obj->status != MT->model('page')->HOLD() ) {
        unless ( $obj->$field ) {
            $app->param( 'customfield_page_skip_htmlimport', 1 );
        }
    }
    return 1;
}

# インポートスキップフラグ（カスタムフィールド）がONのものはインポートしない
sub _cb_cms_pre_htmlimport {
    my ( $cb, $app, $obj, $original ) = @_;
    
    my $field = 'field.page_skip_htmlimport';
    if ( $obj->status != MT->model('page')->HOLD() || $obj->$field ) {
        return $app->error( 'Skipped.' );
    } else {
        return 1;
    }
}

1;