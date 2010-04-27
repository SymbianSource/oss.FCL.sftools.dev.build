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
package com.nokia.helium.antunit.ant.types;

import java.util.ArrayList;
import java.util.List;

import org.apache.ant.antunit.AntUnitListener;
import org.apache.ant.antunit.AssertionFailedException;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.DataType;


/**
 * The customListener type allows you to defines additional custom
 * listener to be run while running test. Each test are considered
 * as single build.
 * 
 * &lt;au:antunit&lt;
 *     .......
 *     &lt;hlm:customListener&lt;
 *         &lt;hlm:listener classname="org.apache.tools.ant.listener.XmlLogger" /&lt;
 *     &lt;/hlm:customListener&lt;
 * &lt;/au:antunit&lt;
 * 
 * @ant.type name="customListener" category="antunit"
 */
public class CustomListener extends DataType implements AntUnitListener {
    
    private Project currentProject;
    private List<Listener> listenerDefinitions = new ArrayList<Listener>();
    private List<BuildListener> listeners =  new ArrayList<BuildListener>();
    
    /**
     * Add an additional listener definition. 
     */
    public Listener createListener() {
        Listener listener = new Listener();
        listenerDefinitions.add(listener);
        return listener;
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void addError(String name, Throwable error) {
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void addFailure(String name, AssertionFailedException exception) {
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void endTest(String name) {
        for (BuildListener bl : listeners) {
            currentProject.removeBuildListener(bl);
            bl.buildFinished(new BuildEvent(currentProject));
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void endTestSuite(Project project, String name) {
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void setCurrentTestProject(Project project) {
        currentProject = project;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void setParentTask(Task task) {
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void startTest(String name) {
        listeners.clear();
        for (Listener l : listenerDefinitions) {
            BuildListener bl = l.instantiate();
            l.setProject(currentProject);
            if (bl != null) {
                listeners.add(bl);
                bl.buildStarted(new BuildEvent(currentProject));
                currentProject.addBuildListener(bl);
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void startTestSuite(Project project, String name) {
    }

    /**
     * This class defines a listener to add
     * to the AntUnit test. 
     */
    public class Listener extends DataType {
        
        private String className;
        
        /**
         * Defines the classname to use to instantiate the listener.
         * @param className
         * @ant.required
         */
        public void setClassname(String className) {
            this.className = className;
        }
        
        /**
         * Create a BuildListener instance based on the
         * classname.
         * @return a new BuildListener.
         */
        @SuppressWarnings("unchecked")
        public BuildListener instantiate() {
            if (className != null) {
                try {
                    Class<BuildListener> clazz = (Class<BuildListener>) Class.forName(className);
                    return clazz.newInstance();
                } catch (ClassNotFoundException e) {
                    log("ERROR: " + e.toString(), Project.MSG_ERR);
                } catch (InstantiationException e) {
                    log("ERROR: " + e.toString(), Project.MSG_ERR);
                } catch (IllegalAccessException e) {
                    log("ERROR: " + e.toString(), Project.MSG_ERR);
                }
            }
            return null;
        }
        
    }
}
