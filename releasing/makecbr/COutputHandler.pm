# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
# COutputHandler
# 
#

package COutputHandler;

use strict;
use XML::Simple;
use File::Basename;
use File::Spec;

use constant CBROUTPUTFILE => File::Spec->catdir(File::Basename::dirname("$INC{'COutputHandler.pm'}"), 'CBROutputFile.xml');

sub new {
    my $pkg = shift;
    my $self = {};
    bless $self, $pkg;
    
    $self->ParseOutputFile();
    
    return $self;
}


sub CheckOutput {
    my $self = shift;
    my $line = shift;
    
    chomp $line;
    
    my $amendedLine = $line;
    $amendedLine =~ s/^-?\s?(error|warning|remark|fatal error):?\s+//i;

    foreach my $type ('Error', 'Remark', 'Warning') {
        foreach my $toMatch (@{$self->{file}->{$type}}) {           
            if ($amendedLine =~ /^$toMatch$/) {
                return uc($type) . ": $amendedLine\n";
            }           
        }
    }

    # did not match, return original line
    return "$line\n";
}


sub ParseOutputFile {
    my $self = shift;
    $self->{file} = XMLin(CBROUTPUTFILE);
    
    # Compile the regular expressions
    foreach my $type ('Error', 'Remark', 'Warning') {
       @{$self->{file}->{$type}} = map { qr/$_/i } @{$self->{file}->{$type}}
    }
}

1;

__END__

=pod

=head1 NAME

COutputHandler.pm

=head1 DESCRIPTION

A module that checks output from the CBR Tools and promotes requested errors, warnings and remarks to scanlog compatible versions.

=head1 SYNOPSIS

 use strict;
 use COutputHandler;
 
 # Instantiate implementation of COutputHandler
 my $outputHandler = COutputHandler->new();

 # Pass the string through CheckOutput before printing it to the log
 $aLine = $outputHandler->CheckOutput($aLine);
 
 print $aLine;

=head1 INTERFACE

=head2 Object Management

=head3 new

To be called without any arguments.  Will parse the XML file containing error, warning and remark messages.

=head2 Data Management

=head3 CheckOuput

To be passed a string.  The string is checked to see if it needs to be made scanlog compatible, and if so it is modified and returned.  If not then the original string is returned.

=head3 ParseOutputFile

Parses the XML file.

=head1 COPYRIGHT

Copyright (c) 2007 Symbian Software Ltd. All rights reserved.

=cut