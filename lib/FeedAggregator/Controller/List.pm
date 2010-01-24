package FeedAggregator::Controller::List;

use strict;
use warnings;
use base 'Catalyst::Controller';

use WebService::Bloglines;
use Encode;
use DateTime;
use DateTime::Format::HTTP;
use Data::Dumper;

=head1 NAME

FeedAggregator::Controller::List - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched FeedAggregator::Controller::List in List.');
}

sub content : Local {
    my ( $self, $c ) = @_;

    $c->forward('dates');
    $c->forward('folders');

    $c->session->{timestamp} = $c->request->params->{timestamp} if $c->request->params->{timestamp};

    my $rs = $c->model('FADB::Feed')->search(
        {
            timestamp => $c->session->{timestamp} || $c->stash->{dates}->[0]->timestamp,
        },
        {
            page  => $c->request->params->{page} || 1,
            rows  => 100,
            order_by => 'pubdate DESC',
        }
    );

    my $feedtitle_rs = $c->model('FADB::Feed')->search(
        undef,
        {
            columns  => ['feedtitle'],
            distinct => 1,
        },
    );

    $c->stash->{feeds} = [$rs->all];
    $c->stash->{pager} = $rs->pager;
    $c->stash->{feedtitles} = [$feedtitle_rs->all];
    $c->stash->{page_link} = "content";
    $c->stash->{template} = 'list.tt2';
}

sub mobile : Local {
    my ( $self, $c ) = @_;

    $c->forward('dates');
    $c->session->{timestamp} = $c->request->params->{timestamp} if $c->request->params->{timestamp};

    my $rs = $c->model('FADB::Feed')->search(
        {
            timestamp => $c->session->{timestamp} || $c->stash->{dates}->[0]->timestamp,
        },
        {
            page  => $c->request->params->{page} || 1,
            rows  => 30,
            order_by => 'pubdate DESC',
        }
    );

    my $feedtitle_rs = $c->model('FADB::Feed')->search(
        undef,
        {
            columns  => ['feedtitle'],
            distinct => 1,
        },
    );

    $c->stash->{feeds} = [$rs->all];
    $c->stash->{pager} = $rs->pager;
    $c->stash->{feedtitles} = [$feedtitle_rs->all];
    $c->stash->{page_link} = "mobile";
    $c->stash->{template} = 'mobile.tt2';
}

sub folder : Local {
    my ( $self, $c ) = @_;

    $c->forward('dates');
    $c->forward('folders');

    $c->session->{foldertitle} = $c->request->params->{folder} if $c->request->params->{folder};
    
    my $rs = $c->model('FADB::Feed')->search(
        {
            foldertitle => $c->session->{foldertitle},
        },
        {
            page  => $c->request->params->{page} || 1,
            rows  => 100,
            order_by => 'pubdate DESC',
        }
    );

    my $feedtitle_rs = $rs->search(
        undef,
        {
            columns  => ['feedtitle'],
            distinct => 1,
        },
    );

    $c->stash->{feeds} = [$rs->all];
    $c->stash->{pager} = $rs->pager;
    $c->stash->{feedtitles} = [$feedtitle_rs->all];
    $c->stash->{page_link} = "folder";
    $c->stash->{template} = 'list.tt2';
}

sub feed : Local {
    my ( $self, $c ) = @_;

    $c->forward('dates');
    $c->forward('folders');

    $c->session->{feedtitle} = $c->request->params->{feedtitle} if $c->request->params->{feedtitle};

    my $rs = $c->model('FADB::Feed')->search(
        {
            feedtitle => $c->session->{feedtitle},
        },
        {
            page  => $c->request->params->{page} || 1,
            rows  => 100,
            order_by => 'pubdate DESC',
        }
    );

    my $feedtitle_rs = $c->model('FADB::Feed')->search(
        {
            foldertitle => $c->session->{foldertitle},
        },
        {
            columns  => ['feedtitle'],
            distinct => 1,
        },
    );

    $c->stash->{feeds} = [$rs->all];
    $c->stash->{pager} = $rs->pager;
    $c->stash->{feedtitles} = [$feedtitle_rs->all];
    $c->stash->{page_link} = "feed";
    $c->stash->{template} = 'list.tt2';
}

sub dates : Private {
    my ( $self, $c ) = @_;

    my $date_rs = $c->model('FADB::Feed')->search(
        undef,
        {
            columns  => ['timestamp'],
            distinct => 1,
            order_by => 'timestamp DESC',
        },
    );
 
    my @date_results = $date_rs->all;
    $c->stash->{dates} = [@date_results];
}

sub folders : Private {
    my ( $self, $c ) = @_;

    my $folder_rs = $c->model('FADB::Feed')->search(
        undef,
        {
            columns  => ['foldertitle'],
            distinct => 1,
        },
    );

    my @folder_results = $folder_rs->all;
    $c->stash->{folders} = [@folder_results];
}

sub aggregation : Local {
    my ( $self, $c ) = @_;
    
    my $bloglines = WebService::Bloglines->new(
        username => 'blogreader01@gmail.com',
        password => 'stoplight',
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
                my $update = $bloglines->getitems($feed->{BloglinesSubId}, 1);
                for my $item ($update->items) {
                    $data{item_title} = encode('utf-8', $item->{title});
                    $data{item_creator} = encode('utf-8', $item->{dc}->{creator});
                    $data{item_link} = encode('utf-8', $item->{link});
                    $data{item_itemid} = encode('utf-8', $item->{bloglines}->{itemid});
                    $data{item_pubdate} = DateTime::Format::HTTP->parse_datetime(encode('utf-8', $item->{pubDate}));
                    $data{item_guid} = encode('utf-8', $item->{guid});
                    $data{timestamp} = $now;
                    $c->stash->{data} = {%data};
                    $c->forward('_insert');
                }
            };
            $c->forward('_aggregation_error') if $@;
        }
    }

    $c->detach('content');
}

sub _insert : Private {
    my ( $self, $c ) = @_;


    eval {
        $c->model('FADB::Feed')->create({
            foldertitle => $c->stash->{data}->{folder_title},
            feedtitle   => $c->stash->{data}->{feed_title},
            title       => $c->stash->{data}->{item_title} || 'nontitle',
            creator     => $c->stash->{data}->{item_creator} || 'unknown',
            link        => $c->stash->{data}->{item_link},
            itemid      => $c->stash->{data}->{item_itemid},
            pubdate     => $c->stash->{data}->{item_pubdate},
            guid        => $c->stash->{data}->{item_guid} || 'neneguid',
            timestamp   => $c->stash->{data}->{timestamp},
        });
    };
    $c->log->debug("Insert :" . $c->stash->{data}->{item_title}) if $@;
}

sub _aggregation_error : Private {
    my ( $self, $c ) = @_;
    $c->stash->{data}->{item_title} = "# Error #";
    $c->stash->{data}->{item_creator} = "# Error #";
    $c->stash->{data}->{item_link} = "# Error #";
    $c->stash->{data}->{item_itemid} = "# Error #";
    $c->stash->{data}->{item_pubdate} = "# Error #";
    $c->stash->{data}->{item_guid} = "# Error #";
    $c->forward('_insert');
}

=head1 AUTHOR

kaz,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
