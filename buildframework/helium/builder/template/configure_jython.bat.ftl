<#-- 
============================================================================ 
Name        : configure_jython.bat.ftl 
Part of     : Helium AntLib

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.
This component and the accompanying materials are made available
under the terms of the License "Eclipse Public License v1.0"
which accompanies this distribution, and is available
at the URL "http://www.eclipse.org/legal/epl-v10.html".

Initial Contributors:
Nokia Corporation - initial contribution.

Contributors:

Description:

============================================================================
-->
set ANT_OPTS=%ANT_OPTS% -Dpython.path=%HELIUM_HOME%\external\python\lib\2.5\jython-2.5-py2.5.egg;<#list project.getReference('egg.hlm.deps.fileset').toString().split(';') as file>%HELIUM_HOME%\${file};</#list>;%PYTHONPATH%
