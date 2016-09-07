package LoginServer::Schema::ResultSet::Token;
use parent 'DBIx::Class::ResultSet';

use Hashids;

=head2 jwt_to_token( jwt )

Takes a JWT (from the authorization header for example) and
assuming it validates, returns the Result::Token associated
with the JWT.

  $token = $schema->resultset('Token')->jwt_to_token($jwt)

=cut

sub jwt_to_token {
    my $self = shift;
    my $token = shift || return undef;

    my $payload = $self->jwt_payload($token);
    unless ($payload && $payload->{ tid }) {
        return undef;
    }
    return $self->find($payload->{ tid });
}

=head2 jwt_payload( jwt )

Takes a JWT and returns a payload hashref. If the JWT signature
is invalid, returns undef.

=cut

sub jwt_payload {
    my $self = shift;
    my $token = shift || return undef;

    # decode the JWT to get the token id
    my $public = Crypt::OpenSSL::RSA->new_public_key(
        LoginServer->config->{ 'Store::DBIC_JWT' }{ public_key }
    );

    my $jwt = eval {
        Crypt::JWT::decode_jwt(
            token   => $token,
            key     => $public,
        );
    };

    my $token_id = 0;
    if ($jwt && (ref($jwt) eq 'HASH')) {
        return $jwt;
    }
    return undef;
}

=head2 jwt_hashid()

Returns a Hashids object preconfigured with the alphabet, salt, etc

=cut

sub jwt_hashid {
    my $self = shift;

    return Hashids->new(
        salt => LoginServer->config->{ 'Store::DBIC_JWT' }{ hashid_salt },
        minHashLength => 15,
        alphabet => join('', reverse('A'..'Z'), reverse('a'..'z'), reverse(0..9)),
    );
}

sub find_refresh {
  shift->related_resultset('codes')->search( { is_active => 1 } )
    ->related_resultset('refresh_tokens')->find(@_);
}

1;
