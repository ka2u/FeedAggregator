#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use DateTime;
use DateTime::Format::HTTP;
use FindBin;
use lib qq($FindBin::Bin/../lib);
use FADB;
use WebService::LivedoorReader;
use Data::Dumper;

main();

sub main {

    my $schema = FADB->connect(
        'dbi:mysql:database=feedaggregator;host=localhost;port=3306',
        'mysqlID',
        'mysqlPassword',
        { on_connect_do => ['SET NAMES utf8'] },
    );

    # mark unread items as read if second arg 1.    
    my $reader = WebService::LivedoorReader->new(
        'livedoorreaderID',
        'livedoorreaderPassword',
	0,
    );

    my $subscription = $reader->notifier;

    my $now = DateTime->now();
    $now->set_time_zone('Asia/Tokyo');
    
    my %data;
    for my $feed (@{$subscription}) {
        $data{folder_title} = $feed->{folder};
        my @entries = $reader->get_unreads($feed->{subscribe_id}) or next;
        for my $unreads (@entries) {
	    my $items = $unreads->{items};
            $data{feed_title} = $feed->{title};
	    for my $entry (@{$items}) {
		eval {
		    my $pubd = DateTime->from_epoch(epoch =>
				  $entry->{created_on});
    		    $data{item_title} = $entry->{title};
		    $data{item_creator} = $entry->{author};
		    $data{item_link} = $entry->{link};
		    $data{item_itemid} = $entry->{id};
		    $data{item_pubdate} = $pubd->ymd . ' ' .$pubd->hms;
		    $data{item_guid} = $entry->{link};
		    $data{timestamp} = $now;
		    _insert($schema, %data);
		};
		_aggregation_error($schema, %data)  if $@;
	    }
        }
	$reader->mark_readed($feed->{subscribe_id});
    }
}

sub _insert {
    my ($schema, %data) = @_;

    eval {
        $schema->resultset('FADB::Feed')->create({
            foldertitle => $data{folder_title},
            feedtitle   => $data{feed_title},
            title       => $data{item_title} || 'nonetitle',
            creator     => $data{item_creator} || 'unknown',
            link        => $data{item_link},
            itemid      => $data{item_itemid},
            pubdate     => $data{item_pubdate} || 'nonepubdate',
            guid        => $data{item_guid} || 'noneguid',
            timestamp   => $data{timestamp},
        });
    };
    warn "insert failed. $@" if $@;
}

sub _aggregation_error {
    my ($schema, %data) = @_;

    $data{item_title} = "# Error #";
    $data{item_creator} = "# Error #";
    $data{item_link} = "# Error #";
    $data{item_itemid} = "# Error #";
    $data{item_pubdate} = "# Error #";
    $data{item_guid} = "# Error #";
    _insert($schema, %data);
}

exit;
