package FeedAggregator::Model::FADB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'FADB',
    connect_info => [
        'dbi:mysql:feedaggregator',
        'mysqlID',
        'mysqlPassword',
        {
            mysql_enable_utf8 => 1,
        },
    ],
);

=head1 NAME

FeedAggregator::Model::FADB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<FeedAggregator>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<FADB>

=head1 AUTHOR

kaz,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
