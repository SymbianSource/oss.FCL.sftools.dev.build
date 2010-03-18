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

 
package com.nokia.helium.core.ant.types;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import java.util.Hashtable;
import org.apache.log4j.Logger;


/**
 * Class to execute the final target as post operation.
 */
public class HlmFinalTargetDef extends HlmPostDefImpl
{
    private Logger log = Logger.getLogger(HlmFinalTargetDef.class);
    
    /**
     * This post action will execute the final target if any to be executed.
     * @param prj
     * @param module
     * @param targetNames
     * 
     */
    public void execute(Project prj, String module, String[] targetNames) {
        String finalTargetName = prj.getProperty("hlm.target.final");
        log.debug("Calling final target" + finalTargetName);
        if (finalTargetName != null) {
            Hashtable targets = prj.getTargets();
            Target finalTarget = (Target)targets.get(finalTargetName);
            if (finalTarget == null) {
                log.info("The final target : " + finalTargetName + " not available skipping");
                return;
            }
            finalTarget.execute();
        }
    }
}