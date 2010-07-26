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
package com.nokia.helium.core.ant.tests;

import java.io.File;

import junit.framework.TestCase;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.taskdefs.Echo;

import com.nokia.helium.core.ant.listener.TargetTimesLogGeneratorListener;

/**
 * Test class for TargetTimesGeneratorListener.
 * 
 */
public class TestTargetTimesLogGenerator extends TestCase {

    private Project project;
    private String timesLogFileName;

    /**
     * Method to setup project
     */
    protected void setUp() throws Exception {
        // create a temp dir to store csv file
        String path = System.getenv("TEMP");
        String buildId = "helium_" + System.getenv("USERNAME");
        timesLogFileName = path + File.separator + buildId
                + "_targetTimesLog.csv";
        project = new Project();
        project.setProperty("target.times.log.file", timesLogFileName);
        project.addBuildListener(new TargetTimesLogGeneratorListener());
        project.addTarget(constructTarget("foo", null));
        project.addTarget(constructTarget("woo", null));
        project.addTarget(constructTarget("moo", null));
        project.addTarget(constructTarget("hello", "foo,woo,moo"));
        project.setDefault("hello");
    }

    /**
     * Method returns a target.
     * 
     * @param targetName
     *            is the target to create.
     * @param depends
     *            is the list of dependent targets
     * @return a target
     */
    private Target constructTarget(String targetName, String depends) {
        Target target = new Target();
        target.setName(targetName);
        target.setProject(project);
        Echo echo = new Echo();
        echo.setMessage("Inside " + targetName);
        echo.setOwningTarget(target);
        echo.setProject(project);
        target.addTask(echo);
        if (depends != null) {
            target.setDepends(depends);
        }
        return target;
    }

    /**
     * Method to test the target times csv file generation.
     */
    public void testTargetTimesCsvFileGeneration() {
        if (project != null) {
            try {
                project.fireBuildStarted();
                project.init();
                project.executeTarget("hello");

            } finally {
                project.fireBuildFinished(null);
            }
        }
        assert new File(timesLogFileName).exists();
    }

    /**
     * Method to cleanup.
     */
    protected void tearDown() throws Exception {
        if (timesLogFileName != null) {
            File file = new File(timesLogFileName);
            if (file != null && file.exists()) {
                file.delete();
            }
        }
    }
}