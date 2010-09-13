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

import java.util.Hashtable;

import org.apache.log4j.Logger;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.PostBuildAction;

/**
 * Class to execute the final target as post build action.
 * 
 * @ant.type name="finaltargetdef" category="Core"
 */
public class HlmFinalTargetDef extends DataType implements PostBuildAction {
    private Logger log = Logger.getLogger(HlmFinalTargetDef.class);

    /**
     * This post action will execute the final target if any to be executed.
     * 
     * @param prj
     * @param module
     * @param targetNames
     * 
     */
    @SuppressWarnings("unchecked")
    public void executeOnPostBuild(Project project, String[] targetNames) {
        String finalTargetName = project.getProperty("hlm.target.final");
        log.debug("Calling final target : " + finalTargetName);
        if (finalTargetName != null) {
            // verify the target exists.
            Hashtable targets = project.getTargets();
            Target finalTarget = (Target) targets.get(finalTargetName);
            if (finalTarget == null) {
                log.info("The final target : " + finalTargetName
                        + " not available skipping");
                return;
            }
            // let's the project execute the target.
            project.executeTarget(finalTargetName);
        }
    }
}