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

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.ant.data.AntFile;
import com.nokia.helium.ant.data.Database;
import com.nokia.helium.ant.data.ProjectMeta;
import com.nokia.helium.ant.data.PropertyCommentMeta;
import com.nokia.helium.ant.data.PropertyMeta;
import com.nokia.helium.ant.data.RootAntObjectMeta;
import com.nokia.helium.ant.data.TargetMeta;
import com.nokia.helium.antlint.ant.AntlintException;
import com.nokia.helium.antlint.ant.Reporter;
import com.nokia.helium.antlint.ant.Severity;
import com.nokia.helium.antlint.ant.types.Check;
import com.nokia.helium.antlint.ant.types.CheckPropertyTypeAndValueMismatch;
import com.nokia.helium.core.ant.PostBuildAction;

/**
 * <code>PostBuildQualityCheckAction</code> is run as a post build action to report user
 * configurations related to Helium targets and properties usage.
 * 
 * <p>
 * This class currently reports following :
 * <ul>
 * <li>Use of deprecated Helium targets.</li>
 * <li>Use of private Helium targets.</li>
 * <li>Use of deprecated Helium properties.</li>
 * <li>Override of private Helium properties.</li>
 * <li>Invalid property types/values set for Helium properties</li>
 * </ul>
 * </p>
 */
public class PostBuildQualityCheckAction extends DataType implements PostBuildAction, Reporter {
    private static final String DEPRECATED = "deprecated:";
    private Set<String> output = new LinkedHashSet<String>();
    private String heliumPath;
    private Database publicScopeDb;
    private Database privateScopeDb;

    /**
     * Method logs a configuration report about usage of helium targets and
     * properties.
     * 
     * @param project Is the Ant project.
     * @param targetNames Is an array of target names.
     */
    public void executeOnPostBuild(Project project, String[] targetNames) {

        if (project.getProperty("helium.dir") != null) {
            try {
                setHeliumPath(new File(project.getProperty("helium.dir")).getCanonicalPath());
                publicScopeDb = new Database(project);
                privateScopeDb = new Database(project, "private");

                // Get list of targets which are called either by antcall or
                // runtarget
                List<String> antCallTargets = getAntCallTargets(project);
                checkDeprecatedHeliumTargets(antCallTargets, project);
                checkPrivateHeliumTargets(antCallTargets, project);

                // Get list of customer defined properties
                List<String> customerProps = getCustomerProperties(project);
                checkInvalidProperties(customerProps, project);
                checkOverriddenProperties(customerProps, project);
                checkDeprecatedProperties(customerProps, project);

                if (!output.isEmpty()) {
                    log("*** Configuration report ***", Project.MSG_INFO);
                    for (String outputStr : output) {
                        log(outputStr, Project.MSG_INFO);
                    }
                }
            } catch (IOException e) {
                log(e.getMessage(), Project.MSG_WARN);
            }
        } else {
            log("Configuration report cannot be generated because 'helium.dir' property is not defined.",
                    Project.MSG_VERBOSE);
        }
    }

    /**
     * Return the Helium path.
     * 
     * @return The helium path.
     */
    public String getHeliumPath() {
        return heliumPath;
    }

    /**
     * Set helium path.
     * 
     * @param heliumPath is the path to set
     */
    public void setHeliumPath(String heliumPath) {
        this.heliumPath = heliumPath;
    }
    
    /**
     * Method checks for incorrect values, set for boolean/integer type properties.
     * 
     * @param customerProps Is a list of customer defined properties
     * @param project Is the Ant project.
     */
    private void checkInvalidProperties(List<String> customerProps, Project project) {
        Check check = new CheckPropertyTypeAndValueMismatch();
        check.setReporter(this);
        check.setSeverity((Severity) Severity.getInstance(Severity.class, "warning"));
        for (AntFile antFile : privateScopeDb.getAntFiles()) {
            try {
                check.setAntFile(antFile);
                check.run();
            } catch (AntlintException aex) {
                log(aex.getMessage(), Project.MSG_WARN);
            }
        }
    }

