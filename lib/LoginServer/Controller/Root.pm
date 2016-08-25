package LoginServer::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

LoginServer::Controller::Root - Root Controller for LoginServer

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body("Index");
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub login :Path('/login') :Args(0) {
    my ($self, $c) = @_;
    $c->log->debug("passthrulogin @ line " . __LINE__);

    # Get the email and password from form
    my $username = $c->request->params->{ username };
    my $password = $c->request->params->{ password };

    # If the sage_id, username and password values were found in form
    if ($username && $password) {
        # Attempt to log the user in
        if ($c->authenticate({ username => $username,
                               password => $password  } )) {

            # Prevents Session Fixation exploit.
            # Changes session id without losing data.
            $c->change_session_id;

            # If successful, then let them use the application
            $c->log->debug("Successful login");
            # This somehow ends up back at /grant which generates the
            # appropriate redirect
            $c->detach();

        } else {
            $c->log->debug("Failed to login");
            # Set an error message
            $c->session( error_msg => "Bad username or password.");
        }
    }

    # If either of above don't work out, send to the login page
    $c->stash(
        template => 'login.html',
    );
}

=head2 /logout

=cut

sub logout :Path('/logout') :Args(0) {
    my ( $self, $c ) = @_;

    # Clear the user's state
    $c->logout;

    # Send the user to the starting point
    $c->response->redirect($c->uri_for('/'));
}

sub end : ActionClass('RenderView') { }

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
