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

 
package com.nokia.helium.signal.ant.types;

import org.apache.tools.ant.Project;
import com.nokia.helium.core.ant.types.*;
import org.apache.tools.ant.BuildException;
import com.nokia.helium.signal.*;
import com.nokia.helium.signal.ant.SignalListener;
import org.apache.log4j.Logger;


/**
 * Class to store the status of the signal of a particular target.
 */
public class SignalStatusDef extends HlmPostDefImpl
{
    private Logger log = Logger.getLogger(SignalListener.class);
    
    /**
     * This post action will fail the build if any pending failure exists. 
     * @throws BuildException
     */
    public void execute(Project prj, String module, String[] targetNames) {
        if (SignalStatusList.getDeferredSignalList().hasSignalInList()) {
            throw new BuildException(SignalStatusList.getDeferredSignalList().getErrorMsg());
        }
    }
}