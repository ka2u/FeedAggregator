package FADB::Feed;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ PK::Auto Core /);
__PACKAGE__->table('feeds');
__PACKAGE__->add_columns(qw/ id foldertitle feedtitle title creator link guid itemid pubdate timestamp /);
__PACKAGE__->set_primary_key('id');

1;
