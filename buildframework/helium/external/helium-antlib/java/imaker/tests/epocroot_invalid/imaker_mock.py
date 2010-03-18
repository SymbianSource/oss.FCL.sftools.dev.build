#============================================================================ 
#Name        : imaler_mock.py 
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
#===============================================================================

import sys
print "iMaker 09.24.01, 10-Jun-2009."
sys.stderr.write("""mingw_make: /epoc32/rom/config/platform/product/image_conf_invalid.mk: No such file or directory
mingw_make: *** No rule to make target `/epoc32/rom/config/platform/product/image_conf_invalid.mk'.  Stop.
*** Error: Command `\epoc32\tools\rom\imaker\mingw_make.exe -R --no-print-directory SHELL="C:\WINNT\system32\cmd.exe" -I
 B:/epoc32/rom/config -f B:/epoc32/tools/rom/imaker/imaker.mk TIMESTAMP=2009102317302243    -f /epoc32/rom/config/platform/
product/image_conf_invalid.mk  -f B:/epoc32/tools/rom/imaker/imaker.mk help-target-*-list' failed in `/'.
""")
sys.exit(1)
