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
set OLDANT_ARGS=-lib %CD%\..\lib -lib %ANT_LIB_HOME%\lib -lib %ANT_LIB_HOME%\bin\helium-core.jar -lib %CD%\..\..\bin\helium-blocks.jar -lib %ANT_LIB_HOME%\antlibs
call ant %*
if "%ERRORLEVEL%" neq "0" (goto error)
endlocal
goto :eof

:error
endlocal
if "%OS%"=="Windows_NT" color 00

