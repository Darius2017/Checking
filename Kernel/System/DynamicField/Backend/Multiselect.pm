# --
# Kernel/System/DynamicField/Backend/Multiselect.pm - Delegate for DynamicField Multiselect backend
# Copyright (C) 2001-2011 OTRS AG, http://otrs.org/
# --
# $Id: Multiselect.pm,v 1.27 2011-10-28 17:54:04 cg Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::Backend::Multiselect;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::System::DynamicFieldValue;
use Kernel::System::DynamicField::Backend::BackendCommon;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.27 $) [1];

=head1 NAME

Kernel::System::DynamicField::Backend::Multiselect

=head1 SYNOPSIS

DynamicFields Multiselect backend delegate

=head1 PUBLIC INTERFACE

This module implements the public interface of L<Kernel::System::DynamicField::Backend>.
Please look there for a detailed reference of the functions.

=over 4

=item new()

usually, you want to create an instance of this
by using Kernel::System::DynamicField::Backend->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Needed (qw(ConfigObject EncodeObject LogObject MainObject DBObject)) {
        die "Got no $Needed!" if !$Param{$Needed};

        $Self->{$Needed} = $Param{$Needed};
    }

    # create additional objects
    $Self->{DynamicFieldValueObject} = Kernel::System::DynamicFieldValue->new( %{$Self} );
    $Self->{BackendCommonObject}
        = Kernel::System::DynamicField::Backend::BackendCommon->new( %{$Self} );

    return $Self;
}

sub ValueGet {
    my ( $Self, %Param ) = @_;

    my $DFValue = $Self->{DynamicFieldValueObject}->ValueGet(
        FieldID  => $Param{DynamicFieldConfig}->{ID},
        ObjectID => $Param{ObjectID},
    );

    return if !$DFValue;
    return if !IsArrayRefWithData($DFValue);
    return if !IsHashRefWithData( $DFValue->[0] );

    # extract real values
    my @ReturnData;
    for my $Item ( @{$DFValue} ) {
        push @ReturnData, $Item->{ValueText}
    }

    return \@ReturnData;
}

sub ValueSet {
    my ( $Self, %Param ) = @_;

    # check for valid possible values list
    if ( !$Param{DynamicFieldConfig}->{Config}->{PossibleValues} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Need PossibleValues in DynamicFieldConfig!",
        );
        return;
    }

    # check value
    my @Values;
    if ( ref $Param{Value} eq 'ARRAY' ) {
        @Values = @{ $Param{Value} };
    }
    else {
        @Values = ( $Param{Value} );
    }

    my @ValueText;
    for my $Item (@Values) {
        push @ValueText, { ValueText => $Item };
    }

    my $Success = $Self->{DynamicFieldValueObject}->ValueSet(
        FieldID  => $Param{DynamicFieldConfig}->{ID},
        ObjectID => $Param{ObjectID},
        Value    => \@ValueText,
        UserID   => $Param{UserID},
    );

    return $Success;
}

sub SearchSQLGet {
    my ( $Self, %Param ) = @_;

    my %Operators = (
        Equals            => '=',
        GreaterThan       => '>',
        GreaterThanEquals => '>=',
        SmallerThan       => '<',
        SmallerThanEquals => '<=',
    );

    if ( $Operators{ $Param{Operator} } ) {
        my $SQL = " $Param{TableAlias}.value_text $Operators{$Param{Operator}} '";
        $SQL .= $Self->{DBObject}->Quote( $Param{SearchTerm} ) . "' ";
        return $SQL;
    }

    if ( $Param{Operator} eq 'Like' ) {
        my $SQL = " LOWER($Param{TableAlias}.value_text) LIKE LOWER('";
        $SQL .= $Self->{DBObject}->Quote( $Param{SearchTerm}, 'Like' );
        $SQL .= "') " . $Self->{DBObject}->GetDatabaseFunction('LikeEscapeString') . ' ';
        return $SQL;
    }

    $Self->{'LogObject'}->Log(
        'Priority' => 'error',
        'Message'  => "Unsupported Operator $Param{Operator}",
    );

    return;
}

sub SearchSQLOrderFieldGet {
    my ( $Self, %Param ) = @_;

    return "$Param{TableAlias}.value_text";
}

