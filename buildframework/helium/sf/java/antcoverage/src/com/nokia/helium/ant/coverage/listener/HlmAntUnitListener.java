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
package com.nokia.helium.ant.coverage.listener;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Map;

import org.apache.ant.antunit.listener.BaseAntUnitListener;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.ProjectHelper;
import org.apache.tools.ant.Target;

import com.nokia.helium.ant.coverage.AntMacros;
import com.nokia.helium.ant.coverage.AntScriptDefs;
import com.nokia.helium.ant.coverage.AntTargets;

import freemarker.cache.ClassTemplateLoader;
import freemarker.template.Configuration;
import freemarker.template.Template;
import freemarker.template.TemplateException;

/**
 * Helium antunit listener. This listener will collect the information of test
 * targets run and feeds the information into ParseTestFiles to get the tested
 * targets, macros and scriptdefs information.
 */

public class HlmAntUnitListener extends BaseAntUnitListener {
    private static final String NEW_LINE = System.getProperty("line.separator");
    private OutputStream out;
    private AntTargets antTargets;
    private AntMacros antMacro;
    private AntScriptDefs antScriptDef;
    private PrintWriter wri;
    private StringWriter inner;
    private File outputFile;

    /**
     * Default constructor.
     */
    public HlmAntUnitListener() {
        super(new BaseAntUnitListener.SendLogTo(SendLogTo.ANT_LOG), "txt");
        antTargets = new AntTargets();
        antMacro = new AntMacros();
        antScriptDef = new AntScriptDefs();
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.apache.ant.antunit.AntUnitListener#endTest(java.lang.String)
     */
    @Override
    public void endTest(String target) {
    }

    /*
     * (non-Javadoc)
     * 
     * @see
     * org.apache.ant.antunit.AntUnitListener#endTestSuite(org.apache.tools.
     * ant.Project, java.lang.String)
     */
    @Override
    public void endTestSuite(Project testProject, String buildFile) {
        try {
            StringWriter ftlWriter = new StringWriter();
            Configuration cfg = new Configuration();
            Template template = null;
            cfg.setTemplateLoader(new ClassTemplateLoader(this.getClass(), ""));
            template = cfg.getTemplate("ant_coverage_report.txt.ftl");
            Map<String, Object> data = new Hashtable<String, Object>();
            data.put("target_percentage", (int)this.getTargetCoverage());
            data.put("target_testcases", antTargets.getExecutedCount());
            data.put("total_targets", antTargets.getCount());

            data.put("macros_percentage", (int)this.getMacroCoverage());
            data.put("macros_testcases", antMacro.getExecutedCount());
            data.put("total_macros", antMacro.getCount());

            data.put("scriptdefs_percentage", (int)this.getScriptDefCoverage());
            data.put("scriptdefs_testcases", antScriptDef.getExecutedCount());
            data.put("total_scriptdefs", antScriptDef.getCount());
            template.process(data, ftlWriter);

            if (getOutputFile() != null) {
                File outputFile = getOutputFile();
                if (!outputFile.getParentFile().exists()) {
                    outputFile.getParentFile().mkdirs();
                }
                OutputStreamWriter output = new OutputStreamWriter(
                        new FileOutputStream(getOutputFile()));
                output.append(ftlWriter.getBuffer().toString());
                output.close();
                output = new OutputStreamWriter(new FileOutputStream(outputFile
                        .getParentFile().toString()
                        + File.separator + "target.plot.property"));
                output.append("YVALUE=" + (int)this.getTargetCoverage());
                output.close();
                output = new OutputStreamWriter(new FileOutputStream(outputFile
                        .getParentFile().toString()
                        + File.separator + "macro.plot.property"));
                output.append("YVALUE=" + (int)this.getMacroCoverage());
                output.close();
                output = new OutputStreamWriter(new FileOutputStream(outputFile
                        .getParentFile().toString()
                        + File.separator + "scriptdef.plot.property"));
                output.append("YVALUE="
                        + (int)this.getScriptDefCoverage());
                output.close();
            } else {
                StringBuffer sb = new StringBuffer(NEW_LINE);
                sb.append(ftlWriter.getBuffer().toString());
                if (out != null) {
                    out.write(sb.toString().getBytes());
                    wri.close();
                    out.write(inner.toString().getBytes());
                    out.flush();
                }
            }
        } catch (IOException ioe) {
            throw new BuildException(ioe.getMessage(), ioe);
        } catch (TemplateException ftle) {
            throw new BuildException(ftle.getMessage(), ftle);
        } finally {
            close(out);
        }
    }

    /*
     * (non-Javadoc)
     * 
     * @see
     * org.apache.ant.antunit.listener.BaseAntUnitListener#startTestSuite(org
     * .apache.tools.ant.Project, java.lang.String)
     */
    public void startTestSuite(Project testProject, String buildFile) {
        inner = new StringWriter();
        wri = new PrintWriter(inner);
        out = getOut(buildFile);
        addTargets(testProject);
        addMacros(testProject);
        addScriptDefs(testProject);
    }

    /*
     * (non-Javadoc)
     * 
     * @see
     * org.apache.ant.antunit.listener.BaseAntUnitListener#startTest(java.lang
     * .String)
     */
    public void startTest(String target) {

    }

    /**
     * @param outputFile
     *            the outputFile to set
     */
    public void setOutputFile(File outputFile) {
        this.outputFile = outputFile;
    }

    /**
     * Returns the output file path.
     * 
     * @return
     */
    public File getOutputFile() {
        return outputFile;
    }

    /**
     * To add Ant targets.
     * 
     * @param project
     */
    @SuppressWarnings("unchecked")
    private void addTargets(Project project) {
        Hashtable<String, Target> projectTargets = project.getTargets();
        Enumeration<String> targetEnum = projectTargets.keys();
        while (targetEnum.hasMoreElements()) {
            String key = targetEnum.nextElement();            
            if (!isAntUnitTestTarget(key) && key.length() > 0) {
                antTargets.add((Target) projectTargets.get(key));
            }
        }
    }

    /**
     * To add Ant macros.
     * 
     * @param project
     */
    @SuppressWarnings("unchecked")
    private void addMacros(Project project) {
        Hashtable<String, Class> projectMacros = project.getTaskDefinitions();
        Enumeration<String> macrosEnum = projectMacros.keys();
        while (macrosEnum.hasMoreElements()) {
            String key = macrosEnum.nextElement();
            Class newTask = projectMacros.get(key);
            if (newTask.getName().equals(
                    "org.apache.tools.ant.taskdefs.MacroInstance")) {
                String macroName = ProjectHelper
                        .extractNameFromComponentName(key);
                if (macroName != null && !macroName.contains("assert")) {
                    antMacro.add(macroName);
                }
            }
        }
    }

    /**
     * To add Ant scriptdefs.
     * 
     * @param project
     */
    @SuppressWarnings("unchecked")
    private void addScriptDefs(Project project) {
        Hashtable<String, Class> projectMacros = project.getTaskDefinitions();
        Enumeration<String> scriptDefsEnum = projectMacros.keys();
        while (scriptDefsEnum.hasMoreElements()) {
            String key = scriptDefsEnum.nextElement();
            Class newTask = projectMacros.get(key);
            if (newTask
                    .getName()
                    .equals(
                            "org.apache.tools.ant.taskdefs.optional.script.ScriptDefBase")) {
                String scriptdefName = ProjectHelper
                        .extractNameFromComponentName(key);
                if (scriptdefName != null) {
                    antScriptDef.add(scriptdefName);
                }
            }
        }
    }

    /**
     * To get the Target covered percentage.
     * 
     * @param measure
     * @return
     */
    private float getTargetCoverage() {
        if (antTargets.getCount() == 0) {
            return 100;
        } else {
            return ((float)antTargets.getExecutedCount() / (float)antTargets
                    .getCount()) * 100;
        }
    }

    /**
     * To get Macros covered percentage.
     * 
     * @param measure
     * @return
     */
    private float getMacroCoverage() {
        if (antMacro.getCount() == 0) {
            return 100;
        } else {
            return ((float)antMacro.getExecutedCount() / (float)antMacro.getCount()) * 100;
        }
    }

    /**
     * To get ScriptDefs covered percentage.
     * 
     * @param measure
     * @return
     */
    private float getScriptDefCoverage() {
        if (antScriptDef.getCount() == 0) {
            return 100;
        } else {
            return ((float)antScriptDef.getExecutedCount() / (float)antScriptDef
                    .getCount()) * 100;
        }
    }

    /**
     * Listener for collecting the targets/tasks information. This listener will
     * collect from the targets which actually run by test projects.
     * 
     */
    private class AntListener implements BuildListener {

        @Override
        public void buildFinished(BuildEvent event) {
        }

        @Override
        public void buildStarted(BuildEvent event) {
        }

        @Override
        public void messageLogged(BuildEvent event) {
        }

        @Override
        public void targetFinished(BuildEvent event) {
        }

        @Override
        public void targetStarted(BuildEvent event) {
            String targetName = event.getTarget().getName();
            if (!isAntUnitTestTarget(targetName) && targetName.length() > 0) {
                antTargets.markAsExecuted(targetName);
            }

        }

        @Override
        public void taskFinished(BuildEvent event) {

        }

        @Override
        public void taskStarted(BuildEvent event) {
            // macro and scriptdef are creating UnknownElement type of tasks
            if (event.getTask().getTaskType() != null) {
                String taskName = ProjectHelper
                        .extractNameFromComponentName(event.getTask()
                                .getTaskType());
                if (taskName != null) {
                    antMacro.markAsExecuted(taskName);
                    antScriptDef.markAsExecuted(taskName);
                }
            }
        }
    }

    /*
     * (non-Javadoc)
     * 
     * @see
     * org.apache.ant.antunit.listener.BaseAntUnitListener#setCurrentTestProject
     * (org.apache.tools.ant.Project)
     */
    @Override
    public void setCurrentTestProject(Project p) {
        p.addBuildListener(new AntListener());
    }
    
    /**
     * Check is the target is a special name for AntUnit.
     * @param targetName
     * @return
     */
    public static boolean isAntUnitTestTarget(String targetName) {
        if (targetName == null) {
            return false;
        }
        if ((targetName.startsWith("test") && !targetName.equals("test"))
            || targetName.equals("setUp") || targetName.equals("tearDown")) {
            return true;
        }
        return false;
    }
}
