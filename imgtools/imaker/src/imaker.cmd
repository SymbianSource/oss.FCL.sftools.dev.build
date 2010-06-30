@rem
@rem Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
@rem Description: iMaker wrapper for Windows
@rem


@echo off
setlocal
set IMAKER_CMDARG=%*
if "%IMAKER_DIR%"=="" (
    set IMAKER_DIR=%~dp0rom\imaker
    if exist %~dp0imaker.pl set IMAKER_DIR=%~dp0
)
set IMAKER_TOOL=%~f0

if "%PERL%"=="" set PERL=perl
call %PERL% -x %IMAKER_DIR%\imaker.pl
set IMAKER_ERROR=%errorlevel%

if %IMAKER_ERROR% neq 0 (
    call %PERL% -v >nul 2>&1
    if errorlevel 1 (
        echo Perl is not properly installed! Environment variable PERL can be used to set the Perl exe.
    )
)

if 0%IMAKER_EXITSHELL% equ 0 exit /b %IMAKER_ERROR%
exit %IMAKER_ERROR%
endlocal

:: END OF IMAKER.CMD
