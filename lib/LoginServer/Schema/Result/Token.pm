package LoginServer::Schema::Result::Token;
use parent 'DBIx::Class';

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

sub as_string  { shift->id }
sub type       {'bearer'}
sub expires_in {3600}
sub owner { shift->code->owner }

1;
