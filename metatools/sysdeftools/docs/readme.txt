# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
# Contributors:
# Description:

Run any .bat or .pl file with no arguments to get syntax and command line options.

*Directory structure*

Main directory contains XLST and Perl scripts and the .bat files that call them
docs contains this file
lib contains common XSLT modules
xalanj contains an implementation of Xalan-J, an XSLT processor implemented in Java


*The tools*

Filtering tools: 
filtering.xsl - Filter a sysdef in the 2.0 or 3.0 syntax
filtering.bat - Call filtering.xsl using xalan-j

Joining tools: 
joinsysdef.pl - Create a stand-alone sysdef from a linked set of fragments. Supports confguring via an .hrh file. By default this also embeds any linked metadata.
joinsysdef.bat - Call joinsysdef.pl
joinsysdef.xsl - Create a stand-alone sysdef from a linked set of fragments
joinandparesysdef.xsl - Create a stand-alone sysdef from a linked set of fragments, paring down to just a set of items of the desired rank.

Merging tools: 
mergesysdef.xsl - Merge two 3.x syntax stand-alone system definitions. It can process two standalone sysdefs or two sysdef fragments which describe the same system model item.
mergesysdef.bat - Call mergesysdef.xsl using xalan-j

Other tools:
sysdefdowngrade.xsl - Convert a 3.0.x sysdef to 2.0.1 sytnax
sysdefdowngrade.bat - Call sysdefdowngrade.xsl using xalan-j
rootsysdef.pl - Generate a root system definition from a template root sysdef and a set of wildcard paths to look for pkgdef files
rootsysdef.bat - Call rootsysdef.pl

Validation tools:
checklinks.pl - Checks that all referenced files in a system definition exist at the specified locations. If there are any linked system definition fragments, it will recursively check them as well.
checklinks.bat - call checklinks.pl
validate-sysdef.xsl - Validate a sysdef file, reporting any errors as plain text
validate-sysdef.bat - Call validate-sysdef.xsl using xalan-j

Modules (in lib):
filter-module.xsl - XSLT module which contains the logic to process the filter attribute in the system definition
joinsysdef-module.xsl - XSLT module which contains the logic to join a system definition file
mergesysdef-module.xsl - XSLT module for merging only two sysdef files according to the 3.0.0 rules
test-model.xsl - XSLT module for validating sysdef files
modelcheck.xsl - Validates a sysdef file, reporting any errors in HTM format. Can validate a sysdef in a web browser by using <?xml-stylesheet type="text/xsl" href="modelcheck.xsl"?>


XSLT Processing (in xalanj):
xalan.jar
xercesImpl.jar
xml-apis.jar
serializer.jar

