/*
* Copyright (c) 2007-2008 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of the License "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description:  
*
*/


package com.nokia.helium.core;

import java.io.File;

import org.apache.tools.ant.types.DataType;

/**
 * This class is the base class for all types of logs
 * 
 */
public class LogSource extends DataType {

    public File getFilename() {
        //will be implemented by subclasses
        throw new HlmAntLibException("Improper logsource usage"); 
    }

}