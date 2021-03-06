#!/usr/bin/perl

use strict;
use warnings;
use WebService::Bloglines;
use Encode;
use DateTime;
use DateTime::Format::HTTP;
use FindBin;
use lib qq($FindBin::Bin/../lib);
use FADB;

main();

sub main {
    my $schema = FADB->connect(
        'dbi:mysql:database=feedaggregator;host=localhost;port=3306',
        'mysqlID',
        'mysqlPassword',
        { on_connect_do => ['SET NAMES utf8'] },
    );
    
    my $bloglines = WebService::Bloglines->new(
        username => 'BloglinesID',
        password => 'BloglinesPassword',
        use_liberal => 1,
    );
    
    my $num = $bloglines->notify();
    my $subscription = $bloglines->listsubs();
    
    my $now = DateTime->now();
    $now->set_time_zone('Asia/Tokyo');
    
    my %data;
    my @folders = $subscription->folders();
    for my $folder (@folders) {
        $data{folder_title} = encode('utf-8', $folder->{title});
        my @feeds = $subscription->feeds_in_folder($folder->{BloglinesSubId});
        for my $feed (@feeds) {
            $data{feed_title} = encode('utf-8', $feed->{title});
            next if $feed->{BloglinesUnread} == 0;
            eval {
                # mark unread items as read if second arg 1.
                my $update = $bloglines->getitems($feed->{BloglinesSubId}, 1);
                for my $item ($update->items) {
                    $data{item_title} = encode('utf-8', $item->{title});
                    $data{item_creator} = encode('utf-8', $item->{dc}->{creator});
                    $data{item_link} = encode('utf-8', $item->{link});
                    $data{item_itemid} = encode('utf-8', $item->{bloglines}->{itemid});
                    $data{item_pubdate} = DateTime::Format::HTTP->parse_datetime(encode('utf-8', $item->{pubDate}));
                    $data{item_guid} = encode('utf-8', $item->{guid});
                    $data{timestamp} = $now;
                    _insert($schema, %data);
                }
            };
            _aggregation_error($schema, %data)  if $@;
        }
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
            pubdate     => $data{item_pubdate},
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
