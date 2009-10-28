#============================================================================ 
#Name        : getppid.pl 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description: 
#============================================================================

use Win32;
sub _getppid() {
    
    my $ppid;

    if ($^O =~ /^MSWin/) {
        my $pid = $$;
        my $machine = "\\\\.";
        
        require Win32::OLE;
        require Win32::OLE::Variant;
    
        # WMI Win32_Process class
        my $class =
"winmgmts:{impersonationLevel=impersonate}$machine\\Root\\cimv2";
        if (my $wmi = Win32::OLE-> GetObject($class)) {
            if(my $proc=$wmi-> Get(qq{Win32_Process.Handle="$pid"})) {
                $ppid = $proc-> {ParentProcessId} if
($proc-> {ParentProcessId}!=0);
            }
        }
    }
    else {
        $ppid = getppid();
    }
    
    return $ppid;
}
my $name = shift @ARGV or "";
print $name._getppid()."\n";
