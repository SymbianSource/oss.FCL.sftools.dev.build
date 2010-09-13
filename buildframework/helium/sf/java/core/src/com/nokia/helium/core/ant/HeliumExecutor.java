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
package com.nokia.helium.core.ant;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.BuildLogger;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.ProjectHelper;
import org.apache.tools.ant.helper.DefaultExecutor;

import com.nokia.helium.core.MultiCauseBuildException;
import com.nokia.helium.core.ant.types.HlmDefList;

/**
 * This class implements a flexible Ant Executor which allows dynamic discovery
 * and automatic loading of new features. It also supports pre/post actions to
 * be executed.
 * 
 */
public class HeliumExecutor extends DefaultExecutor {

    private static final String HELP_TARGET = "help";

    private List<HlmDefList> hlmDefCache = new ArrayList<HlmDefList>();
    private MultiCauseBuildException failure;

    /**
     * Execute the specified Targets for the specified Project.
     * 
     * @param project
     *            the Ant Project.
     * @param targetNames
     *            String[] of Target names.
     * @throws BuildException
     *             on error
     */
    public void executeTargets(Project project, String[] targetNames) {
        if (targetNames.length > 1 && targetNames[0].equals(HELP_TARGET)) {
            displayHelp(project, targetNames);
        } else {
            executeRegularTargets(project, targetNames);
        }
    }

    /**
     * Execute the given targets.
     * 
     * @param project
     *            is the ant project
     * @param targetNames
     *            array of target names to be executed.
     */
    public void executeRegularTargets(Project project, String[] targetNames) {
        project.log("Running executeTargets", Project.MSG_DEBUG);
        loadModules(project);
        handlePreBuildActions(project, targetNames);
        try {
            super.executeTargets(project, targetNames);
        } catch (BuildException be) {
            recordFailure(be);
        } finally {
            handlePostBuildActions(project, targetNames);
            // Propagating any raised issues.
            handleException(project);
        }
    }

    /**
     * Method loads all the available helium modules from the system classpath.
     * 
     * @param project
     *            is the ant project.
     */
    @SuppressWarnings("unchecked")
    private void loadModules(Project project) {
        try {
            List<URL> modules = getAvailableModules();
            project.log("Total no of modules available : " + modules.size(), Project.MSG_DEBUG);
            for (URL module : modules) {
                loadModule(project, module);
            }
            Map<String, Object> references = (Hashtable<String, Object>)project.getReferences();
            for (String key : references.keySet()) {
                Object refObj = references.get(key);
                if (refObj instanceof HlmDefList) {
                    hlmDefCache.add((HlmDefList)refObj);
                    project.log("Total pre build actions : "
                            + ((HlmDefList)refObj).getPreBuildActions().size(), Project.MSG_DEBUG);
                    project.log("Total post build actions : "
                            + ((HlmDefList)refObj).getPostBuildActions().size(), Project.MSG_DEBUG);
                    project.log("Total exception handlers : "
                            + ((HlmDefList)refObj).getExceptionHandlers().size(), Project.MSG_DEBUG);
                }
            }            
        } catch (BuildException be) {
            recordFailure(be);
        }
    }

    /**
     * Returns a list of available helium modules from the system classpath.
     * 
     * @return a list of helium module files.
     */
    private List<URL> getAvailableModules() {
        List<URL> moduleList = new ArrayList<URL>();
        String classpathString = System.getProperty("java.class.path");
        String[] modules = classpathString.split(File.pathSeparator);
        File module = null;
        URL url = null;
        for (String moduleName : modules) {
            module = new File(moduleName);
            if (module != null && module.isFile()
                    && module.getName().endsWith(".jar")) {
                try {
                    String hlmAntlibXmlFile = findHeliumAntlibXml(new JarFile(
                            module));
                    if (hlmAntlibXmlFile != null) {
                        url = new URL("jar:" + module.toURI().toString() + "!/"
                                + hlmAntlibXmlFile);
                        moduleList.add(url);
                    }
                } catch (MalformedURLException me) {
                    throw new BuildException(
                            "Error occured while getting helium module "
                                    + module + " : ", me);
                } catch (IOException ioe) {
                    throw new BuildException("Error reading file " + module
                            + ": " + ioe.getMessage(), ioe);
                }
            }
        }
        return moduleList;
    }