sub EditFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};
    my $FieldName   = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel  = $Param{DynamicFieldConfig}->{Label};

    # set the field value or default
    my $Value = $FieldConfig->{DefaultValue} || '';
    $Value = $Param{Value}
        if defined $Param{Value};

    #d extract the dynamic field value form the web request
    my $FieldValue = $Self->EditFieldValueGet(
        %Param,
    );

    # set values from ParamObject if present
    if ( IsArrayRefWithData($FieldValue) ) {
        $Value = $FieldValue;
    }

    # check and set class if necessary
    my $FieldClass = 'DynamicFieldText';
    if ( defined $Param{Class} && $Param{Class} ne '' ) {
        $FieldClass .= ' ' . $Param{Class};
    }

    # set field as mandatory
    $FieldClass .= ' Validate_Required' if $Param{Mandatory};

    # set error css class
    $FieldClass .= ' ServerError' if $Param{ServerError};

    # set PossibleValues
    my $SelectionData = $FieldConfig->{PossibleValues};

    # use PossibleValuesFilter if defined
    $SelectionData = $Param{PossibleValuesFilter}
        if defined $Param{PossibleValuesFilter};

    # check value
    my @Values;
    if ( ref $Value eq 'ARRAY' ) {
        @Values = @{$Value};
    }
    else {
        @Values = ($Value);
    }

    my $HTMLString = $Param{LayoutObject}->BuildSelection(
        Data         => $SelectionData,
        Name         => $FieldName,
        SelectedID   => \@Values,
        Translation  => $FieldConfig->{TranslatableValues} || 0,
        PossibleNone => $FieldConfig->{PossibleNone} || 0,
        Class        => $FieldClass,
        HTMLQuote    => 1,
        Multiple     => 1,
    );

    if ( $Param{Mandatory} ) {
        my $DivID = $FieldName . 'Error';

        # for client side validation
        $HTMLString .= <<"EOF";

    <div id="$DivID" class="TooltipErrorMessage">
        <p>
            \$Text{"This field is required."}
        </p>
    </div>
EOF
    }

    if ( $Param{ServerError} ) {

        my $ErrorMessage = $Param{ErrorMessage} || 'This field is required.';
        my $DivID = $FieldName . 'ServerError';

        # for server side validation
        $HTMLString .= <<"EOF";
    <div id="$DivID" class="TooltipErrorMessage">
        <p>
            \$Text{"$ErrorMessage"}
        </p>
    </div>
EOF
    }

    # call EditLabelRender on the common backend
    my $LabelString = $Self->{BackendCommonObject}->EditLabelRender(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        Mandatory          => $Param{Mandatory} || '0',
        FieldName          => $FieldName,
    );

    my $Data = {
        Field => $HTMLString,
        Label => $LabelString,
    };

    return $Data;
}

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    # get dynamic field value form param
    my @ReturnData = $Param{ParamObject}
        ->GetArray( Param => 'DynamicField_' . $Param{DynamicFieldConfig}->{Name} );
    return \@ReturnData;
}

sub EditFieldValueValidate {
    my ( $Self, %Param ) = @_;

    # get the field value from the http request
    my $Values = $Self->EditFieldValueGet(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        ParamObject        => $Param{ParamObject},

        # not necessary for this backend but place it for consistency reasons
        ReturnValueStructure => 1,
    );

    my $ServerError;
    my $ErrorMessage;

    # perform necessary validations
    if ( $Param{Mandatory} && !IsArrayRefWithData($Values) ) {
        return {
            ServerError => 1,
        };
    }
    else {

        # get possible values list
        my $PossibleValues = $Param{DynamicFieldConfig}->{Config}->{PossibleValues};

        # overwrite possible values if PossibleValuesFilter
        if ( defined $Param{PossibleValuesFilter} ) {
            $PossibleValues = $Param{PossibleValuesFilter}
        }

        # validate if value is in possible values list (but let pass empty values)
        for my $Item ( @{$Values} ) {
            if ( !$PossibleValues->{$Item} ) {
                $ServerError  = 1;
                $ErrorMessage = 'The field content is invalid';
            }
        }
    }

    # create resulting structure
    my $Result = {
        ServerError  => $ServerError,
        ErrorMessage => $ErrorMessage,
    };

    return $Result;
}

