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

package com.nokia.helium.sbs.ant;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.BuildException;
import java.util.Hashtable;
import java.util.List;
import java.util.HashMap;
import com.nokia.helium.sbs.ant.types.*;
import com.nokia.helium.sbs.ant.taskdefs.*;
import org.apache.log4j.Logger;

/**
 * This is the final class to store the sbs build list across the ant configurations.
 */
public final class SBSBuildList {

    private static HashMap<Object, SBSBuild> sbsBuildMap;

    private static Logger log = Logger.getLogger(SBSBuildList.class);

    private SBSBuildList() {
    }
    
    /**
     *  Provides the list of sbsinput for the given configuration name. Process
     *  all the sbs input and returns the sbsinputlist for matchin configuration name
     *  from the ant xml file.
     * @param project, ant project for whcih the sbs config needs to be searched for.
     * @param buildName - name of the configuration for which the sbs input list needs
     * to be obtained.
     * @return list of sbs input for which the raptor needs to be executed one after another.
     */
    public static List<SBSInput> getSBSInputList(Project project, String buildName) {
        if (sbsBuildMap == null) {
            initialize(project);
        }
        SBSBuild sbsBuild = sbsBuildMap.get(buildName);
        if (sbsBuild == null) {
            throw new BuildException("Config name : " + buildName + " is not valid");
        }
        List<SBSInput> retList = null;
        if (sbsBuild != null) {
            retList = sbsBuild.getSBSInputList();
        }
        return retList;
    }

    /**
     *  Internal function to initialize the sbsbuild configuration to the hashmap.
     * @param project, ant project for whcih the sbs config needs to be searched for.
     */
    private static void initialize(Project project) {
        Hashtable references = project.getReferences();
        sbsBuildMap = new HashMap<Object, SBSBuild>();
        for (Object key : references.keySet()) {
            Object sbsBuildObject = references.get(key);
            if ( sbsBuildObject != null && sbsBuildObject instanceof SBSBuild) {
                sbsBuildMap.put(key, (SBSBuild)sbsBuildObject);
            }
        }
    }
}