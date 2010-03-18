@echo off

rem
rem Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
rem All rights reserved.
rem This component and the accompanying materials are made available
rem under the terms of the License "Eclipse Public License v1.0"
rem which accompanies this distribution, and is available
rem at the URL "http://www.eclipse.org/legal/epl-v10.html".
rem
rem Initial Contributors:
rem Nokia Corporation - initial contribution.
rem
rem Contributors:
rem
rem Description: 
rem

setlocal

REM Set the Helium location
REM Make sure the path is not ending with a backslash!
if not defined HELIUM_HOME (
	set HELIUM_HOME_TEMP=%~dp0
)
if not defined HELIUM_HOME (
	set HELIUM_HOME=%HELIUM_HOME_TEMP:~0,-1%
)

set HLM_DISABLE_INTERNAL_DATA=1


set ANT_ARGS=-lib "%HELIUM_HOME%\external\antlibs" -logger org.apache.tools.ant.DefaultLogger

hlm -f build-jar.ant.xml jar


endlocal

