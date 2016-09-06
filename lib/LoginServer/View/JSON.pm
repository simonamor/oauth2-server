package LoginServer::View::JSON;
use base qw(Catalyst::View::JSON);

__PACKAGE__->config(
    allow_callback => 0,   # defaults to 0 anyway
    expose_stash => 'json',
);

=head1 NAME

LoginServer::View::JSON - JSON View for LoginServer

=head1 DESCRIPTION

JSON View for LoginServer

=head1 SEE ALSO

L<LoginServer>

=cut

1;
