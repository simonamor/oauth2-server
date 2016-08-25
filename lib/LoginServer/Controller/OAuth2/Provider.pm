package LoginServer::Controller::OAuth2::Provider;
use Moose;
BEGIN { extends 'Catalyst::Controller::ActionRole' }

with 'CatalystX::OAuth2::Controller::Role::Provider';

__PACKAGE__->config(
  store => {
    class => 'DBIC',
    client_model => 'DB::Client'
  }
);

sub base :Chained('/') PathPart('') CaptureArgs(0) {}

sub request : Chained('base') Args(0) Does('OAuth2::RequestAuth') {}

sub grant : Chained('base') Args(0) Does('OAuth2::GrantAuth') {
    my ( $self, $c ) = @_;

    my $oauth2 = $c->req->oauth2;

    $c->log->debug("Here at line " . __LINE__);

    $c->log->debug(
        "c->user_exists: " . ($c->user_exists ? 1 : 0) .
        " oauth2->user_is_valid: " . ($oauth2->user_is_valid(1) ? 1 : 0)
    );

    $c->user_exists and $oauth2->user_is_valid(1)
        or $c->detach('/login');

    $c->log->debug("Here at line " . __LINE__);

    # If the user is logged in and valid, approve the granting of permissions
    # since we're using it for centralised login rather than granting privs
    # to a third-party.
    $oauth2->approved(1);
}

sub token : Chained('base') Args(0) Does('OAuth2::AuthToken::ViaAuthGrant') {}

sub refresh : Chained('base') Args(0) Does('OAuth2::AuthToken::ViaRefreshToken') {}

1;
