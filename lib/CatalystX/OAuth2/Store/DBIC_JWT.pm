package CatalystX::OAuth2::Store::DBIC_JWT;
use Moose;
use Crypt::JWT;

use strict;
use warnings;

extends 'CatalystX::OAuth2::Store::DBIC';

sub verify_client_token {
    my ( $self, $access_token ) = @_;
    my $rs = $self->_client_model;
    return 0 unless defined $access_token;

    # decode the JWT to get the token id
    my $public = Crypt::OpenSSL::RSA->new_public_key(
        LoginServer->config->{ 'Store::DBIC_JWT' }{ public_key }
    );

    my $jwt = eval {
        Crypt::JWT::decode_jwt(
            token   => $access_token,
            key     => $public,
        );
    };

    my $token_id = 0;
    if ($jwt && (ref($jwt) eq 'HASH')) {
        $token_id = $jwt->{ tid };
    }
    # Failed to extract the token id or the JWT wasn't valid?
    if (! $token_id) {
        return 0;
    }

    my $token_rs = $rs->related_resultset( $self->code_relation )
        ->related_resultset( $self->token_relation );
    if(my $token = $token_rs->find($token_id)) {
        return $token;
    }
    return 0;
}

1;
