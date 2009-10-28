@echo off
REM 
REM Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies). 
REM All rights reserved.
REM This component and the accompanying materials are made available
REM under the terms of the License "Symbian Foundation License v1.0"
REM which accompanies this distribution, and is available
REM at the URL "http://www.symbianfoundation.org/legal/sfl-v10.html".
REM 
REM Initial Contributors:
REM Nokia Corporation - initial contribution.
REM 
REM Contributors:
REM 
REM Description:
REM cmaker windows batch file.
REM 


setlocal
set MAKEFILES=/epoc32/tools/cmaker/tools.mk
if "%PERL%"==""             set PERL=perl
if "%CMAKER_DIR%"==""       set CMAKER_DIR=%~dp0
set CMAKER_MAKECMD=/epoc32/tools/rom/mingw_make.exe -R --no-print-directory -I /epoc32/tools/cmaker %*

REM The script call itself with perl
%PERL% -x -S %~f0
endlocal
exit /b %errorlevel%

#!perl
my $begin=time();
system($ENV{CMAKER_MAKECMD});
my $end=time();
print "Duration: ".($end-$begin)." seconds\n";

__END__

