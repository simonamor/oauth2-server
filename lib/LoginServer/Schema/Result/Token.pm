package LoginServer::Schema::Result::Token;
use parent 'DBIx::Class';

use Crypt::JWT;
use Crypt::OpenSSL::RSA;
use Time::ParseDate;

use strict;
use warnings;

# ABSTRACT: A table for registering bearer tokens

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('token');
__PACKAGE__->add_columns(
  id       => { data_type => 'int', is_auto_increment => 1 },
  code_id  => { data_type => 'int', is_nullable       => 0 },
);
__PACKAGE__->set_primary_key(qw(id));
__PACKAGE__->belongs_to( code => 'LoginServer::Schema::Result::Code' =>
    { 'foreign.id' => 'self.code_id' } );

# this is a has many but will only ever return a single record
# because of the constraint on the relationship table
__PACKAGE__->has_many(
  from_refresh_token_map =>
    'LoginServer::Schema::Result::RefreshTokenToAccessToken' => {
    'foreign.access_token_id' => 'self.id',
    'foreign.code_id'         => 'self.code_id'
    }
);
__PACKAGE__->many_to_many(
  from_refresh_token_map_m2m => from_refresh_token_map => 'refresh_token' );

# this is a has many but will only ever return a single record
# because of the constraint on the relationship table
__PACKAGE__->has_many(
  to_refresh_token_map =>
    'LoginServer::Schema::Result::AccessTokenToRefreshToken' => {
    'foreign.access_token_id' => 'self.id',
    'foreign.code_id'         => 'self.code_id'
    }
);
__PACKAGE__->many_to_many(
  to_refresh_token_map_m2m => to_refresh_token_map => 'refresh_token' );

sub from_refresh_token { shift->from_refresh_token_map_m2m->first }
sub to_refresh_token   { shift->to_refresh_token_map_m2m->first }

sub type       {'bearer'}
sub expires_in {1200}       # 20 minutes default
sub owner { shift->code->owner }

# This should be used to encode the id and other stuff into a JWT using Crypt::JWT
sub as_string {
    my $self = shift;
    my $user = $self->code->user;

    my $lpt = $user->last_password_change;
    my $llt = $user->last_login_time;

    # It doesn't have to be "secure" as long as it's obfuscated a bit
    # and doesn't give an easy indication as to what number a user is.

    my $hashids = $self->result_source->resultset->jwt_hashid();
    my $userid = $hashids->encode($user->id);

    my $payload = {
        user_id => $userid,
        lpt => $lpt,    # Last password change time for user
        llt => $llt,    # Last login time
        iat => time(),
        exp => time() + $self->expires_in,
        tid => $self->id,   # This is needed for the verification process
    };

    my $key = LoginServer->config->{ 'Store::DBIC_JWT' }{ private_key };

    my $rsa = Crypt::OpenSSL::RSA->new_private_key($key);
    my $pem = $rsa->get_private_key_string() . $rsa->get_public_key_string();
    # If the tid is removed from the payload, change the
    # verify_token method in CatalystX/OAuth2/Store/DBIC_JWT.pm
    my $token = Crypt::JWT::encode_jwt(
        payload         => $payload,
        alg             => 'RS512',
        key             => \$pem,
        extra_headers   => { "typ" => "JWT" },
    );
    return $token;
}

1;
