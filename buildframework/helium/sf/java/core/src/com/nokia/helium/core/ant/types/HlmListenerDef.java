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

import java.util.Vector;

import org.apache.tools.ant.BuildEvent;
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
    private boolean preappend;

    /**
     * The classname of the BuildListener to instantiate and register
     * to the project..
     * @param preappend
     */
    public void setClassname(String classname) {
        this.classname = classname;
    }
    
    /**
     * Defines if the listener should be added at the end of 
     * the list or always appended at the beguining of the list
     * just after the logger.
     * @param preappend
     */
    public void setPreappend(boolean preappend) {
        this.preappend = preappend;
    }
    
    /**
     * Register given listener to the project.
     */
    @SuppressWarnings("unchecked")
    public void executeOnPreBuild(Project project, String[] targetNames) {
        if (classname == null) {
            throw new BuildException("classname attribute has not been defined.");
        }
        try {
            Class<?> listenerClass = Class.forName(classname);
            BuildListener listener = (BuildListener) listenerClass
                    .newInstance();
            
            if (preappend) {
                Vector<BuildListener> listeners = (Vector<BuildListener>)project.getBuildListeners();
                for (BuildListener removeListener : listeners) {
                    project.removeBuildListener(removeListener);
                }
                // Always add the listener as after the first element which should be
                // the logger.
                if (listeners.size() > 0) {
                    listeners.add(1, listener);
                } else {
                    // this is really unlikely to happen
                    listeners.add(listener);
                }
                for (BuildListener addListener : listeners) {
                    project.addBuildListener(addListener);
                }
                
            } else {
                project.addBuildListener(listener);                
            }
            // Trigger that build has started under the listener,
            // so initialization could happen.
            listener.buildStarted(new BuildEvent(project));
            log(classname + " is registered", Project.MSG_DEBUG);
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