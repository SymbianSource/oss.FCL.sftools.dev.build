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
@rem Kicks off the Terminal Filter refiltering for use with terminal_filter_tests.py

@SETLOCAL

@SET HOSTPLATFORM=win 32
@SET HOSTPLATFORM_DIR=win32

@set PYTHONPATH=%SBS_HOME%/python;%SBS_HOME%/python/plugins

@python %SBS_HOME%\test\smoke_suite\test_resources\refilter\testfilterterminal.py

@endlocal
