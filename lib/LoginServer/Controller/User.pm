package LoginServer::Controller::User;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole' }

with 'CatalystX::OAuth2::Controller::Role::WithStore';

__PACKAGE__->config(
    store => {
        class => 'DBIC',
        client_model => 'DB::Client'
    }
);

sub user :Path('/user') :Args(0) Does('OAuth2::ProtectedResource') {
    my ($self, $c) = @_;

    $c->response->header("Content-Type", "application/json");
    $c->response->body('{"username":"someone"}');
}

# __PACKAGE__->meta->make_immutable;

1;
