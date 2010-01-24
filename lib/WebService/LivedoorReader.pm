package WebService::LivedoorReader;
use strict;

use JSON::Syck;
use URI;
use WWW::Mechanize;
use Data::Dumper;

sub new {
    my $class = shift;
    my ($username, $password, $mark_read) = @_;

    my $self = bless {
	username => $username,
	password => $password,
	mark_read => $mark_read || 0,
    }, $class;
    $self->init_reader;
    return $self;
}

sub init_reader {
    my $self = shift;
    $self->{mech} = WWW::Mechanize->new(cookie_jar => {});
}

sub notifier {
    my($self, $context) = @_;

    $self->{mech}->get(
	"http://rpc.reader.livedoor.com/notify?user=" . $self->{username});
    my $content = $self->{mech}->content;

    # copied from WebService/Bloglines.pm

    # |A|B| where A is the number of unread items
    $content =~ /\|([\-\d]+)|(.*)|/
	or $context->error("Bad Response: $content");

    my($unread, $url) = ($1, $2);

    # A is -1 if the user email address is wrong.
    if ($unread == -1) {
	die("Bad username: " . $self->{username});
    }

    return unless $unread;

    $self->sync(@_);
}

sub sync {
    my($self, $context, $args) = @_;

    $self->login_reader();
    $self->_request("/api/subs", { unread => 1 }) || [];
}

sub get_unreads {
    my $self = shift;
    my $subscribe_id = shift;
    $self->_request(
	"/api/unread", { subscribe_id => $subscribe_id });
}

sub mark_readed {
    my $self = shift;
    my ($subscribe_id) = @_;
    $self->_request("/api/touch_all", { subscribe_id => $subscribe_id })
	if $self->{mark_read};
}

sub login_reader {
    my $self = shift;

    local $^W; # input type="search" warning
    $self->{mech}->get("http://reader.livedoor.com/reader/");

    if ($self->{mech}->content =~ /name="loginForm"/) {
        $self->{mech}->submit_form(
            form_name => 'loginForm',
            fields => {
                livedoor_id => $self->{username},
                password    => $self->{password},
            },
        );

        if ( $self->{mech}->content =~ /class="headcopy"/ ) {
            die("Failed to login using username & password");
        }
    }

    $self->{mech}->cookie_jar->scan(
        sub {
            my($key, $val) = @_[1,2];
            if ($key =~ /_sid/) {
                $self->{apikey} = $val;
                return;
            }
        },
    );
}

sub _request {
    my($self, $method, $param) = @_;

    my $uri = URI->new_abs($method, "http://reader.livedoor.com/");
    $self->{mech}->post($uri, { %$param, ApiKey => $self->{apikey} });

    if ($self->{mech}->status == 200) {
        return JSON::Syck::Load($self->{mech}->content);
    }

    return;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::LivedoorReader - Synchronize livedoor Reader with JSON API

=head1 SYNOPSIS

  - module: Subscription::LivedoorReader
    config:
      username: your-livedoor-id
      password: your-password
      mark_read: 1

=head1 DESCRIPTION

This plugin allows you to synchronize your subscription using Livedoor
Reader JSON API.

=head1 CONFIGURATION

=over 4

=item username, password

Your username & password to use with livedoor Reader.

Note that you don't have to supply username and password if you set
global cookie_jar in your configuration file and the cookie_jar
contains a valid login session there, such as:

  global:
    user_agent:
      cookies: /path/to/cookies.txt

See L<Plagger::Cookies> for details.

=item mark_read

C<mark_read> specifies whether this plugin I<marks as read> the items
you synchronize. With this option set to 0, you will get the
duplicated updates every time you run Plagger, until you mark them
unread using Livedoor Reader web interface.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Subscription::Bloglines>, L<http://reader.livedoor.com/>

=cut

