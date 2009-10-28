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
set HELIUMCCEXT_HOME=%~dp0

REM Detecting CruiseControl
if not defined CCDIR (
if exist "%HELIUMCCEXT_HOME%..\..\cruisecontrol\cruisecontrol.bat" (
set CCDIR=%HELIUMCCEXT_HOME%..\..\cruisecontrol
) else (
echo CCDIR is not defined
goto :end
)
)

if not defined DASHBOARD_CONFIG set DASHBOARD_CONFIG=%HELIUMCCEXT_HOME%helium-dashboard-config.xml
set CC_OPTS=%CC_OPTS%  -Ddashboard.config=%DASHBOARD_CONFIG% -Dhelium.cc.ext.home=%HELIUMCCEXT_HOME%
set CC_ARGS=-lib %HELIUMCCEXT_HOME%lib -webapppath %CCDIR%/webapps/cruisecontrol -dashboard %CCDIR%/webapps/dashboard -jettyxml %HELIUMCCEXT_HOME%etc/jetty.xml %CC_ARGS%
call %CCDIR%\cruisecontrol.bat %CC_ARGS% %*
:end
endlocal
