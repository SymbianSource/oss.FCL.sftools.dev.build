@rem
@rem Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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

@SETLOCAL
@CALL "%~dp0\sbs_env.bat"

@REM Run with all the arguments.
@bash %SBS_HOME%\bin\sbs_filter %*

@ENDLOCAL
@cmd /c exit /b %ERRORLEVEL%
