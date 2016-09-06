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

    use Data::Dumper;
    $c->log->debug("c->user: " . Dumper($c->user));
    $c->log->debug("c->auth bearer: " . Dumper($c->req->header('Authorization')));
    # Setup the user etc
}

sub profile :Chained('api_base') :PathPart('profile') :Args(0) {
    my ($self, $c) = @_;

    my $time = scalar(localtime(time()));
    $c->response->header("Content-Type", "application/json");
    $c->response->body(sprintf '{"username":"someone","timestamp":"%s"}', $time);
}

sub access :Chained('api_base') :PathPart('access') :Args(0) {
    my ($self, $c) = @_;

    $c->response->header("Content-Type", "application/json");
    $c->response->body('{"content":"list of sites token user is allowed to access"}');
}

sub refresh :Chained('api_base') :PathPart('refresh') :Args(0) {
    my ($self, $c) = @_;

    $c->response->header("Content-Type", "application/json");
    $c->response->body('{"content":"refreshed jwt with same token id but different expiry"}');
}

sub revoke :Chained('api_base') :PathPart('revoke') :Args(0) {
    my ($self, $c) = @_;

    $c->response->header("Content-Type", "application/json");
    $c->response->body('{"content":"revoke jwt by deleting token from db"}');
}

# __PACKAGE__->meta->make_immutable;

1;
