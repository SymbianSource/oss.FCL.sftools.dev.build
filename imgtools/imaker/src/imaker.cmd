@echo off
rem
rem Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
rem All rights reserved.
rem This component and the accompanying materials are made available
rem under the terms of the License "Symbian Foundation License v1.0"
rem which accompanies this distribution, and is available
rem at the URL "http://www.symbianfoundation.org/legal/sfl-v10.html".
rem
rem Initial Contributors:
rem Nokia Corporation - initial contribution.
rem
rem Contributors:
rem
rem Description: iMaker wrapper for Windows
rem


setlocal
set MAKE=
set IMAKER_CMDARG=%*
if "%EPOCROOT%"==""         set EPOCROOT=\
if "%CONFIGROOT%"==""       set CONFIGROOT=%EPOCROOT%epoc32\rom\config
if "%ITOOL_DIR%"==""        set ITOOL_DIR=%EPOCROOT%epoc32\tools\rom
if "%IMAKER_DIR%"==""       set IMAKER_DIR=%ITOOL_DIR%\imaker
if "%IMAKER_MAKE%"==""      set IMAKER_MAKE=%IMAKER_DIR%\mingw_make.exe
if "%IMAKER_MAKESHELL%"=="" set IMAKER_MAKESHELL=%COMSPEC%
if "%IMAKER_MAKESHELL%"=="" set IMAKER_MAKESHELL=cmd.exe
if "%IMAKER_CYGWIN%"==""    set IMAKER_CYGWIN=0
if "%PERL%"==""             set PERL=perl
call %PERL% -x %IMAKER_DIR%\imaker.pl
set IMAKER_ERROR=%errorlevel%
if %IMAKER_ERROR% geq 1 (
    call %PERL% -v >nul 2>&1
    if errorlevel 1 echo Perl is not properly installed! Environment variable PERL can be used to set the Perl exe.
)
if 0%IMAKER_EXITSHELL% equ 0 exit /b %IMAKER_ERROR%
exit %IMAKER_ERROR%
endlocal

:: END OF IMAKER.CMD
