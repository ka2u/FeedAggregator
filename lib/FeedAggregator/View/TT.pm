package FeedAggregator::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    CATALYST_VAR => 'Catalyst',
    INCLUDE_PATH => [
        FeedAggregator->path_to( 'root', 'src' ),
        FeedAggregator->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0
});

=head1 NAME

FeedAggregator::View::TT - Catalyst TTSite View

=head1 SYNOPSIS

See L<FeedAggregator>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

kaz,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