    /**
     * Method checks for overridden of private scope helium properties.
     * 
     * @param customerProps A list of customer defined properties.
     * @param project Is the Ant project.
     */
    private void checkOverriddenProperties(List<String> customerProps, Project project) {
        for (PropertyMeta propertyMeta : privateScopeDb.getProperties()) {
            if (propertyMeta.getLocation().contains(getHeliumPath())
                    && propertyMeta.getScope().equals("private")
                    && customerProps.contains(propertyMeta.getName())) {
                output.add("Warning: " + propertyMeta.getName() + " property has been overridden");
            }
        }
        for (PropertyCommentMeta propertyCommentMeta : privateScopeDb.getCommentProperties()) {
            if (propertyCommentMeta.getLocation().contains(getHeliumPath())
                    && propertyCommentMeta.getScope().equals("private")
                    && customerProps.contains(propertyCommentMeta.getName())) {
                output.add("Warning: " + propertyCommentMeta.getName()
                        + " property has been overridden");
            }
        }
    }

    /**
     * Method checks for use of deprecated helium properties.
     * 
     * @param customerProps Is a list of customer defined properties.
     * @param project Is the Ant project.
     */
    private void checkDeprecatedProperties(List<String> customerProps, Project project) {
        // check for deprecated properties
        for (PropertyMeta propertyMeta : privateScopeDb.getProperties()) {
            if (propertyMeta.getLocation().contains(getHeliumPath())
                    && (!propertyMeta.getDeprecated().equals(""))
                    && customerProps.contains(propertyMeta.getName())) {
                output.add("Warning: "
                        + propertyMeta.getName()
                        + " property has been deprecated "
                        + propertyMeta.getDeprecated()
                        + "."
                        + propertyMeta.getSummary().substring(
                                propertyMeta.getSummary().lastIndexOf(DEPRECATED)
                                        + DEPRECATED.length()));
            }
        }

        for (PropertyCommentMeta propertyCommentMeta : privateScopeDb.getCommentProperties()) {
            if (propertyCommentMeta.getLocation().contains(getHeliumPath())
                    && (!propertyCommentMeta.getDeprecated().equals(""))
                    && customerProps.contains(propertyCommentMeta.getName())) {
                output.add("Warning: "
                        + propertyCommentMeta.getName()
                        + " property has been deprecated "
                        + propertyCommentMeta.getDeprecated()
                        + "."
                        + propertyCommentMeta.getSummary().substring(
                                propertyCommentMeta.getSummary().lastIndexOf(DEPRECATED)
                                        + DEPRECATED.length()));
            }
        }
    }

    /**
     * Method checks for use of deprecated helium targets.
     * 
     * @param antCallTargets A list of targets referred by antcall/runtarget.
     * @param project Is the Ant project
     */
    private void checkDeprecatedHeliumTargets(List<String> antCallTargets, Project project) {
        for (String targetName : antCallTargets) {
            TargetMeta targetMeta = getHeliumTarget(targetName, publicScopeDb);
            if (targetMeta != null && !targetMeta.getDeprecated().trim().isEmpty()) {
                output.add("Warning: " + targetMeta.getName() + " target has been deprecated. "
                        + targetMeta.getDeprecated() + ".");
            }
        }
        // check in dependencies
        for (TargetMeta targetMeta : publicScopeDb.getTargets()) {
            if (!targetMeta.getLocation().contains(getHeliumPath())) {
                List<String> dependencies = targetMeta.getDepends();
                for (String targetName : dependencies) {
                    TargetMeta tm = getHeliumTarget(targetName, publicScopeDb);
                    if (tm != null && !tm.getDeprecated().trim().isEmpty()) {
                        output.add("Warning: " + tm.getName() + " target has been deprecated. "
                                + tm.getDeprecated() + ".");
                    }
                }
            }
        }
    }

