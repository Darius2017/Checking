#!/usr/bin/perl
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';
use lib dirname($RealBin) . '/Custom';

use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Log;
use Kernel::System::DB;
use Kernel::System::Type;
use Kernel::System::Main;

my %CommonObject;

# create common objects
$CommonObject{ConfigObject} = Kernel::Config->new();
$CommonObject{EncodeObject} = Kernel::System::Encode->new(%CommonObject);
$CommonObject{LogObject}    = Kernel::System::Log->new( %CommonObject, LogPrefix => 'OTRS-otrs.TicketType' );
$CommonObject{MainObject}   = Kernel::System::Main->new(%CommonObject);
$CommonObject{DBObject}     = Kernel::System::DB->new(%CommonObject);
$CommonObject{TypeObject}   = Kernel::System::Type->new(%CommonObject);

my %Param;
my %Options;

use Getopt::Std;
getopts( 'n:h', \%Options );

if ( $Options{h} ) {
    print STDERR "Usage: $FindBin::Script -n <Type>\n";
    exit;
}

if ( !$Options{n} ) {
    print STDERR "ERROR: Need -n <Type>\n";
    exit 1;
}

# user id of the person adding the record
$Param{UserID} = '1';

# Validrecord
$Param{ValidID} = '1';
$Param{Name}    = $Options{n} || '';

if ( my $RID = $CommonObject{TypeObject}->TypeAdd(%Param) ) {
    print "Ticket type '$Options{n}' added. Type id is '$RID'\n";
}
else {
    print STDERR "ERROR: Can't add type\n";
}

exit(0);