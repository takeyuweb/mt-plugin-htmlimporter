package HTMLImporter::L10N::ja;

use strict;
use warnings;
use base 'HTMLImporter::L10N::en_us';

use vars qw( %Lexicon );

%Lexicon = (
    '_PLUGIN_DESCRIPTION'   => '既存のHTMLファイルをMTのウェブページとして一括インポート、CMS化を支援します。',
    # config.yaml
    'Import from HTML'      => 'HTMLからインポート',
    # tmpl/start_import.tmpl
    'Import settings'   => 'インポート設定',
    'Import from'       => 'インポート元ルートディレクトリ',
    'It is mapped to the web site root.'    => 'ウェブサイトルートにマッピングされます。',
    'Source type'       => 'データソース種別',
    'CSS Selector'      => 'CSSセレクタ',
    'Source'            => 'データソース',
    'Target field'      => 'インポート先フィールド',
    'Title(Override)'   => 'タイトル（上書き）',
    'Keywords(Override)'    => 'キーワード（上書き）',
    'Description(Override)' => '説明（上書き）',
    'Add rule'          => 'インポートルールを追加',
    'Start import'      => 'インポート開始',
);