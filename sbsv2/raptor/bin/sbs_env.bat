@REM
@REM Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
@REM All rights reserved.
@REM This component and the accompanying materials are made available
@REM under the terms of the License "Eclipse Public License v1.0"
@REM which accompanies this distribution, and is available
@REM at the URL "http://www.eclipse.org/legal/epl-v10.html".
@REM
@REM Initial Contributors:
@REM Nokia Corporation - initial contribution.
@REM
@REM Contributors:
@REM
@REM Description: 
@REM

@SET HOSTPLATFORM=win 32
@SET HOSTPLATFORM_DIR=win32

@REM Automatically find SBS_HOME if it is not set
@IF NOT "%SBS_HOME%"=="" GOTO foundhome
@SET RAPTORBINDIR=%~dp0
@SET WD=%CD%
@CD /d %RAPTORBINDIR%\..
@SET SBS_HOME=%CD%
@CD /d %WD%
:foundhome 

@REM The python and PYTHONPATH used by Raptor are determined by, in order of precedence:
@REM 1. the SBS_PYTHON and SBS_PYTHONPATH environment variables (if set)
@REM 2. the python shipped locally with Raptor (if present)
@REM 3. the python on the system PATH and the PYTHONPATH set in the system environment

@SET __LOCAL_PYTHON__=%SBS_HOME%\win32\python264\python.exe
@IF NOT "%SBS_PYTHON%"=="" GOTO sbspython
@IF EXIST %__LOCAL_PYTHON__% GOTO localpython
@SET __PYTHON__=python.exe
@GOTO sbspythonpath

:sbspython
@SET __PYTHON__=%SBS_PYTHON%
@GOTO sbspythonpath

:localpython
@SET __PYTHON__=%__LOCAL_PYTHON__%
@SET SBS_PYTHON=%__PYTHON__%
@SET PYTHONPATH=

:sbspythonpath
@IF NOT "%SBS_PYTHONPATH%"=="" SET PYTHONPATH=%SBS_PYTHONPATH%

@REM Use the mingw set by the environment if possible
@SET __MINGW__=%SBS_MINGW%
@IF "%__MINGW__%"=="" SET __MINGW__=%SBS_HOME%\win32\mingw

@REM Tell CYGWIN not to map unix security attributes to windows to
@REM prevent raptor from potentially creating read-only files.
@REM Assume Cygwin 1.5 CLI.
@SET __MOUNTOPTIONS__=-u
@SET __UMOUNTOPTIONS__=-u
@SET CYGWIN=nontsec nosmbntsec

@REM If SBS_CYGWIN17 is set, we are using Cygwin 1.7, so change the mount/umount 
@REM options to the 1.7 CLI and set SBS_CYGWIN to the value of SBS_CYGWIN17
@IF NOT "%SBS_CYGWIN17%" == "" SET CYGWIN=nodosfilewarning && SET "SBS_CYGWIN=%SBS_CYGWIN17%" && SET __MOUNTOPTIONS__=-o noacl -o user && SET __UMOUNTOPTIONS__=

@REM Use the Cygwin set by the environment (from SBS_CYGWIN or SBS_CYGWIN17) if possible
@SET __CYGWIN__=%SBS_CYGWIN%
@IF "%__CYGWIN__%"=="" SET __CYGWIN__=%SBS_HOME%\win32\cygwin

@REM Add to the search path
@REM (make sure that we don't get into trouble if there are Path and PATH variables)
@SET PATH_TEMP=%__MINGW__%\bin;%__CYGWIN__%\bin;%SBS_HOME%\win32\bin;%PATH%
@SET PATH=
@SET PATH=%PATH_TEMP%
@SET PATH_TEMP=

@REM Make sure that /tmp is not set incorrectly for sbs. 
@umount %__UMOUNTOPTIONS__% /tmp >NUL  2>NUL
@mount %__MOUNTOPTIONS__% %TEMP% /tmp >NUL 2>NUL
@umount %__UMOUNTOPTIONS__% / >NUL  2>NUL
@mount %__MOUNTOPTIONS__% %__CYGWIN__% / >NUL 2>NUL

