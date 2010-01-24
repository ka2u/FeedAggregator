package FeedAggregator::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

FeedAggregator::Controller::Root - Root Controller for FeedAggregator

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

sub auto : Private {
    my ($self, $c) = @_;

    my ($user, $pass) = $c->request->headers->authorization_basic;
    if ( !($user eq 'basicauth' && $pass eq 'basicauth') ) {
        $c->response->status(401);
        $c->response->headers->header('WWW-Authenticate' => 'Basic realm="Please enter id and pass"');
        $c->stash->{template} = '401.tt2'; 
        return 0;
    }

    if ($c->controller eq $c->controller('Auth')) {
        return 1;
    }

    if (!$c->user_exists) {
        $c->log->debug("user not found. forwarding to login");
        $c->response->redirect($c->uri_for('/auth/login'));
        return 0;
    }

    return 1;
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

kaz,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
