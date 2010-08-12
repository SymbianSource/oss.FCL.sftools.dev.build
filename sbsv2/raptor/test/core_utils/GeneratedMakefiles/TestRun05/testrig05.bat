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
@rem Description: 
@rem

ECHO junk_file: this file is the dummy file to be used in the cp-testing. > junk_file
SET SBS_HOME=D:\yiluzhu\CBR\m04710\raptor
SET PATH=%SBS_HOME%\win32\mingw\bin;D:\danieljacobs\msystest\cygwin\bin;%PATH%

@REM Run mingw32-make with various values of j
FOR /L %%r in (1,1,100) DO (
FOR %%j in (50 100) DO (
FOR %%f IN (makefile_env_1000_targets_50_divisions.mk makefile_env_1000_targets_100_divisions.mk) DO (
make -j %%j -f %%f > %%f_jobs_%%j_run_%%r.log 2>&1
)
)
)
