use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'FeedAggregator' }
BEGIN { use_ok 'FeedAggregator::Controller::List' }

ok( request('/list')->is_success, 'Request should succeed' );


