use strict;
use warnings;

use LoginServer;

my $app = LoginServer->apply_default_middlewares(LoginServer->psgi_app);
$app;