    /**
     * Method checks for the use of private helium targets.
     * 
     * @param antCallTargets A list of targets referred by antcall/runtarget.
     * @param project Is the Ant project.
     */
    private void checkPrivateHeliumTargets(List<String> antCallTargets, Project project) {
        for (TargetMeta targetMeta : privateScopeDb.getTargets()) {
            if (targetMeta.getLocation().contains(getHeliumPath())
                    && targetMeta.getScope().equals("private")
                    && antCallTargets.contains(targetMeta.getName())) {
                output.add("Warning: " + targetMeta.getName()
                        + " is private and should only be called by helium");
            }
        }
        // check in dependencies
        for (TargetMeta targetMeta : publicScopeDb.getTargets()) {
            if (!targetMeta.getLocation().contains(getHeliumPath())) {
                List<String> dependencies = targetMeta.getDepends();
                for (String targetName : dependencies) {
                    TargetMeta tm = getHeliumTarget(targetName, privateScopeDb);
                    if (tm != null && tm.getScope().equals("private")) {
                        output.add("Warning: " + tm.getName()
                                + " is private and should only be called by helium");
                    }
                }
            }
        }
    }

    /**
     * Method returns a list of targets referred by antcall/runtarget.
     * 
     * @param project Is the Ant project.
     * @return A list of targets referred by antcall/runtarget
     */
    private List<String> getAntCallTargets(Project project) {
        List<String> antCallTargets = new ArrayList<String>();
        List<AntFile> customerAntFiles = getCustomerAntFiles(project);
        for (AntFile antFile : customerAntFiles) {
            RootAntObjectMeta root = antFile.getRootObjectMeta();
            if (root instanceof ProjectMeta) {
                ProjectMeta projectMeta = (ProjectMeta) root;
                List<TargetMeta> targets = projectMeta.getTargets();
                for (TargetMeta targetMeta : targets) {
                    antCallTargets.addAll(targetMeta.getExecTargets());
                }
            }
        }
        return antCallTargets;
    }

    /**
     * Method returns a list of customer ant files.
     * 
     * @param project Is the Ant project.
     * @return A list of customer ant files.
     */
    private List<AntFile> getCustomerAntFiles(Project project) {
        List<AntFile> customerAntFiles = new ArrayList<AntFile>();
        try {
            for (AntFile antFile : publicScopeDb.getAntFiles()) {
                if (!antFile.getFile().getCanonicalPath().contains(getHeliumPath())) {
                    customerAntFiles.add(antFile);
                }
            }
        } catch (IOException e) {
            log("Unable to get a list of customer ant files. " + e.getMessage(), Project.MSG_WARN);
        }
        return customerAntFiles;
    }

    /**
     * Method returns a list of property names defined by customer.
     * 
     * @param project Is the Ant project.
     * @return A list of customer defined property names.
     */
    private List<String> getCustomerProperties(Project project) {
        List<String> customerProps = new ArrayList<String>();
        List<PropertyMeta> properties = publicScopeDb.getProperties();
        for (PropertyMeta propertyMeta : properties) {
            if (!propertyMeta.getLocation().contains(getHeliumPath())) {
                customerProps.add(propertyMeta.getName());
            }
        }
        return customerProps;
    }

    /**
     * Method returns target meta information of the target found in helium.
     * 
     * @param targetName Is the name of the target requested.
     * @param db Is the database to look in for the target information.
     * @return The requested target meta.
     */
    private TargetMeta getHeliumTarget(String targetName, Database db) {
        List<TargetMeta> targetList = db.getTargets();
        for (TargetMeta targetMeta : targetList) {
            if (targetMeta.getLocation().contains(getHeliumPath())
                    && targetMeta.getName().equals(targetName)) {
                return targetMeta;
            }
        }
        return null;
    }

    public void open() {
        // do nothing
    }

    public void close() {
        // do nothing
    }

    public void report(Severity severity, String message, File filename, int lineNo) {
        output.add("Warning: " + message);
    }

    public void setTask(Task task) {
        // do nothing
    }
}