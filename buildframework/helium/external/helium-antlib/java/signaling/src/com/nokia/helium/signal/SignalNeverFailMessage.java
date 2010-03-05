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
* Description: To print the message on the shell in case of build has errors
* is user sets failbuild status to never in signal configuration file.
*
*/
 
package com.nokia.helium.signal;


import org.apache.tools.ant.Project;
import com.nokia.helium.core.ant.types.*;
import org.apache.log4j.Logger;

/**
 * Class to check the signal is present in the never signal list.
 * Print the message on the shell "Build completed with errors and warnings".
 * 
 */
public class SignalNeverFailMessage extends HlmPostDefImpl
{
    private Logger log = Logger.getLogger(SignalNeverFailMessage.class); 
    
    /**
     * Override execute method to print build completed message.
     * @param prj
     * @param module
     * @param targetNames
     */
    
    public void execute(Project prj, String module, String[] targetNames) {
        
        if (SignalStatusList.getNeverSignalList().hasSignalInList()) {
            log.info("Build completed with errors and warnings.");
        }
        
    }
}