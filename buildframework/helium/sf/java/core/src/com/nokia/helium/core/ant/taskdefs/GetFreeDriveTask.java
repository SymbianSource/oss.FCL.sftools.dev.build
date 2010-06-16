/*
 * Copyright (c) 2010-2011 Nokia Corporation and/or its subsidiary(-ies).
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

package com.nokia.helium.core.ant.taskdefs;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import java.io.File;
import org.apache.tools.ant.taskdefs.condition.Os;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Returns Next Free Drive available to use
 * 
 * <pre>
 * Usage: &lt;hlm:getfreedrive property="build.drive"/&gt;
 * </pre>
 * @ant.task name="getfreedrive" category="Core"
 */
public class GetFreeDriveTask extends Task {
    // property to set with the available drive
    private String property;

    /**
     * To find the free drives available to use
     * 
     * @return First free drive available
     */
    private String getNextFreeDrive() {
        List<File> drives = new ArrayList<File>(Arrays.asList(File.listRoots()));
        for (char i = 'Z'; i >= 'A'; i--) {
            File file = new File(i + ":" + File.separator);
            if (!drives.contains(file)) {
                return i + ":";
            }
        }
        return null;
    }

    /**
     * Name of the property to be set.
     * 
     * @param property
     *            the property name
     * @ant.required
     */
    public void setProperty(String property) {
        this.property = property;
    }

    @Override
    public void execute() {
        if (property == null) {
            throw new BuildException("'property' attribute is not defined");
        }
        if (!Os.isFamily(Os.FAMILY_WINDOWS)) {
            throw new BuildException("Task getfreedrive is supported only on windows");
        }
        String returnValue = getNextFreeDrive();
        if (returnValue != null) {
            getProject().setNewProperty(property, returnValue);
        }
        else {
            throw new BuildException("No free drive available");
        }
            
        
    }
}
