@rem
@rem Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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

@echo off

set HOSTPLATFORM=win 32
set HOSTPLATFORM_DIR=win32

setlocal
set __PYTHON__=%SBS_PYTHON%
if "%__PYTHON__%"=="" set __PYTHON__=%SBS_HOME%\win32\python252\python.exe

set __TEST_SUITE__=%SBS_HOME%\test\common\run_tests.pyc
set __TEST_SUITE_PY__=%SBS_HOME%\test\common\run_tests.py

@REM Mount '/' in cygwin, in case it is not done automatically
set __CYGWIN__=%SBS_CYGWIN%
if "%__CYGWIN__%"=="" set __CYGWIN__=%SBS_HOME%\win32\cygwin
%__CYGWIN__%\bin\umount -u "/" >NUL  2>NUL
%__CYGWIN__%\bin\mount -u "%__CYGWIN__%" "/"

@REM If the Python source exists, use it. Else use the byte-compiled Python code
if exist %__TEST_SUITE_PY__% SET __TEST_SUITE__=%__TEST_SUITE_PY__%

@REM Then run the test suite with all the arguments
%__PYTHON__% -tt %__TEST_SUITE__% %*

endlocal
@echo on
