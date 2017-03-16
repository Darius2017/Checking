#!/usr/bin/perl
# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';

use Kernel::System::ObjectManager;

use Getopt::Long;

local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OTRS-DBUpdate-to-6.pl',
    },
);

# get options
my %Opts = (
    Help           => 0,
    NonInteractive => 0,
);
Getopt::Long::GetOptions(
    'help',            \$Opts{Help},
    'non-interactive', \$Opts{NonInteractive},
);

{
    if ( $Opts{Help} ) {
        print <<"EOF";

DBUpdate-to-6.pl - Upgrade script for OTRS 5 to 6 migration.
Copyright (C) 2001-2017 OTRS AG, http://otrs.com/

Usage: $0
    Options are as follows:
        --help              display this help
        --non-interactive   skip interactive input and display steps to execute after script has been executed

EOF
        exit 1;
    }

    # UID check
    if ( $> == 0 ) {    # $EFFECTIVE_USER_ID
        die "
Cannot run this program as root.
Please run it as the 'otrs' user or with the help of su:
    su -c \"$0\" -s /bin/bash otrs
";
    }

    my $DBUpdateTo6Object = $Kernel::OM->Create(
        'scripts::DBUpdateTo6',
        ObjectParams => {
            Opts => \%Opts,
        },
    );

    # Run DB update.
    $DBUpdateTo6Object->Run();

    exit 0;
}

1;
