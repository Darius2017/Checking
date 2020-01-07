# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::NotificationAgentSessionLimit;

use strict;
use warnings;
use utf8;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::AuthSession',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    $Self->{LayoutObject} = $Param{LayoutObject} || die "Got no LayoutObject!";

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # Check if the agent session limit for the prior warning is reached
    #   and save the message for the translation and the output.
    my $AgentSessionLimitPriorWarningMessage
        = $Kernel::OM->Get('Kernel::System::AuthSession')->CheckAgentSessionLimitPriorWarning();

    return '' if !$AgentSessionLimitPriorWarningMessage;

    my $Output = $Self->{LayoutObject}->Notify(
        Data     => $Self->{LayoutObject}->{LanguageObject}->Translate($AgentSessionLimitPriorWarningMessage),
        Priority => 'Warning',
    );

    return $Output;
}

1;