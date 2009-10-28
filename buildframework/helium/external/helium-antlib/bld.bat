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
if not defined JAVA_6_HOME (
set TESTED_JAVA=C:\Apps\j2sdk_1.6.0_02
) ELSE  set TESTED_JAVA=%JAVA_6_HOME%
if exist %TESTED_JAVA% (set JAVA_HOME=%TESTED_JAVA%)

REM Configure Ant 
if not defined TESTED_ANT_HOME (
set TESTED_ANT_HOME=C:\Apps\ant_1.7
) 
if exist %TESTED_ANT_HOME% (set ANT_HOME=%TESTED_ANT_HOME%)

REM Configure the expected Ant Version details below
SET expMajorVer=1
SET expMinorVer=7

rem *** Verify Ant Version ***
rem -- Run the 'ant -version' command and capture the output to a variable 
for /f "tokens=*" %%a in ('ant -version') do (set antversion=%%a)
echo *** Installed Version : %antversion%

rem -- Parse the version string obtained above and get the version number
for /f "tokens=4 delims= " %%a in ("%antversion%") do set val=%%a
rem -- Parse the version number delimiting the '.' and set the major and
rem    minor versions
for /f "tokens=1-2 delims=." %%a in ("%val%") do (
set /A majorVersion=%%a
set /A minorVersion=%%b
)
rem -- Check whether major version is greater than or equal to the expected.
if %majorVersion% geq %expMajorVer% ( 
rem -- if major version is valid, check minor version. If minor version is less
rem    than expected display message and abort the execution.
if %minorVersion% lss %expMinorVer% (echo *** Incorrect version of Ant found. Please check you have atleast Ant 1.7.0 & goto :errorstop ) 
)

set ANT_ARGS=-lib antlibs -lib lib -lib core/lib -lib diamonds/lib -lib scm/lib
ant %*
endlocal

:errorstop
@echo *** Build aborted with error
exit /b 1