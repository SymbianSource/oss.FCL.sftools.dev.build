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

package com.nokia.helium.sbs.ant.taskdefs;

import java.util.List;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import com.nokia.helium.sbs.ant.types.*;
import com.nokia.helium.sbs.ant.*;
import org.apache.log4j.Logger;

public class GetSBSInputs extends Task {

    private Logger log = Logger.getLogger(GetSBSInputs.class);
    private String configName;
    private String outputProperty;
    

    public void setConfig(String name) {
        configName = name;
    }

    public void setOutputProperty(String property) {
        outputProperty = property;
    }

    /**
     *  Execute the task. Set the property with number of severities.  
     * @throws BuildException
     */
    public void execute() {
        if (configName == null) {
            throw new BuildException("configInput is not defined");
        }
        List<SBSInput> sbsInputList = SBSBuildList.getSBSInputList(getProject(), configName);
        StringBuffer inputs = new StringBuffer();
        for (SBSInput input : sbsInputList) {
            if (inputs.length() > 0) {
                inputs.append(",");
            }
            inputs.append(input.getRefid().getRefId());
            getProject().setProperty(outputProperty,inputs.toString());
        }
    }
}