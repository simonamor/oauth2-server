package LoginServer;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use CatalystX::RoleApplicator;

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple

    Authentication
    Authorization::Roles

    Session

    Session::Store::DBI
    Session::State::Cookie
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in loginserver.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->apply_request_class_roles(qw/
    Catalyst::TraitFor::Request::ProxyBase
/);

__PACKAGE__->config(
    name => 'LoginServer',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 0, # Send X-Catalyst header

    using_frontend_proxy => 1,

    default_view => 'HTML',
);


# Configure simple authentication
__PACKAGE__->config(
    'Plugin::Authentication' => {
        default => {
            credential => {
                class           => 'Password',
                password_type   => 'self_check',
            },
            store => {
                class           => 'DBIx::Class',
                user_model      => 'DB::User',
                role_relation   => 'roles',
                role_field      => 'role',
                use_userdata_from_session => '0',  # Don't cache user data in session
            },
        },
    },
);

# Or use an existing database handle from a DBIC/CDBI class
__PACKAGE__->config(
    'Plugin::Session' => {
        dbi_dbh   => 'DB', # which means LoginServer::Model::DB
        dbi_table => 'sessions',
        dbi_id_field => 'id',
        dbi_data_field => 'session_data',
        dbi_expires_field => 'expires',

        expires   => 900,   # 15 minutes (in seconds)

        # If nothing in the session changed, only refresh the expiry
        # time if it's got less than 10 minutes until it expires
        expiry_threshold => 600,
    },
);

__PACKAGE__->config(
    'Store::DBIC_JWT' => {
        private_key => '-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAui6/qJ658qPgmnGZSOPHnbDd352o+w2d94BahhWS7TRRWsFn
eo3AnA3Sh+hJPRw4zFc+DApFTB3C4NJrwZaBBYG+FGvOSD5eOQZ48dk2d1A2PUI0
5yaK4AXTtijDtWbwql2KCSST2yDEFK88XsMQV2YmMUMypvhoYoq+3skhrv7p6IiT
JOCa/80ZZQfx+f9xI+NK3pX2vidfX8gi2XhDwEcyDnroS5GzfAtDjVz9JU6weRGu
hiD74RZkQDbJ3T8XDhISZf4t2Z8HHK0yZ6tjs73vfAZGfauo5Wl5tjn5/1ijcaoc
X+566PHNEayN04pDdC8xdfUvkfgZc4K2pP7StwIDAQABAoIBAAyX9uzf97H69clc
n8K3bZw0B34FuxVoQWQpcXYaZXrYDBy4clhu2DV2FeSNiM6yZwEjcZX8590TMkhk
01cf6BBIS2Q0OprWZSc0UeACElYVveV84fk0uTYYDs8GiN5vXR4Y/6pIqButZrYD
eHDsfuF6jmDMq9NxgBYSToDhV/7vL4rVTGxiME6X3GYKWkzGr/rFK2ecVoyjRYwG
oFVia4QBKE4EYBGlnJXyk5qZryM9EuQVpK56a+NW7G3CHL7ed8FHYHpuPKCB4UcA
FxXS/vT8S46tPceuFLBvzzBInTExHr3qjIhOemvOE0DYd9UHYb9eEpL3o6VWp4ks
zlR5xXkCgYEA85vdhkLP8MRBLU2u8gsyXrfbJ23r0kSyDwp1DJHlly+hlY4Nfuig
vyNOoYN7gnAN7PuDpJgpdCM/BYTflEh+XdAMujv2TiOjzHWBJZajtdj6ndJD6YTQ
SiOgkZpPhO3m9rPjr1AdlpFwDLM8277J6GD4DxiKoAByjCkSaPjitH0CgYEAw6cc
oJCapP10/xih6qyBm8ec1MyOwqZIFf1ryGA+8bk0lEqQ+tqsOFehV/6aZ+LrhOG3
zfq5Mr/QzNG3RifxI4O3SDyVpMOjdqksC40OGhOhgTEiQeR6ywGCtLUTqZKq6FX7
4BsExBoIl180AIho4R/QojfeBdbNg5lNvZKxzkMCgYAqiAHrGOsZDAqdED0FATNw
GgVnIufTNC8qNRcudKJy/NvnMn/kslSuSknGJSCBK3Mi9t6K9A34utab7hDi4K0/
T72JHkLobYyBe9pqZ5x5eUJ4H2e/83IyH3o/MYPEn4x9cfbEeuZPjWDUts5fRzYV
Hijw6cX6HVniYqFWNm3OOQKBgD3HiNySjKJIficGyinl6s8bysPPC80e4GhBK0WM
TpPZXWbt3LW5UuQ/l2zHsk3Xc3L0KyvZXZ1OwEnMdsiqWBRUxQ0ERGRQek8/v+6t
zaQiSr8WmrCfyr5LbdBN1TWYYGsYq33qSij553iU0UDR0fw0JZbzeSHy39YMFGYl
6gstAoGBAJfnAt5YFOgumM2i1qptvzh0mVpVm2wl3r6KSqZpr7D4damL418CtFlh
j2r9FiOtVYe72bajz+85Z/KfJPCZI6lpdjwDWUecc3AqUf74ULKXlAVYuWzr/m1B
8C+enr4DuMHqstWbjfKKCAUhdbb2bLTglOraQedoTQ/HxQ9kIITS
-----END RSA PRIVATE KEY-----',
        public_key => '-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAui6/qJ658qPgmnGZSOPH
nbDd352o+w2d94BahhWS7TRRWsFneo3AnA3Sh+hJPRw4zFc+DApFTB3C4NJrwZaB
BYG+FGvOSD5eOQZ48dk2d1A2PUI05yaK4AXTtijDtWbwql2KCSST2yDEFK88XsMQ
V2YmMUMypvhoYoq+3skhrv7p6IiTJOCa/80ZZQfx+f9xI+NK3pX2vidfX8gi2XhD
wEcyDnroS5GzfAtDjVz9JU6weRGuhiD74RZkQDbJ3T8XDhISZf4t2Z8HHK0yZ6tj
s73vfAZGfauo5Wl5tjn5/1ijcaocX+566PHNEayN04pDdC8xdfUvkfgZc4K2pP7S
twIDAQAB
-----END PUBLIC KEY-----',
    }
);

# Start the application
__PACKAGE__->setup();

=encoding utf8

=head1 NAME

LoginServer - Catalyst based application

=head1 SYNOPSIS

    script/loginserver_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<LoginServer::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
