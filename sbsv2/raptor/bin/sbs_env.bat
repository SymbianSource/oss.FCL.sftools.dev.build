@rem
@rem Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
@rem All rights reserved.
@rem This component and the accompanying materials are made available
@rem under the terms of the License "Eclipse Public License v1.0"
@rem which accompanies this distribution, and is available
@rem at the URL "http://www.eclipse.org/legal/epl-v10.html".
@rem
@rem Initial Contributors:
@rem Nokia Corporation - initial contribution.
@rem
@rem Contributors:
@rem
@rem Description: 
@rem

@SET HOSTPLATFORM=win 32
@SET HOSTPLATFORM_DIR=win32

@REM Automatically find SBS_HOME if it is not set
@IF NOT "%SBS_HOME%"==""  goto foundhome
@SET RAPTORBINDIR=%~dp0
@SET WD=%cd%
@cd /d %RAPTORBINDIR%\..
@SET SBS_HOME=%cd%
@cd /d %WD%
:foundhome 

@REM Use the python set by the environment if possible
@SET __PYTHON__=%SBS_PYTHON%
@IF "%__PYTHON__%"=="" SET __PYTHON__=%SBS_HOME%\win32\python264\python.exe
@SET PYTHONPATH=%SBS_PYTHONPATH%
@IF "%PYTHONPATH%"=="" SET PYTHONPATH=%SBS_HOME%\win32\python264

@REM Use the mingw set by the environment if possible
@SET __MINGW__=%SBS_MINGW%
@IF "%__MINGW__%"=="" SET __MINGW__=%SBS_HOME%\win32\mingw

@REM Use the cygwin set by the environment if possible
@SET __CYGWIN__=%SBS_CYGWIN%
@IF "%__CYGWIN__%"=="" SET __CYGWIN__=%SBS_HOME%\win32\cygwin

@REM add to the search path
@REM (make sure that we don't get into trouble if there are Path and PATH variables)
@SET PATH_TEMP=%__MINGW__%\bin;%__CYGWIN__%\bin;%SBS_HOME%\win32\bin;%PATH%
@SET PATH=
@SET PATH=%PATH_TEMP%
@SET PATH_TEMP=

@REM Tell CYGWIN not to map unix security attributes to windows to
@REM prevent raptor from potentially creating read-only files:
@REM
@REM
@REM

@REM Assume Cygwin 1.5 CLI.
@SET __MOUNTOPTIONS__=-u
@SET __UMOUNTOPTIONS__=-u
@SET CYGWIN=nontsec nosmbntsec

@REM Make sure that /tmp is not set incorrectly for sbs. 
@umount %__UMOUNTOPTIONS__% /tmp >NUL  2>NUL

@REM If this fails, that means we are using Cygwin 1.7, so change the options and redo the first umount
@IF %ERRORLEVEL% == 1 SET CYGWIN=nodosfilewarning && SET __MOUNTOPTIONS__=-o noacl -o user && SET __UMOUNTOPTIONS__=&& umount %__UMOUNTOPTIONS__% /tmp >NUL  2>NUL

@mount %__MOUNTOPTIONS__% %TEMP% /tmp >NUL 2>NUL
@umount %__UMOUNTOPTIONS__% / >NUL  2>NUL
@mount %__MOUNTOPTIONS__% %__CYGWIN__% / >NUL 2>NUL

