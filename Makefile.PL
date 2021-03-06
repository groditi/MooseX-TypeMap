
use strict;
use inc::Module::Install;

name 'MooseX-TypeMap';
license 'perl';
all_from 'lib/MooseX/TypeMap.pm';

# prereqs
requires 'Moose';
requires 'MooseX::Types' => '0.19';

# things the tests need
test_requires 'Test::More' => '0.62';

resources 'IRC' => 'irc://irc.perl.org/#moose';
resources 'license' => 'http://dev.perl.org/licenses/';
resources 'repository' => 'git://github.com/groditi/MooseX-TypeMap.git';

WriteAll;
