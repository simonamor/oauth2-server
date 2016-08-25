package LoginServer::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    # TEMPLATE_EXTENSION => '.tt',
    render_die => 1,

    INCLUDE_PATH => [
        LoginServer->path_to( 'templates', 'webapp' ),   # Look here first
        LoginServer->path_to( 'templates', 'library' ),
    ],
    # Set to 1 for detailed timer stats in your HTML as comments
    TIMER => 0,
    # This is your wrapper template located in templates/library
    WRAPPER => "wrapper",
);

=head1 NAME

LoginServer::View::HTML - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=encoding utf8

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
