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
package com.nokia.helium.sysdef.ant.taskdefs;

import java.io.File;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;

import com.nokia.helium.core.FileUtils;

/**
 * Utility class to access the system definition tools.
 *
 */
public final class SysdefUtils {
    public static final String SYSDEF_HOME_PROPERTY_NAME = "sysdef.tools.home";
    private static final String ASSET_PATH = "sf/os/buildtools/bldsystemtools/sysdeftools";
    
    private SysdefUtils() {        
    }
    
    /**
     * Get the location of the the system definitions tools.
     * Use the SYSDEF_HOME_PROPERTY_NAME if it is defined.
     * Else it tries to search the joinsysdef script on the path,
     * and finally falls back on the ASSET_PATH location.
     * @param project the current Ant project.
     * @param epocroot the epocroot location.
     * @return a directory represented by a File object.
     */
    public static File getSysdefHome(Project project, File epocroot) {
        if (project.getProperty(SYSDEF_HOME_PROPERTY_NAME) != null) {
            File dir = new File(project.getProperty(SYSDEF_HOME_PROPERTY_NAME)).getAbsoluteFile();
            if (dir.exists() && dir.isDirectory()) {
                return dir;
            } else {
                throw new BuildException("The " + SYSDEF_HOME_PROPERTY_NAME +
                        " property refers to an invalid directory: " + dir);
            }
        } else {
            File dir = FileUtils.findExecutableOnPath("joinsysdef");
            if (dir != null) {
                return dir.getParentFile();
            }
            // last resorts the asset location...
            dir = new File(epocroot, ASSET_PATH);
            if (!dir.exists() || !dir.isDirectory()) {
                throw new BuildException("Could not find system definition tools home.");
            }
            return dir;
        }
    }
    
}