sub DisplayValueRender {
    my ( $Self, %Param ) = @_;

    # set HTMLOuput as default if not specified
    if ( !defined $Param{HTMLOutput} ) {
        $Param{HTMLOutput} = 1;
    }

    # set Value and Title variables
    my $Value         = '';
    my $Title         = '';
    my $ValueMaxChars = $Param{ValueMaxChars} || '';
    my $TitleMaxChars = $Param{TitleMaxChars} || '';

    # check value
    my @Values;
    if ( ref $Param{Value} eq 'ARRAY' ) {
        @Values = @{ $Param{Value} };
    }
    else {
        @Values = ( $Param{Value} );
    }

    # get real values
    my $PossibleValues     = $Param{DynamicFieldConfig}->{Config}->{PossibleValues};
    my $TranslatableValues = $Param{DynamicFieldConfig}->{Config}->{TranslatableValues};

    my @ReadableValues;
    my @ReadableTitles;

    VALUEITEM:
    for my $Item (@Values) {
        next VALUEITEM if !$Item;

        if ( $PossibleValues->{$Item} ) {

            # get readeble value
            my $ReadableValue = $PossibleValues->{$Item};

            my $ReadableLength = length $ReadableValue;

            # check if needed to translate values
            if ($TranslatableValues) {

                # translate value
                $ReadableValue = $Param{LayoutObject}->{LanguageObject}->Get($ReadableValue);
            }

            # set title equal value
            my $ReadableTitle = $ReadableValue;

            # cut strings if needed
            if ( $ValueMaxChars ne '' ) {
                $ReadableValue = substr $ReadableValue, 0, $ValueMaxChars;

                # decrease the max parameter
                $ValueMaxChars = $ValueMaxChars - $ReadableLength;
                $ValueMaxChars = 0 if $ValueMaxChars < 0;
            }

            if ( $TitleMaxChars ne '' ) {
                $ReadableTitle = substr $ReadableTitle, 0, $TitleMaxChars;

                # decrease the max parameter
                $TitleMaxChars = $TitleMaxChars - $ReadableLength;
                $TitleMaxChars = 0 if $TitleMaxChars < 0;
            }

            # HTMLOuput transformations
            if ( $Param{HTMLOutput} ) {

                $ReadableValue = $Param{LayoutObject}->Ascii2Html(
                    Text => $ReadableValue,
                );

                $ReadableTitle = $Param{LayoutObject}->Ascii2Html(
                    Text => $ReadableTitle,
                );
            }

            push @ReadableValues, $ReadableValue;
            push @ReadableTitles, $ReadableTitle;
        }
    }

    # get specific field settings
    my $FieldConfig = $Self->{ConfigObject}->Get('DynamicFields::Backend')->{Multiselect} || {};

    # set new line separator
    my $ItemSeparator = $FieldConfig->{ItemSeparator} || ', ';

    # HTMLOuput transformations
    $Value = join( $ItemSeparator, @ReadableValues );
    $Title = join( $ItemSeparator, @ReadableTitles );

    # create return structure
    my $Data = {
        Value => $Value,
        Title => $Title,
    };

    return $Data;

}

sub IsSortable {
    my ( $Self, %Param ) = @_;

    return 0;
}

sub SearchFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};
    my $FieldName   = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel  = $Param{DynamicFieldConfig}->{Label};

    my $Value;

    my @DefaultValue;

    if ( defined $Param{DefaultValue} ) {
        my @DefaultValue = split /;/, $Param{DefaultValue};
    }

    # set the field value
    if (@DefaultValue) {
        $Value = \@DefaultValue;
    }

    # get the field value, this fuction is always called after the profile is loaded
    my $FieldValues = $Self->SearchFieldValueGet(
        %Param,
    );

    if ( defined $FieldValues )
    {
        $Value = $FieldValues;
    }

    # check and set class if necessary
    my $FieldClass = 'DynamicFieldMultiSelect';

    # set PossibleValues
    my $SelectionData = $FieldConfig->{PossibleValues};

    # get historical values from database
    my $HistoricalValues = $Self->{DynamicFieldValueObject}->HistoricalValueGet(
        FieldID   => $Param{DynamicFieldConfig}->{ID},
        ValueType => 'Text,',
    );

    # add historic values to current values (if they don't exist anymore)
    for my $Key ( keys %{$HistoricalValues} ) {
        if ( !$SelectionData->{$Key} ) {
            $SelectionData->{$Key} = $HistoricalValues->{$Key}
        }
    }

    # use PossibleValuesFilter if defined
    $SelectionData = $Param{PossibleValuesFilter}
        if defined $Param{PossibleValuesFilter};

    my $HTMLString = $Param{LayoutObject}->BuildSelection(
        Data         => $SelectionData,
        Name         => $FieldName,
        SelectedID   => $Value,
        Translation  => $FieldConfig->{TranslatableValues} || 0,
        PossibleNone => 1,
        Class        => $FieldClass,
        Multiple     => 1,
        HTMLQuote    => 1,
    );

    # call EditLabelRender on the common backend
    my $LabelString = $Self->{BackendCommonObject}->EditLabelRender(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        FieldName          => $FieldName,
    );

    my $Data = {
        Field => $HTMLString,
        Label => $LabelString,
    };

    return $Data;
}

