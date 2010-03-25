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

set HELIUM_HOME=.
set PYTHONPATH=%HELIUM_HOME%\external\python\lib\2.5;%HELIUM_HOME%\tools\common\python\lib;%HELIUM_HOME%\tools\dp\iCreatorDP;c:\apps\sbs\python;%HELIUM_HOME%\extensions\nokia\external\python\lib\2.5;

python external\python\bin\nosetests-script.py -v %*

endlocal

