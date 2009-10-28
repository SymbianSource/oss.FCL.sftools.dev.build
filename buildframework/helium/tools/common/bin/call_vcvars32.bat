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

REM Set MS Visual C++ environment
if "%MSVC_ENV_BAT%"=="" call :findmsvc vcvars32.bat
goto :foundmsvc
:findmsvc
set MSVC_ENV_BAT=%~$PATH:1
exit /b
:foundmsvc
if "%MSVC_ENV_BAT%"=="" set MSVC_ENV_BAT=C:\apps\msvc6\VC98\Bin\Vcvars32.bat
if not exist "%MSVC_ENV_BAT%" set MSVC_ENV_BAT=C:\Program Files\Microsoft Visual Studio\VC98\Bin\Vcvars32.bat
REM Do we need the following line to support MSVS.net 2003?
REM if not exist "%MSVC_ENV_BAT%" set MSVC_ENV_BAT=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\bin\Vcvars32.bat
if not exist "%MSVC_ENV_BAT%" ( echo *** WARNING: Can't find vcvars32.bat - MS Visual Studio not present. & goto MS_Set_Env_End )
call "%MSVC_ENV_BAT%" > nul
if not "%DEBUG%"=="" echo on
:MS_Set_Env_End
