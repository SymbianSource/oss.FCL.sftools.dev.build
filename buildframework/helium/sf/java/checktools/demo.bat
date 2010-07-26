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

"%JAVA_HOME%\bin\java" -cp "./../../bin/helium-checktools.jar" com.nokia.helium.checktools.HeliumToolsCheckerMain -config "./tests/config/helium.basic.tools.config"

IF (%ERRORLEVEL% == 0) GOTO :ok
IF (%ERRORLEVEL% == -1) GOTO :errorstop

:ok
GOTO :end

:errorstop
echo *** Build aborted with error
exit /b 1

:end