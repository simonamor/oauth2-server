package LoginServer::Controller::OAuth2::Provider;
use Moose;
BEGIN { extends 'Catalyst::Controller::ActionRole' }

with 'CatalystX::OAuth2::Controller::Role::Provider';

__PACKAGE__->config(
  store => {
    class => 'DBIC_JWT',
    client_model => 'DB::Client'
  }
);

sub base :Chained('/') PathPart('') CaptureArgs(0) {}

sub request : Chained('base') Args(0) Does('OAuth2::RequestAuth') {}

sub grant : Chained('base') Args(0) Does('OAuth2::GrantAuth') {
    my ( $self, $c ) = @_;

    my $oauth2 = $c->req->oauth2; #ref() CatalystX::OAuth2::Request::GrantAuth

    $c->log->debug("Here in file " . __FILE__ . " at line " . __LINE__);

    if ($c->req->params->{ username } && $c->req->params->{ password }) {
        if ($c->authenticate({
            username => $c->req->params->{ username },
            password => $c->req->params->{ password },
            active   => 1, })) {

            $c->log->debug("Successful login");

            $c->user->update({ last_login_time => time() });
        } else {
            $c->detach('login');
        }
    }

    # user_is_valid attribute must be 1 to continue flow
    $c->user_exists and $oauth2->user_is_valid(1)
        or $c->detach('login');

    $c->log->debug("Here in file " . __FILE__ . " at line " . __LINE__);

    # If the user is logged in and valid, approve the granting of permissions
    # since we're using it for centralised login rather than granting privs
    # to a third-party.
    $oauth2->approved(1);

    # We needed to record which user authenticated against
    # the code so that when a protected resource is requested
    # with a token, we can link the token back to a particular
    # authenticated user.

    # The user id is also included within the JWT payload.

    my $code = $oauth2->store->find_client_code($oauth2->code);
    $code->update({ user_id => $c->user->id });
}

sub token : Chained('base') Args(0) Does('OAuth2::AuthToken::ViaAuthGrant') {}

sub refresh : Chained('base') Args(0) Does('OAuth2::AuthToken::ViaRefreshToken') {}

sub login : Chained('base') Args(0) {
    my ($self,$c) = @_;

    # Get the email and password from form
    my $username = $c->req->params->{ username };
    my $password = $c->req->params->{ password };

    # If the username and password values were found in form
    if ($username && $password) {
        $c->log->debug("Failed to login");
        # Set an error message to be included on the login page
        $c->stash( error_msg => "Bad username or password." );
    }

    $c->stash( cancel_uri => $c->req->params->{ redirect_uri } );

    # If the above params aren't present, display the login page
    $c->stash( template => 'login.html' );
}

1;
