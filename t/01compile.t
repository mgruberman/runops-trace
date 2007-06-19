#!perl

use Test::More tests => 4;

use_ok('Runops::Trace');
pass('and it continues to work');
eval  { pass('... in eval {}') };
eval q{ pass('... in eval STRING') };
