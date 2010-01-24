package FeedAggregator::Controller::Auth;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

FeedAggregator::Controller::Auth - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched FeedAggregator::Controller::Auth in Auth.');
}

sub login : Local {
    my ( $self, $c ) = @_;

    my $user_id = $c->request->params->{user_id} || '';
    my $passwd = $c->request->params->{passwd} || '';

    if ($user_id && $passwd) {
        if ($c->login($user_id, $passwd)) {
            if ($c->req->params->{mobile}) {
                $c->response->redirect($c->uri_for('/list/mobile'));
            }
            else {
                $c->response->redirect($c->uri_for('/list/content'));
            }
            return;
        }
        else {
            $c->stash->{error_msg} = "Bad user_id or password";
        }
    }

    $c->stash->{template} = 'top.tt2';
}

sub logout : Local {
    my ( $self, $c ) = @_;

    $c->logout;

    $c->response->redirect($c->uri_for('/'));
}


=head1 AUTHOR

kaz,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
