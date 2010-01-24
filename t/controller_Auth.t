use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'FeedAggregator' }
BEGIN { use_ok 'FeedAggregator::Controller::Auth' }

ok( request('/auth')->is_success, 'Request should succeed' );


