package LoginServer::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole' }

with 'CatalystX::OAuth2::Controller::Role::WithStore';

__PACKAGE__->config(
    store => {
        class => 'DBIC_JWT',
        client_model => 'DB::Client'
    }
);

sub api_base :Chained('/') :PathPart('api') :CaptureArgs(0) :Does('OAuth2::ProtectedResource') {
    my ($self, $c) = @_;

    # Setup the user etc
    if (! $c->user_exists) {
        # Re-authenticate user based on the id in the token which has
        # already been verified (JWT user_id = token.code.user_id)
        my $user_id = eval { $c->req->oauth2->token->code->user_id };
        $user_id ||= 0;
        $c->log->debug("User id " . $user_id);
        my $user = $c->find_user({ id => $user_id });
        unless ($user) {
            $c->log->debug("user not found for id $user_id");
            $c->res->status(404);
            $c->res->body("Not found");
            $c->detach();
        }
        $c->set_authenticated($user);
        $c->log->debug("user found and set " . $c->user->id);
    } else {
        $c->log->debug("user already exists " . $c->user->id);
    }
}

sub profile :Chained('api_base') :PathPart('profile') :Args(0) {
    my ($self, $c) = @_;

    my $time = scalar(localtime(time()));
    $c->response->header("Content-Type", "application/json");
    $c->stash( json => {
        user_id => $c->user->id,
        timestamp => $time,
        map {
            $_ => $c->user->$_
        } qw/first_name last_name email_address username
             last_password_change last_login_time/
    });
    $c->detach('View::JSON');
}

sub access :Chained('api_base') :PathPart('access') :Args(0) {
    my ($self, $c) = @_;

    # FIXME: Needs finishing

    $c->response->header("Content-Type", "application/json");
    $c->stash( json => { content => "list of sites token user is allowed to access" } );
    $c->detach('View::JSON');
}

=head2 /api/refresh

If the JWT is verified (via api_base), issue a new JWT for the
current token in the normal manner.

=cut

sub refresh :Chained('api_base') :PathPart('refresh') :Args(0) {
    my ($self, $c) = @_;

    my $jwt = $c->req->oauth2->token->as_string;

    $c->response->header("Content-Type", "application/json");
    $c->stash( json => { jwt => $jwt } );
    $c->detach('View::JSON');
}

=head2 /api/revoke

Even though you can't technically revoke a JWT, we can at least
dissociate the token id from a useful database record by deleting
the entry from the table.

=cut

sub revoke :Chained('api_base') :PathPart('revoke') :Args(0) {
    my ($self, $c) = @_;

    # FIXME: Needs finishing

    $c->response->header("Content-Type", "application/json");
    $c->stash( json => { result => "ok", content => "revoke jwt by deleting token from db" } );
    $c->detach('View::JSON');
}

# __PACKAGE__->meta->make_immutable;

1;