    /**
     * Search for helium.antlib.xml under the module Jar.
     * 
     * @param jarFile
     *            is the jar to be searched in.
     * @return the helium.antlib.xml
     */
    private String findHeliumAntlibXml(JarFile jarFile) {
        String hlmAntlibXmlFile = null;
        for (Enumeration<JarEntry> jarEntries = jarFile.entries(); jarEntries
                .hasMoreElements();) {
            JarEntry je = jarEntries.nextElement();
            if (je.getName().endsWith("/helium.antlib.xml")) {
                hlmAntlibXmlFile = je.getName();
                break;
            }
        }
        return hlmAntlibXmlFile;
    }

    /**
     * Method loads the specified module .
     * 
     * @param project
     *            is the ant project.
     * @param module
     *            the helium module to be loaded.
     */
    private void loadModule(Project project, URL module) {
        project.log("Loading module : " + module.toString(), Project.MSG_DEBUG);
        ProjectHelper helper = (ProjectHelper) project
                .getReference(ProjectHelper.PROJECTHELPER_REFERENCE);
        helper.parse(project, module);
    }

    /**
     * Method handles all the pre build events.
     * 
     * @param project
     *            is the ant project.
     * @param targets
     *            an array of target names.
     */
    private void handlePreBuildActions(Project project, String[] targets) {
        for (HlmDefList hlmDefList : hlmDefCache) {
            for (PreBuildAction event : hlmDefList.getPreBuildActions()) {
                try {
                    event.executeOnPreBuild(project, targets);
                } catch (BuildException be) {
                    // Saving current issue
                    // We are Ignoring the errors as no need to fail the build.
                    recordFailure(be);
                }
            }
        }
    }

    /**
     * Method handles all the post build events.
     * 
     * @param project
     *            is the ant project.
     * @param targets
     *            an array of target names.
     */
    private void handlePostBuildActions(Project project, String[] targets) {
        for (HlmDefList hlmDefList : hlmDefCache) {
            for (PostBuildAction event : hlmDefList.getPostBuildActions()) {
                try {
                    event.executeOnPostBuild(project, targets);
                } catch (BuildException be) {
                    // Treating possible new issues...
                    recordFailure(be);
                }
            }
        }
    }

    /**
     * Records a build failure.
     * 
     * @param be
     *            a build failure.
     */
    private void recordFailure(BuildException be) {
        if (failure == null) {
            failure = new MultiCauseBuildException();
        }
        failure.add(be);
    }

    /**
     * Method handles the recored build failures if any.
     * 
     * @param project
     *            is the ant project.
     */
    private void handleException(Project project) {
        if (failure != null) {
            for (HlmDefList hlmDefList : hlmDefCache) {
                for (HlmExceptionHandler handler : hlmDefList
                        .getExceptionHandlers()) {
                    try {
                        handler.handleException(project, failure);
                    } catch (BuildException be) {
                        // Treating possible new issues...
                        recordFailure(be);
                    }
                }
            }
            throw failure;
        }
    }

    @SuppressWarnings("unchecked")
    private void displayHelp(Project project, String[] targetNames) {
        if (targetNames.length > 1) {
            project.setProperty("help.item", targetNames[1]);
        }
        // Set Emacs mode to true for all listeners, so that help text does
        // not have [echo] at the start of each line
        Iterator<BuildListener> iter = project.getBuildListeners().iterator();
        while (iter.hasNext()) {
            BuildListener listener = iter.next();
            if (listener instanceof BuildLogger) {
                BuildLogger logger = (BuildLogger) listener;
                logger.setEmacsMode(true);
            }
        }
        // Run the 'help' target
        project.executeTarget(HELP_TARGET);
    }
}
