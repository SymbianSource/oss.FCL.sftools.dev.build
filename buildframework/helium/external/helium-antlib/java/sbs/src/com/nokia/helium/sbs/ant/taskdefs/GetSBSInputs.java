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

/**
 * This task provide a way to get the list of sbs command input for a particular
 * configuration from abld. For every abld command mentioned for a configuration 
 * from schema 1.4.0, there should be a corresponding sbsinput and for all
 * abld commands in the sysdef configuration a corresponding sbsbuild command has
 * to be there. And using this task the list of sbs commands are extracted and executed 
 * one after another. This is only for backward compatibility, once the sysdef config
 * is migrated to 3.0, this task would be deprecated.
 * 
 * This is internal task and should not be used outside helium.
 * 
 * <pre>
 * Example 1:
 * &lt;getsbsinputs config=&quot;sysdef.configuration&quot;
 *      outputProperty=&quot;sbs.internal.list&quot;/&gt;
 * </pre>
 * 
 * @ant.task name="getsbsinputs" category="SBS"
 */

public class GetSBSInputs extends Task {

    private Logger log = Logger.getLogger(GetSBSInputs.class);
    private String configName;
    private String outputProperty;
    
    /**
     *  Helper function to set the configuration name for
     *  which the sbs commands to be extracted.
     * @param name of the configuration for which sbs commands to be obtained.
     */
    public void setConfig(String name) {
        configName = name;
    }

    /**
     *  Helper function to retrive the sbs input list (list of sbs commands
     *  to be executed one after another). The list is provided with comma
     *  separated values.
     * @param property name of the property where the sbs input list to be stored.
     */
    public void setOutputProperty(String property) {
        outputProperty = property;
    }

    /**
     *  Execute the task. Finds the list of sbsinput and store it in
     *  outputproperty with comma separated values.
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