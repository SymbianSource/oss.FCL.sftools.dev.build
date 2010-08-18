@echo off

rem if not defined HELIUM_HOME set HELIUM_HOME=%~dp0..\..\..\helium

helium\hlm.bat %*

perl "%HELIUM_HOME%\tools\common\bin\getppid.pl" > %TEMP%\%USERNAME%pid.txt
set /p PID=< %TEMP%\%USERNAME%pid.txt

if not defined HLM_DISABLE_INTERNAL_DATA (
set INTERNAL_DATA_ANT_ARGS= -listener com.nokia.helium.internaldata.ant.listener.Listener
)


REM Configure listener to generate target times csv file.
REM **Note: Comment below line if you want to skip the target times csv file generation
set TARGET_TIMES_GENERATOR= -listener com.nokia.helium.core.ant.listener.TargetTimesLogGeneratorListener


if not defined ANT_ARGS (
set ANT_ARGS=-lib "%HELIUM_HOME%\external\antlibs2" -logger com.nokia.ant.HeliumLogger  %INTERNAL_DATA_ANT_ARGS% %SIGNALING_ANT_ARGS% %LOGGING_ANT_ARGS% %TARGET_TIMES_GENERATOR% -listener com.nokia.helium.environment.ant.listener.ExecListener
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

set PYTHONPATH=%HELIUM_HOME%\external\python\lib\auto;%HELIUM_HOME%\external\python\lib\%pythonversion%
set PYTHONPATH=%PYTHONPATH%;%HELIUM_HOME%\external\python\lib\common
set PYTHONPATH=%PYTHONPATH%;%HELIUM_HOME%\extensions\nokia\external\python\lib\%pythonversion%
set PYTHONPATH=%PYTHONPATH%;%SBS_HOME%\python
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

if not exist "%HELIUM_HOME%\external\antlibs2\helium-checktools-1.0.jar" (
echo *** Error: Please build helium from nokia_builder or builder dir run "bld && bld get-deps"
goto errorstop
)

call "%JAVA_HOME%\bin\java" -cp "%HELIUM_HOME%\external\antlibs2\helium-checktools-1.0.jar" com.nokia.helium.checktools.HeliumToolsCheckerMain -config "%HELIUM_HOME%\config\helium.basic.tools.config"
if not defined HLM_DISABLE_TOOL_CHECK (
if "%ERRORLEVEL%" neq "0" (goto errorstop)
)

REM Call the Helium generated batch file if it exists
if defined JOB_ID  (
	set HELIUM_CACHE_DIR="%TEMP%\helium\%USERNAME%\%JOB_ID%"
)ELSE set HELIUM_CACHE_DIR="%TEMP%\helium\%USERNAME%"

if not exist %HELIUM_CACHE_DIR% (
md %HELIUM_CACHE_DIR%
)

REM pass cache dir to a property for log4j log file
if not defined ANT_OPTS (
    set ANT_OPTS=-Xmx896M -Dlog4j.configuration=com/nokia/log4j.xml -Dlog4j.cache.dir=%HELIUM_CACHE_DIR% -Dpython.verbose=warning
    call "%HELIUM_HOME%\external\python\configure_jython.bat"
)

call ant -Dhelium.dir="%HELIUM_HOME%" -Dcache.dir=%HELIUM_CACHE_DIR% %*

endlocal
goto :eof

:errorstop
@echo *** Build aborted with error
exit /b 1


