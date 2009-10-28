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

rem Loading runtime environment tools
if exist "%HELIUM_HOME%\runtime\runtime_env.bat" (
call %HELIUM_HOME%\runtime\runtime_env.bat
) 

if not exist "%HELIUM_HOME%\extensions\nokia\distribution.policy.S60" ( 
set HLM_SUBCON=1
set HLM_DISABLE_INTERNAL_DATA=1
)


REM Configure Java
if not defined JAVA_6_HOME (
set TESTED_JAVA=C:\Apps\j2sdk_1.6.0_02
) ELSE  set TESTED_JAVA=%JAVA_6_HOME%
if exist %TESTED_JAVA% (set JAVA_HOME=%TESTED_JAVA%)
if not exist "%JAVA_HOME%" ( echo *** Java cannot be found & goto :errorstop )
set JEP_HOME=%HELIUM_HOME%\external\jep_1.6_2.5
set PATH=%PATH%;%JEP_HOME%

REM Needed by python logging
set PID=1
perl "%HELIUM_HOME%\tools\common\bin\getppid.pl" > %TEMP%\%USERNAME%pid.txt
set /p PID=< %TEMP%\%USERNAME%pid.txt

REM Configure Apache Ant
set TESTED_ANT=C:\APPS\ant_1.7
if exist %TESTED_ANT% (set ANT_HOME=%TESTED_ANT%)
if not exist "%ANT_HOME%" ( echo *** Ant cannot be found & goto :errorstop )
if not defined ANT_OPTS (
	set ANT_OPTS=-Xmx896M -Dlog4j.configuration=com/nokia/log4j.xml
)

set SIGNALING_ANT_ARGS= -Dant.executor.class=com.nokia.helium.core.ant.HeliumExecutor
set DIAMONDS_ANT_ARGS= -listener com.nokia.helium.diamonds.ant.HeliumListener

if not defined HLM_DISABLE_INTERNAL_DATA (
set INTERNAL_DATA_ANT_ARGS= -listener com.nokia.ant.listener.internaldata.Listener
echo Internal data listening enabled.
)

if not defined ANT_ARGS (
set ANT_ARGS=-lib "%HELIUM_HOME%\extensions\nokia\external\antlibs" -lib "%HELIUM_HOME%\extensions\nokia\external\helium-nokia-antlib\bin" -lib "%HELIUM_HOME%\external\helium-antlib\bin" -lib "%HELIUM_HOME%\tools\common\java\lib" -lib "%HELIUM_HOME%\external\antlibs" -lib "%JEP_HOME%" -logger com.nokia.ant.HeliumLogger  %DIAMONDS_ANT_ARGS% %INTERNAL_DATA_ANT_ARGS% %SIGNALING_ANT_ARGS%
)

REM Shall we impose the EPOCROOT?
if not defined EPOCROOT (
set EPOCROOT=\
)

REM Symbian Build area path related settings
set PATH=%PATH%;%EPOCROOT%epoc32\tools;%EPOCROOT%epoc32\gcc\bin;%EPOCROOT%epoc32\tools\build;%EPOCROOT%epoc32\rombuild

REM Helium specific settings
set PATH=%PATH%;%HELIUM_HOME%\tools\common\bin
set PATH=%PATH%;%HELIUM_HOME%\extensions\nokia\external\doxygen
set PATH=%PATH%;%HELIUM_HOME%\extensions\nokia\external\unxutils
set PATH=%PATH%;%HELIUM_HOME%\external\filedisk
set PATH=%PATH%;%HELIUM_HOME%\extensions\nokia\external\info-zip
set PATH=%PATH%;%HELIUM_HOME%\extensions\nokia\external\Subversion\bin
set PATH=%PATH%;%HELIUM_HOME%\extensions\nokia\external\graphviz\bin
set PATH=%PATH%;%HELIUM_HOME%\extensions\nokia\external\LSC_5.2
set PATH=%PATH%;\tools
set PATH=%PATH%;\tools\ncp_tools
set PYTHONPATH=%PYTHONPATH%;%HELIUM_HOME%\external\python\lib\2.5;%HELIUM_HOME%\tools\common\python\lib
set PYTHONPATH=%PYTHONPATH%;%HELIUM_HOME%\extensions\nokia\external\python\lib\2.5
set PYTHONPATH=%PYTHONPATH%;%HELIUM_HOME%\extensions\nokia\tools\common\python\lib;%SBS_HOME%\python
set PERL5LIB=%HELIUM_HOME%\tools\common\packages
set COPYCMD=/y
set spp_tools=\tools\
set ppd_tools=\tools\

REM Should be done that SYMSEE?
set PATH=%PATH%;C:\APPS\ctc

REM Nokia specific
set HOME=h:\
set ARMROOT=\


REM Setting the Visual Studio environment
REM if not exist "%HELIUM_HOME%\tools\common\bin\call_vcvars32.bat" ( echo *** "%HELIUM_HOME%\tools\common\bin\call_vcvars32.bat" cannot be found & goto :errorstop )
REM call "%HELIUM_HOME%\tools\common\bin\call_vcvars32.bat" > nul

REM Manage RVCT switching.
if defined HLM_RVCT_VERSION (
if not exist "C:\APPS\rvct%HLM_RVCT_VERSION%\rvctcmdprompt.bat" ( echo *** "C:\APPS\rvct%HLM_RVCT_VERSION%\rvctcmdprompt.bat" cannot be found & goto :errorstop )
call "C:\APPS\rvct%HLM_RVCT_VERSION%\rvctcmdprompt.bat" > nul
)
TITLE Helium

call "%JAVA_HOME%\bin\java" -cp "%HELIUM_HOME%\tools\common\bin" CheckTools

REM Call the Helium generated batch file if it exists
REM This must match with the cache.dir property in helium.ant.xml
set HELIUM_CACHE_DIR=%TEMP%\helium\%USERNAME%
if not exist %HELIUM_CACHE_DIR% (
md %HELIUM_CACHE_DIR%
)

REM pass cache dir to a property for log4j log file
if defined ANT_OPTS (
	set ANT_OPTS=%ANT_OPTS% -Dlog4j.cache.dir=%HELIUM_CACHE_DIR% -Dpython.path=%PYTHONPATH%;%HELIUM_HOME%\external\python\lib\2.5\jython-2.5-py2.5.egg
)

call "%HELIUM_HOME%\precompile_py.bat"

call ant -Dhelium.dir="%HELIUM_HOME%" %*

endlocal
goto :eof


:errorstop
@echo *** Build aborted with error
exit /b 1

