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

import java.util.StringTokenizer;
import java.util.Vector;
import java.util.Enumeration;
import java.util.List;
import java.io.BufferedReader;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.JarURLConnection;
import java.net.URL;
import java.util.ArrayList;

import org.apache.tools.ant.taskdefs.ImportTask;
import org.apache.tools.ant.helper.DefaultExecutor;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.Location;
import com.nokia.helium.core.ant.types.*;

import java.util.HashMap;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import org.apache.log4j.Logger;

/**
 * This class implements a flexible Ant Executor which allows dynamic discovery
 * and automatic loading of new features. It also supports pre/post actions to
 * be executed.
 */
public class HeliumExecutor extends DefaultExecutor {
    private HashMap<String, Vector<HlmDefinition>> preOperations = new HashMap<String, Vector<HlmDefinition>>();
    private HashMap<String, Vector<HlmDefinition>> postOperations = new HashMap<String, Vector<HlmDefinition>>();
    private HashMap<String, Vector<HlmExceptionHandler>> exceptionHandlers = new HashMap<String, Vector<HlmExceptionHandler>>();
    private Project project;
    private Logger log = Logger.getLogger(HeliumExecutor.class);

    /**
     * Override the default Ant executor.
     * 
     * @param project
     *            Object of the project
     * @param targetNames
     *            Array of target names to execute
     * 
     */
    public void executeTargets(Project project, String[] targetNames) {
        this.project = project;
        log.debug("Running executeTargets");
        BuildException failure = null;
        try {
            loadModules(project);
            doOperations(preOperations, project, targetNames);
            super.executeTargets(project, targetNames);
        } catch (BuildException e) {
            // Saving current issue
            // We are Ignoring the errors as no need to fail the build.
            failure = e;
        }

        try {
            doOperations(postOperations, project, targetNames);
        } catch (BuildException e) {
            // Treating possible new issues...
            if (failure != null) {
                failure = new BuildException(e.toString() + failure.toString());
            } else {
                failure = e;
            }
        }
        // Propagating any raised issues.
        if (failure != null) {
            handleExceptions(project, failure);
            throw failure;
        }
    }

    /**
     * Loading all the discovered modules.
     * 
     * @param module
     * @param prj
     */
    private void loadModules(Project prj) {
        List<File> moduleList = loadAvailableModules();
        for (File moduleName : moduleList) {
            loadModule(moduleName, prj);
        }
    }

    /**
     * Load a specific module.
     * 
     * @param moduleLib
     * @param prj
     */
    private void loadModule(File moduleLib, Project prj) {
        String file = getHlmAntLibFile(moduleLib);
        if (file == null) {
            return;
        }
        log.debug("Loading " + moduleLib.getName());
        ImportTask task = new ImportTask();
        Target target = new Target();
        target.setName("");
        target.setProject(prj);
        task.setOwningTarget(target);
        task.setLocation(new Location(file));
        task.setFile(file);
        task.setProject(prj);
        task.execute();
        String moduleName = getModuleName(moduleLib);
        Object refObject = prj.getReference(moduleName + ".list");

        if (refObject == null) {
            log.debug(moduleName + ".list not found");
        }
        if (refObject != null && refObject instanceof HlmDefList) {
            HlmDefList defList = (HlmDefList) refObject;
            Vector<HlmDefinition> tempDefList = new Vector<HlmDefinition>(
                    defList.getPreDefList());
            if (tempDefList != null) {
                preOperations.put(moduleName, tempDefList);
            }
            Vector<HlmDefinition> tempPostDefList = new Vector<HlmDefinition>(
                    defList.getPostDefList());
            if (tempPostDefList != null) {
                postOperations.put(moduleName, tempPostDefList);
            }
            Vector<HlmExceptionHandler> tempExceptionDefList = defList
                    .getExceptionHandlerList();
            if (tempExceptionDefList != null) {
                exceptionHandlers.put(moduleName, tempExceptionDefList);
            }
            log.debug("loadModule:pre-opsize"
                    + preOperations.size());
            log.debug("loadModule:post-opsize"
                    + postOperations.size());
            log.debug("loadModule:exception-opsize"
                    + exceptionHandlers.size());
            log.debug("Checking " + moduleLib);
        }
    }

    /**
     * Search for helium.antlib.xml under the module Jar.
     * 
     * @param moduleLib
     * @return
     * @throws IOException
     */
    protected URL findHeliumAntlibXml(File moduleLib) throws IOException {
        JarFile jarFile = new JarFile(moduleLib);
        Enumeration<JarEntry> jee = jarFile.entries();
        while (jee.hasMoreElements()) {
            JarEntry je = jee.nextElement();
            if (je.getName().endsWith("/helium.antlib.xml")) {
                return new URL("jar:" + moduleLib.toURI().toString() + "!/"
                        + je.getName());
            }
        }
        return null;
    }

    /**
     * Retrieve the found helium.antlib.xml. TODO improve if possible without
     * extracting the file.
     * 
     * @param moduleLib
     * @return
     */
    private String getHlmAntLibFile(File moduleLib) {
        log.debug("[HeliumExecutor] Checking " + moduleLib);
        try {
            URL url = findHeliumAntlibXml(moduleLib);
            if (url == null)
                return null;
            log.debug("Getting " + url);

            JarURLConnection jarConnection = (JarURLConnection) url
                    .openConnection();
            JarEntry jarEntry = jarConnection.getJarEntry();
            JarFile jarFile = new JarFile(moduleLib);
            InputStream is = jarFile.getInputStream(jarEntry);
            InputStreamReader isr = new InputStreamReader(is);
            BufferedReader reader = new BufferedReader(isr);
            File file = File.createTempFile("helium", "antlib.xml");
            file.deleteOnExit();
            FileWriter writer = new FileWriter(file);
            String line;
            while ((line = reader.readLine()) != null) {
                writer.write(line + "\n");
            }
            writer.close();
            reader.close();
            log.debug("Temp file " + file.getAbsolutePath());
            return file.getAbsolutePath();
        } catch (Exception ex) {
            log.error("Error: " + ex.getMessage(), ex);
            return null;
        }
    }

    private void doOperations(
            HashMap<String, Vector<HlmDefinition>> operations, Project prj,
            String[] targetNames) {
        log.debug("doOperations: start");
        for (String moduleName : operations.keySet()) {
            log.debug("doOperations: module" + moduleName);
            for (HlmDefinition definition : operations.get(moduleName)) {
                definition.execute(prj, moduleName, targetNames);
            }
        }
    }

    private void handleExceptions(Project prj, Exception e) {
        for (String moduleName : this.exceptionHandlers.keySet()) {
            log.debug("handleExceptions: module" + moduleName);
            for (HlmExceptionHandler exceptionHandler : this.exceptionHandlers
                    .get(moduleName)) {
                exceptionHandler.handleException(prj, moduleName, e);
            }
        }
    }

    private String getModuleName(File moduleLib) {
        String name = moduleLib.getName();
        return name.substring(0, name.lastIndexOf('.'));
    }

    private List<File> loadAvailableModules() {
        List<File> moduleList = new ArrayList<File>();
        String classpathString = System.getProperty("java.class.path");
        StringTokenizer tokenizier = new StringTokenizer(classpathString,
                File.pathSeparator);
        String token;
        while (tokenizier.hasMoreTokens()) {
            token = (String) tokenizier.nextToken();
            if (new File(token).isFile() && token.endsWith(".jar")) {
                moduleList.add(new File(token));
            }
        }
        return moduleList;
    }

    protected Project getProject() {
        return project;
    }
}