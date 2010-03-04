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
if exist "%TESTED_JAVA%" (set JAVA_HOME=%TESTED_JAVA%)
if not exist "%JAVA_HOME%" ( echo *** Java cannot be found & goto :errorstop )

REM Needed by python logging
set PID=1
perl "%HELIUM_HOME%\tools\common\bin\getppid.pl" > %TEMP%\%USERNAME%pid.txt
set /p PID=< %TEMP%\%USERNAME%pid.txt

REM Configure Apache Ant
set TESTED_ANT=C:\APPS\ant_1.7
if exist "%TESTED_ANT%" (set ANT_HOME=%TESTED_ANT%)
if not exist "%ANT_HOME%" ( echo *** Ant cannot be found & goto :errorstop )
if not defined ANT_OPTS (
	set ANT_OPTS=-Xmx896M -Dlog4j.configuration=com/nokia/log4j.xml
)

set SIGNALING_ANT_ARGS= -Dant.executor.class=com.nokia.helium.core.ant.HeliumExecutor
set LOGGING_ANT_ARGS= -listener com.nokia.helium.logger.ant.listener.StatusAndLogListener
REM -listener com.nokia.helium.logger.ant.listener.StatusAndLogListener
set DIAMONDS_ANT_ARGS= -listener com.nokia.helium.diamonds.ant.HeliumListener

if not defined HLM_DISABLE_INTERNAL_DATA (
set INTERNAL_DATA_ANT_ARGS= -listener com.nokia.helium.internaldata.ant.listener.Listener
echo Internal data listening enabled.
)


REM Configure listener to generate target times csv file.
REM **Note: Comment below line if you want to skip the target times csv file generation
set TARGET_TIMES_GENERATOR= -listener com.nokia.helium.core.ant.listener.TargetTimesLogGeneratorListener


if not defined ANT_ARGS (
set ANT_ARGS=-lib "%HELIUM_HOME%\extensions\nokia\external\antlibs" -lib "%HELIUM_HOME%\extensions\nokia\external\helium-nokia-antlib\bin" -lib "%HELIUM_HOME%\external\helium-antlib\bin" -lib "%HELIUM_HOME%\tools\common\java\lib" -lib "%HELIUM_HOME%\external\antlibs" -logger com.nokia.ant.HeliumLogger  %DIAMONDS_ANT_ARGS% %INTERNAL_DATA_ANT_ARGS% %SIGNALING_ANT_ARGS% %LOGGING_ANT_ARGS% %TARGET_TIMES_GENERATOR%
)

REM Shall we impose the EPOCROOT?
if not defined EPOCROOT (
set EPOCROOT=\
)

REM Symbian Build area path related settings
set PATH=%PATH%;%EPOCROOT%epoc32\tools;%EPOCROOT%epoc32\gcc\bin;%EPOCROOT%epoc32\tools\build;%EPOCROOT%epoc32\rombuild

set PATH=%PATH%;%HELIUM_HOME%\extensions\nokia\external\unxutils
set PATH=%PATH%;%HELIUM_HOME%\extensions\nokia\external\Subversion\bin
set PATH=%PATH%;%HELIUM_HOME%\extensions\nokia\external\graphviz\bin

for /f "tokens=2" %%a in ('"python -V 2>&1"') do (set pythonversion=%%a)
for /f "tokens=1-2 delims=." %%a in ("%pythonversion%") do (set pythonversion=%%a.%%b)

set PYTHONPATH=%PYTHONPATH%;%HELIUM_HOME%\external\python\lib\%pythonversion%;%HELIUM_HOME%\external\python\lib\common;%HELIUM_HOME%\external\helium-antlib\python\pythoncore\lib;%HELIUM_HOME%\tools\common\python\scripts
set PYTHONPATH=%PYTHONPATH%;%HELIUM_HOME%\extensions\nokia\external\python\lib\%pythonversion%
set PYTHONPATH=%PYTHONPATH%;%HELIUM_HOME%\extensions\nokia\tools\common\python\lib;%HELIUM_HOME%\extensions\nokia\external\helium-nokia-antlib\python;%HELIUM_HOME%\extensions\nokia\external\helium-nokia-antlib\python\pythonnokia\lib;%SBS_HOME%\python
set PERL5LIB=%HELIUM_HOME%\tools\common\packages
set COPYCMD=/y

REM Should be done that SYMSEE?
set PATH=%PATH%;C:\APPS\ctc

REM Nokia specific
set HOME=h:\
set ARMROOT=\


REM Manage RVCT switching.
if defined HLM_RVCT_VERSION (
if not exist "C:\APPS\rvct%HLM_RVCT_VERSION%\rvctcmdprompt.bat" ( echo *** "C:\APPS\rvct%HLM_RVCT_VERSION%\rvctcmdprompt.bat" cannot be found & goto :errorstop )
call "C:\APPS\rvct%HLM_RVCT_VERSION%\rvctcmdprompt.bat" > nul
)
TITLE Helium

if not exist "%HELIUM_HOME%\external\helium-antlib\bin\helium-checktools.jar" (
echo *** Error: helium-checktools.jar not found 
goto errorstop
)

REM call java -cp "%HELIUM_HOME%\external\helium-antlib\bin\helium-checktools.jar" com.nokia.helium.checktools.HeliumToolsCheckerMain -config "%HELIUM_HOME%\config\helium.basic.tools.config"
REM if "%ERRORLEVEL%" neq "0" (goto errorstop)

REM Call the Helium generated batch file if it exists
REM This must match with the cache.dir property in helium.ant.xml
if defined JOB_ID  (
	set HELIUM_CACHE_DIR=%TEMP%\helium\%USERNAME%\%JOB_ID%
)ELSE set HELIUM_CACHE_DIR=%TEMP%\helium\%USERNAME%

if not exist %HELIUM_CACHE_DIR% (
md %HELIUM_CACHE_DIR%
)

REM pass cache dir to a property for log4j log file
if defined ANT_OPTS (
	set ANT_OPTS=%ANT_OPTS% -Dlog4j.cache.dir=%HELIUM_CACHE_DIR% -Dpython.path=%PYTHONPATH%;%HELIUM_HOME%\external\python\lib\2.5\jython-2.5-py2.5.egg
)

call "%HELIUM_HOME%\precompile_py.bat" > %HELIUM_CACHE_DIR%\precompile_output.txt 

call ant -Dhelium.dir="%HELIUM_HOME%" -Dcache.dir="%HELIUM_CACHE_DIR%" %*

endlocal
goto :eof

:errorstop
@echo *** Build aborted with error
exit /b 1


