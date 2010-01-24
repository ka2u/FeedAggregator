package FADB::User;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ PK::Auto Core /);
__PACKAGE__->table('users');
__PACKAGE__->add_columns(qw/ id user_id passwd mail /);
__PACKAGE__->set_primary_key('id');

1;
