@rem Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
@setlocal
@if .%1==. goto use
@ java -jar %~dp0xalanj\xalan.jar -xsl %~dpn0.xsl %* 
@goto end
:use
@ java -jar %~dp0xalanj\xalan.jar -in %~dpn0.xsl -xsl %~dp0lib\usage.xsl -param usage "%~n0"
:end