sub SearchFieldValueGet {
    my ( $Self, %Param ) = @_;

    my $Value;

    # get dynamic field value form param object
    if ( defined $Param{ParamObject} ) {
        my @FieldValues = $Param{ParamObject}
            ->GetArray( Param => 'DynamicField_' . $Param{DynamicFieldConfig}->{Name} );

        $Value = \@FieldValues;
    }

    # otherwise get the value from the profile
    elsif ( defined $Param{Profile} ) {
        $Value = $Param{Profile}->{ 'DynamicField_' . $Param{DynamicFieldConfig}->{Name} };
    }
    else {
        return;
    }

    if ( defined $Param{ReturnProfileStructure} && $Param{ReturnProfileStructure} eq 1 ) {
        return {
            'DynamicField_' . $Param{DynamicFieldConfig}->{Name} => $Value,
        };
    }

    return $Value;

}

sub SearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    # get field value
    my $Value = $Self->SearchFieldValueGet(%Param);

    my $DisplayValue;

    if ($Value) {
        if ( ref $Value eq 'ARRAY' ) {

            my @DisplayItemList;
            for my $Item ( @{$Value} ) {

                # set the display value
                my $DisplayItem = $Param{DynamicFieldConfig}->{Config}->{PossibleValues}->{$Item};
                if ( $Param{DynamicFieldConfig}->{Config}->{TranslatableValues} ) {

                    # translate the value
                    $DisplayItem = $Param{LayoutObject}->{LanguageObject}->Get($DisplayValue);
                }

                push @DisplayItemList, $DisplayItem;
            }

            # combine different values into one string
            $DisplayValue = join ' + ', @DisplayItemList;
        }
        else {

            # set the display value
            $DisplayValue = $Param{DynamicFieldConfig}->{PossibleValues}->{$Value};

            if ( $Param{DynamicFieldConfig}->{Config}->{TranslatableValues} ) {

                # translate the value
                $DisplayValue = $Param{LayoutObject}->{LanguageObject}->Get($DisplayValue);
            }
        }
    }

    # return search parameter structure
    return {
        Parameter => {
            Equals => $Value,
        },
        Display => $DisplayValue,
    };
}

sub StatsFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    # set PossibleValues
    my $Values = $Param{DynamicFieldConfig}->{Config}->{PossibleValues};

    # get historical values from database
    my $HistoricalValues = $Self->{DynamicFieldValueObject}->HistoricalValueGet(
        FieldID   => $Param{DynamicFieldConfig}->{ID},
        ValueType => 'Text,',
    );

    # add historic values to current values (if they don't exist anymore)
    for my $Key ( keys %{$HistoricalValues} ) {
        if ( !$Values->{$Key} ) {
            $Values->{$Key} = $HistoricalValues->{$Key}
        }
    }

    # use PossibleValuesFilter if defined
    $Values = $Param{PossibleValuesFilter}
        if defined $Param{PossibleValuesFilter};

    return {
        Values             => $Values,
        Name               => 'DynamicField_' . $Param{DynamicFieldConfig}->{Label},
        Element            => 'DynamicField_' . $Param{DynamicFieldConfig}->{Name},
        TranslatableValues => $Param{DynamicFieldconfig}->{Config}->{TranslatableValues},
    };
}

sub StatsSearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    my $Operator = 'Equals';
    my $Value    = $Param{Value};

    return {
        $Operator => $Value,
    };
}

sub ReadableValueRender {
    my ( $Self, %Param ) = @_;

    # set Value and Title variables
    my $Value = '';
    my $Title = '';

    # check value
    my @Values;
    if ( ref $Param{Value} eq 'ARRAY' ) {
        @Values = @{ $Param{Value} };
    }
    else {
        @Values = ( $Param{Value} );
    }

    # get real values
    my $PossibleValues = $Param{DynamicFieldConfig}->{Config}->{PossibleValues};

    my @ReadableValues;

    VALUEITEM:
    for my $Item (@Values) {
        next VALUEITEM if !$Item;

        my $ReadableValue = $Item;
        if ( $PossibleValues->{$Item} ) {

            # get readeble value
            $ReadableValue = $PossibleValues->{$Item};
        }
        push @ReadableValues, $ReadableValue;
    }

    # set new line separator
    my $ItemSeparator = ', ';

    # Ouput transformations
    $Value = join( $ItemSeparator, @ReadableValues );
    $Title = $Value;

    # cut strings if needed
    $Value = substr $Value, 0, $Param{ValueMaxChars} if $Param{ValueMaxChars};
    $Title = substr $Title, 0, $Param{TitleMaxChars} if $Param{TitleMaxChars};

    # create return structure
    my $Data = {
        Value => $Value,
        Title => $Title,
    };

    return $Data;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$$

=cut
