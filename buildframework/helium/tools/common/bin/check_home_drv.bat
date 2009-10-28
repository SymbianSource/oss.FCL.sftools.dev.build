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

REM This is needed by buildbot service to connect H: drive
net use
net use | find  "Unavailable  H:" >arg.txt
if %ERRORLEVEL% == 1 goto end
echo net use %%2 %%3 > temp.bat
set /P t_var=<arg.txt
call temp.bat %t_var%
rem del temp.bat
rem del arg.txt
set t_var=
:end