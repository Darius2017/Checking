# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OTRS::SchedulerRunning;

use strict;
use warnings;

use base qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::System::PID;

sub GetDisplayPath {
    return 'OTRS';
}

sub Run {
    my $Self = shift;

    my $PIDObject = Kernel::System::PID->new( %{$Self} );

    # try to get scheduler PID
    my %PID = $PIDObject->PIDGet(
        Name => 'otrs.Scheduler',
    );

    my $PIDUpdateTime = $Self->{ConfigObject}->Get('Scheduler::PIDUpdateTime') || 600;

    # check if scheduler process is registered in the DB and if the update was not too long ago
    if ( !%PID || ( time() - $PID{Changed} > 4 * $PIDUpdateTime ) ) {

        $Self->AddResultProblem(
            Label   => 'Scheduler',
            Value   => 0,
            Message => 'Scheduler is not running.',
        );
    }
    else {
        $Self->AddResultOk(
            Label   => 'Scheduler',
            Value   => 1,
            Message => 'Scheduler is running.',
        );
    }

    return $Self->GetResults();
}

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut

1;