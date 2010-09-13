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

import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.PreBuildAction;

/**
 * This class implements a listener registration action.
 * 
 * @ant.type name="listenerdef" category="Core"
 */
public class HlmListenerDef extends DataType implements PreBuildAction {

    private String classname;
    private Logger log = Logger.getLogger(HlmListenerDef.class);

    public void setClassname(String classname) {
        this.classname = classname;
    }

    /**
     * Register given listener to the project.
     */
    public void executeOnPreBuild(Project project, String[] targetNames) {
        try {
            Class<?> listenerClass = Class.forName(classname);
            BuildListener listener = (BuildListener) listenerClass
                    .newInstance();
            project.addBuildListener(listener);
            log.debug(classname + " is registered");
        } catch (ClassNotFoundException ex) {
            throw new BuildException("Class not found exception:"
                    + ex.getMessage(), ex);
        } catch (InstantiationException ex1) {
            throw new BuildException("Class Instantiation exception:"
                    + ex1.getMessage(), ex1);
        } catch (IllegalAccessException ex1) {
            throw new BuildException("Illegal Class Access exception:"
                    + ex1.getMessage(), ex1);
        }
    }
}