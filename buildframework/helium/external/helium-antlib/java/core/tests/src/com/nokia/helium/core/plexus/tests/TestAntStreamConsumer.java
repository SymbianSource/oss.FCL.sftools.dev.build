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
package com.nokia.helium.core.plexus.tests;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.taskdefs.Echo;
import org.junit.Test;
import static org.junit.Assert.*;
import com.nokia.helium.core.plexus.AntStreamConsumer;

public class TestAntStreamConsumer {

    public class AntBuildListener implements BuildListener {
        private StringBuffer log = new StringBuffer();
        
        public StringBuffer getLog() {
            return log;
        }

        @Override
        public void buildFinished(BuildEvent arg0) {
        }

        @Override
        public void buildStarted(BuildEvent arg0) {
        }

        @Override
        public void messageLogged(BuildEvent arg0) {
            log.append(arg0.getMessage());
        }

        @Override
        public void targetFinished(BuildEvent arg0) {
        }

        @Override
        public void targetStarted(BuildEvent arg0) {
        }

        @Override
        public void taskFinished(BuildEvent arg0) {
        }

        @Override
        public void taskStarted(BuildEvent arg0) {
        }
        
    }
    
    @Test
    public void testLoggingThroughAnt() {
        // Setting up an Ant task
        Project project = new Project();
        AntBuildListener listener = new AntBuildListener();
        project.addBuildListener(listener);
        project.init();
        Echo echo = new Echo();
        echo.setProject(project);
        echo.setMessage("From the echo task");
        
        
        // Configuring the Ant consumer
        AntStreamConsumer consumer = new AntStreamConsumer(echo);
        consumer.consumeLine("consumed line!");
        echo.execute();
        assertTrue(listener.getLog().toString().contains("From the echo task"));
        assertTrue(listener.getLog().toString().contains("consumed line!"));
        
    }

    @Test
    public void testLoggingThroughAntAsError() {
        // Setting up an Ant task
        Project project = new Project();
        AntBuildListener listener = new AntBuildListener();
        project.addBuildListener(listener);
        project.init();
        Echo echo = new Echo();
        echo.setProject(project);
        echo.setMessage("From the echo task");
        
        
        // Configuring the Ant consumer
        AntStreamConsumer consumer = new AntStreamConsumer(echo, Project.MSG_ERR);
        consumer.consumeLine("consumed line!");
        echo.execute();
        assertTrue(listener.getLog().toString().contains("From the echo task"));
        assertTrue(listener.getLog().toString().contains("consumed line!"));
        
    }
    
    
}
