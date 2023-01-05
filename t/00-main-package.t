use v5.10;
use strict;
use warnings;

use Test::More;

# App::ProdHandler should have no code, but still - verify whether it is
# required ok
use_ok 'App::ProdHandler';

done_testing;

