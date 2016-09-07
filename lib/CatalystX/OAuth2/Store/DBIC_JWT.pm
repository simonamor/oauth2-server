package CatalystX::OAuth2::Store::DBIC_JWT;
use Moose;

use strict;
use warnings;

extends 'CatalystX::OAuth2::Store::DBIC';

sub verify_client_token {
    my ( $self, $access_token ) = @_;
    my $rs = $self->_client_model;
    return 0 unless defined $access_token;

    my $token_rs = $rs->related_resultset( $self->code_relation )
        ->related_resultset( $self->token_relation );

    my $jwt = $token_rs->jwt_payload($access_token);

    # Failed to extract payload, JWT wasn't valid, or token id not present?
    unless ($jwt && (ref($jwt) eq 'HASH') && ($jwt->{ tid })) {
        return 0;
    }

    my $hashids = $token_rs->jwt_hashid();
    my $user_id = $hashids->decode($jwt->{ user_id });

    if(my $token = $token_rs->find($jwt->{ tid })) {
        # Validation! Should be the same user id
        if ($token->code->user_id != $user_id) {
            return 0;   # User id for code doesn't match user id in JWT
        }
        my $user = $token->code->user;
        if (! $user) {
            return 0;   # User doesn't exist in db (deleted?)
        }
        if ((exists $jwt->{ lpt }) &&
            ($jwt->{ lpt } < $user->last_password_change)) {
            return 0;   # User has changed password since token issued
        }
        return $token;
    }
    return 0;
}

1;
