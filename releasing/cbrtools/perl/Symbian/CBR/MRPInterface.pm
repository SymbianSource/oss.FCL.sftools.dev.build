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
# 
#
# Description:
# Symbian::CBR::MRPInterface
#

package Symbian::CBR::MRPInterface;

use strict;
use Carp;


sub new {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::new\n";
}

sub _new_instance {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::_new_instance\n";
}

sub SetIPR {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::SetIPR\n";
}

sub SetComponent {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::SetComponent\n";
}

sub SetNotesSource {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::SetNotesSource\n";
}

sub SetSource {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::SetSource\n";
}

sub SetBinary {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::SetBinary\n";
}

sub SetExports {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::SetExports\n";
}

sub SetExportFile {    
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::SetExportFile\n";
}

sub GetIPRInformation {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::GetIPRInformation\n";
}

sub GetExportComponentDependencies {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::GetExportComponentDependencies\n";    
}

sub ValidateParsing {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::Validate\n";
}

sub Populated {
    croak 'Error: Call to interface method ' .  __PACKAGE__ . "::Populated\n";
}

1;