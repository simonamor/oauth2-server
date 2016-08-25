use utf8;
package LoginServer::Schema::Result::User;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("PassphraseColumn");

__PACKAGE__->table("users");

__PACKAGE__->add_columns(
  "id",             {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "password",       { data_type => "text", is_nullable => 1 },
  "email_address",  { data_type => "text", is_nullable => 1 },
  "first_name",     { data_type => "text", is_nullable => 1 },
  "last_name",      { data_type => "text", is_nullable => 1 },
  "active",         { data_type => "integer", is_nullable => 1 },
  "username",       { data_type => "char", is_nullable => 0, size => 32 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("username", ["username"]);

__PACKAGE__->add_columns(
    'password' => {
        passphrase          => 'rfc2307',
        passphrase_class    => 'SaltedDigest',
        passphrase_args     => {
            algorithm => 'SHA-1',
            salt_random => 20,
        },
        passphrase_check_method => 'check_password',
    },
);

__PACKAGE__->meta->make_immutable;
1;
