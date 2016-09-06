package LoginServer::Schema::Result::Code;
use parent 'DBIx::Class';

# ABSTRACT: A table for registering grant codes

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('code');
__PACKAGE__->add_columns(
  client_id => { data_type => 'int', is_nullable => 0 },
  id => { data_type => 'int', is_auto_increment => 1, is_nullable => 0 },
  is_active => { data_type => 'int', is_nullable => 0, default_value => 0 },
  owner_id => { data_type => 'int', is_nullable => 1 },
    user_id => { data_type => 'int', is_nullable => 1 }
);
__PACKAGE__->set_primary_key(qw(id));
__PACKAGE__->belongs_to(
  client => 'LoginServer::Schema::Result::Client' =>
    { 'foreign.id' => 'self.client_id' } );
__PACKAGE__->has_many( tokens => 'LoginServer::Schema::Result::Token' =>
    { 'foreign.code_id' => 'self.id' } );
__PACKAGE__->has_many(
  refresh_tokens => 'LoginServer::Schema::Result::RefreshToken' =>
    { 'foreign.code_id' => 'self.id' } );
__PACKAGE__->belongs_to(
  owner => 'LoginServer::Schema::Result::Owner',
  { 'foreign.id' => 'self.owner_id' }
);
__PACKAGE__->belongs_to(
    user => 'LoginServer::Schema::Result::User',
        { 'foreign.id' => 'self.user_id' }
);

sub as_string { shift->id }

sub activate {
  my($self, $owner_id) = @_;
  $self->update( { is_active => 1, owner_id => $owner_id } )
}

1;
