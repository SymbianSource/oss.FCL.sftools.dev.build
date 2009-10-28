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
 
package com.nokia.tools.sbs;

import java.util.Vector;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Enumeration;
import com.nokia.ant.types.VariableSet;
import com.nokia.ant.types.SBSMakeOptions;
import com.nokia.ant.types.Variable;
import com.nokia.tools.*;
import org.apache.tools.ant.Project;
import java.util.Set;
import org.apache.tools.ant.taskdefs.ExecTask;
import org.apache.log4j.Logger;
import java.io.File;
import org.apache.tools.ant.types.Reference;
import org.w3c.dom.*;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import java.io.FileWriter;
import java.text.SimpleDateFormat;
import java.util.Date;

//import org.apache.tools.ant.types.Environment;
/**
 * Command Line wrapper for configuration tools
 */
public class SBSTool implements Tool {
    private final String prefix = "--mo=";
    private final String equalSign = "=";
    
    private Logger log;
    private String layers;
    private String config;
    private String skipBuild;
    private String singleJob;
    private String layerOrder;
    private String components;
    private String command;
    private String varName;
    private String sysdefBase;
    private String enableFilter;
    private String checkOption;
    private String whatOption;
    private String retryOption;
    private SimpleDateFormat timeFormat;
    private Date startTime;
    private Date endTime;
    
    
    public SBSTool() {
        log = Logger.getLogger(SBSTool.class);
        timeFormat = new SimpleDateFormat("HH:mm:ss");
        
    }
    /**
     * Sets the command line variables to be used to execute and validates 
     * for the required parameters (as Tool interface) 
     * @param VariableSet variable(name / value list)
     */    
    public void execute(VariableSet varSet, Project prj)throws ToolsProcessException {
        layers = null;
        config = null;
        skipBuild = null;
        singleJob = null;
        layerOrder = null;
        components = null;
        command = null;
        varName = null;
        String value = null;
        sysdefBase = null;
        enableFilter = null;
        checkOption = null;
        whatOption = null;
        retryOption = null;
        Vector configSet = varSet.getVariables();
        log.debug("SBSTool:configSet.size:" + configSet.size());
        Enumeration e = configSet.elements();
        Variable variable;
        while (e.hasMoreElements()) {
            variable = (Variable)e.nextElement();
            varName = variable.getName();
            value = variable.getValue();
            log.debug("SBSTool:varName:" + varName);
            log.debug("SBSTool:value:" + value);
            if (varName.equals("layers")) {
                layers = value;
            } else if (varName.equals("config")) {
                config = value;
            } else if (varName.equals("skipbuild")) {
                skipBuild = value;
            } else if (varName.equals("singlejob")) {
                singleJob = value;
            } else if (varName.equals("layer-order")) {
                layerOrder = value;
            } else if (varName.equals("command")) {
                command = value;
            } else if (varName.equals("components")) {
                components = value;
            } else if (varName.equals("sysdef-base")) {
                sysdefBase = value;
            } else if (varName.equals("enable-filter")) {
                enableFilter = value;
            } else if (varName.equals("run-check")) {
                checkOption = value;
            } else if (varName.equals("run-what")) {
                whatOption = value;
            } else if (varName.equals("retry-limit")) {
                retryOption = value;
            }
            
        }
        execTask(prj);
    }

    /**
     * Sets the command line variables to be used to execute and validates 
     * for the required parameters (as SBSTask) 
     * @param VariableSet variable(name / value list)
     */    
    public void execute(HashMap attributes, Project project)throws ToolsProcessException {
        layers = null;
        config = null;
        skipBuild = null;
        singleJob = null;
        layerOrder = null;
        command = null;
        components = null;
        sysdefBase = null;
        enableFilter = null;
        retryOption = null;
        String value = (String)attributes.get("layers");
        if ( value != null) {
            layers = value;
            System.out.println("layers:" + value);
        }
        value = (String)attributes.get("config");
        if (value != null) {
            config = value;
            System.out.println("config:" + value);
        }
        value = (String)attributes.get("skipbuild");
        if (value != null) {
            skipBuild = value;
            System.out.println("skipbuild:" + value);
        }
        value = (String)attributes.get("singlejob");
        if (value != null) {
            singleJob = value;
            System.out.println("singlejob:" + value);
        }
        value = (String)attributes.get("layer-order");
        if (value != null) {
            layerOrder = value;
            System.out.println("layer-order:" + value);
        }
        value = (String)attributes.get("command");
        if (value != null) {
            command = value;
            System.out.println("command:" + value);
        }
        value = (String)attributes.get("components");
        if (value != null) {
            components = value;
        }
        value = (String)attributes.get("sysdef-base");
        if (value != null) {
            sysdefBase = value;
        }
        value = (String)attributes.get("enable-filter");
        if (value != null) {
            enableFilter = value;
        } else if (varName.equals("retry")) {
            retryOption = value;
        }

        execTask(project);
    }
    
    /**
     * Task to execute the SBS command 
     * Updates all the default values for the command, in case
     * if the options are not provided. 
     * @param engine - make engine for sbs command
     * @param layers - layers for sbs commands has to be executed
     * @param config - configuration to be built (armv5 / winscw) 
     * @param singleJob - no. of concurrent jobs
     * @param layerOrder - whether the layer execution should be based on order
     * @param command - sbs make targets to execute(CLEAN, REALLYCLEAN, TARGET etc.,) 
     * @param prj - Ant project reference. 
     */    
    public void execTask(Project prj) throws ToolsProcessException {

        log.info("SBSTask:executing for SBS task");
        String partialLogPath = prj.getProperty("build.log.dir") + "/" + prj.getProperty("build.id");
        String sysdefConfig = prj.getProperty("sysdef.configuration");
        String sbsLogName = "";
        ExecTask task = new ExecTask();
        task.setTaskName("sbs");
        String osType = System.getProperty("os.name");
        log.debug("SBSTask:ostype:" + osType);
        if (osType.toLowerCase().startsWith("win")) {
            task.setExecutable("sbs.bat");
        } else {
            task.setExecutable("sbs");
        }
        task.setFailonerror(true);
        task.setDir(new java.io.File(prj.getProperty("build.drive") + "/"));
        log.debug("SBSTask:root dir:" + prj.getProperty("build.drive") + "/");
        task.createArg().setValue("-s");
        String sysdefFile = prj.getProperty("build.output.dir") + "/build/canonical_system_definition_" + sysdefConfig + ".xml";
        task.createArg().setValue(sysdefFile);
        if (layerOrder != null) {
            task.createArg().setValue("-o");
        }
        task.createArg().setValue("-k");
        sbsLogName += setLayerArgs(task);
        sbsLogName += setConfigArgs(task);
        Object makeOptReference = prj.getReference("sbs.internal.make.options");
        sbsLogName += updateSBSMakeOptions(makeOptReference, prj, task);
        if ( skipBuild != null ) {
            log.debug("SBSTask:makeOptions.skipping build:" + skipBuild);
            sbsLogName += "_nobuild";
            if (skipBuild.equals("true")) {
                task.createArg().setValue("-n");
            }
        }
        if (command != null) {
            log.debug("SBSTask:command:" + command);
            sbsLogName += command;
            task.createArg().setValue(command);
        }
        if (sysdefBase != null) {
            log.debug("SBSTask:sysdefBase:" + sysdefBase);
            task.createArg().setValue("-a");
            task.createArg().setValue(sysdefBase);
        }
        String logFileName = partialLogPath + "." + sysdefConfig + "_compile.log";
        sbsLogName = convertSpecialCharacters(sbsLogName);
        String tempPath = partialLogPath + "_" + sbsLogName + "_" + sysdefConfig;
        task.createArg().setValue("-m");
        task.createArg().setValue(tempPath + "_Makefile");
        String additionalFilters = "";
        /*
         * commented as changes from raptor is required and is not there yet. Further 
         * discussions on to handle in a better way.
         */
        if (whatOption != null && whatOption.equals("true")) {
            task.createArg().setValue("--what");
        }
        /*
        //When whatOption is set to true, then it uses the filterWhat plugin to generate the 
        // what log (which is generated during the build phase)
        if (whatOption != null && whatOption.equals("true")) {
            Environment.Variable var = new Environment.Variable();
            var.setKey("FILTERWHAT_FILE");
            var.setValue(partialLogPath + "." + sysdefConfig + "_what.log");
            log.debug("SBSTask:filterwhatlog file:" + (partialLogPath + "." + sysdefConfig + "_what.log"));
            task.addEnv(var);
            additionalFilters = ",filterWhat";
        }
        //When checkOption is set to true, then in filterHeliumLog during summary file generation
        // what log is read and checked for the existance of the file in what log. If the file doesn't exists
        // then it writes it to the check log. Requested this operation to be in raptor plugin rather than
        // in helium plugin, but 
        // what log (which is generated during the build phase)
        if (checkOption != null && checkOption.equals("true")) {
            Environment.Variable var = new Environment.Variable();
            var.setKey("FILTERCHECK_FILE");
            var.setValue(partialLogPath + "." + sysdefConfig + "_check.log");
            log.debug("SBSTask:filterchecklog file:" + (partialLogPath + "." + sysdefConfig + "_check.log"));
            task.addEnv(var);
            additionalFilters = ",filterWhat";
        }
        */
        if (checkOption != null && checkOption.equals("true")) {
            task.createArg().setValue("--check");
        }
        task.createArg().setValue("--filters=FilterMetadataLog" + additionalFilters);
        String sbsStatsFile = partialLogPath + "." + sysdefConfig + "_sbs_info.xml";
        if (retryOption != null) {
            //the problem could be that if the failure happened for some other reason
            //it would still retry
            log.debug("building with retry:");
            task.createArg().setValue("--tries");
            task.createArg().setValue(retryOption);
        }
        task.createArg().setValue("-f");
        task.createArg().setValue(tempPath + "_compile.log");
        String outputFileName = tempPath + ".sbs_ant_output.log";
        log.debug("SBSTask:outputfilename:" + outputFileName);
        log.debug("SBSTask:sbsLogName:" + sbsLogName);
        task.setOutput(new File(outputFileName));
        startTime = new Date();
        
        try {
            task.execute();
        } catch (Exception ex) {
            //Sometime null pointer exception is thrown in linux
            log.debug("Warning: exception during executing sbs task", ex);
        }
        try {
            log.debug("SBSTask:sbs.log.file:" + tempPath + "_compile.log");
            prj.setProperty("sbs.log.file", tempPath + "_compile.log");
        } catch (Exception e) {
            log.debug("SBSTask:sysdefBase:copying the log file with sbs config failed");
        }
        endTime = new Date();
        updateSBSLogStatistics(sbsStatsFile, tempPath + "_compile.log");
    }

    private String updateSBSMakeOptions(Object makeOptReference, Project prj, ExecTask task) {
        String retValue = "";
        if (makeOptReference != null && makeOptReference instanceof SBSMakeOptions) {
            Object makeOptObject = ((Reference)((SBSMakeOptions)makeOptReference).getRefid()).getReferencedObject();
            if (makeOptObject != null && makeOptObject instanceof SBSMakeOptions) {
                log.debug("SBSTask:makeOptReference: not null");
                SBSMakeOptions sbsMakeOptions = (SBSMakeOptions)makeOptObject;
                String engine = sbsMakeOptions.getEngine();
                log.info("SBSTask:with engine:" + engine);
                if (engine != null && engine.equals("emake")) {
                    emake(task, sbsMakeOptions, prj);
                } else if (engine != null && engine.equals("gmake")) {
                    retValue += gmake(task, prj);
                }
            }
        }
        return retValue;
    }
    
    private void updateSBSLogStatistics(String infoFileName, 
            String logFileName) {

        try {
            DocumentBuilderFactory sbsInfo = DocumentBuilderFactory.newInstance();
            DocumentBuilder docBuilder = sbsInfo.newDocumentBuilder();
            Document doc = docBuilder.newDocument();
            Element root = doc.createElement("sbsinfo");
            doc.appendChild(root);
            Element child = doc.createElement("logfile");
            child.setAttribute("name", logFileName);
            root.appendChild(child);
            
            child = doc.createElement("duration");
            //Todo: handle if the time difference is greater than 24 hours
            child.setAttribute("time", timeFormat.format(new Date(endTime.getTime() - startTime.getTime())));
            root.appendChild(child);
            Transformer transformer = TransformerFactory.newInstance().newTransformer();
            transformer.setOutputProperty(OutputKeys.INDENT, "yes");
            FileWriter sbsWriter = new FileWriter(infoFileName);
            StreamResult result = new StreamResult(sbsWriter);
            DOMSource sbsSource = new DOMSource(doc);
            transformer.transform(sbsSource, result);
        } catch (Exception ex) {
            log.debug("exception while xml writing sbs log info", ex);
        }
        
    }

    
    private String setLayerArgs(ExecTask task)
    {
        String logName = "";
        if (layers != null) { 
            String[] lList = layers.split(","); 
            for (int i = 0;i < lList.length; i++) { 
                log.debug("SBSTask:llist:" + lList[i]); 
                logName += "_" + lList[i]; 
                task.createArg().setValue("-l"); 
                task.createArg().setValue(lList[i]); 
            } 
        }
        return logName;
    }
    
    private String setConfigArgs(ExecTask task)
    {
        String logName = "";
        if (config != null) {
            String[] configList = config.split(",");
            for (int i = 0; i < configList.length; i++) {
                logName += "_" + configList[i];
                task.createArg().setValue("-c");
                task.createArg().setValue(configList[i]);
            }
        }
        return logName;
    }
    
    private String gmake(ExecTask task, Project prj)
    {
        log.info("SBSTask:normal gmake");
        if (singleJob == null) {
            log.debug("SBSTask:building using multiple thread");
            task.createArg().setValue("-j");
            task.createArg().setValue(prj.getProperty("number.of.threads"));
            return "_multiple_thread";
        } else if (singleJob.equals("true")) {
            task.createArg().setValue("-j");
            task.createArg().setValue("1");
            return "_single_thread";
        }
        return "";
    }
    
    private void emake(ExecTask task, SBSMakeOptions sbsMakeOptions, Project prj)
    {
        HashMap makeOptMap = new HashMap();
        Vector makeOptions = sbsMakeOptions.getVariables();
        Enumeration makeOptEnum = makeOptions.elements();
        Variable variable = null;
        while (makeOptEnum.hasMoreElements()) {
            variable = (Variable)makeOptEnum.nextElement();
            log.debug("SBSTask:makeOptions.variable-name:" + variable.getName());
            log.debug("SBSTask:makeOptions.variable-name:" + variable.getValue());
            makeOptMap.put(variable.getName(),variable.getValue());
        }
        updatedMakeOptions(sbsMakeOptions.getEngine(), makeOptMap, prj);
        log.info("SBSTask:updating all make options");
        
        String makeOpt = null;
        task.createArg().setValue("-e");
        task.createArg().setValue("emake");
        Set keys = makeOptMap.keySet();
        for ( Iterator listIter = keys.iterator(); listIter.hasNext(); ) {
            makeOpt = (String)listIter.next();
            String param = prefix + makeOpt;
            String paramValue = (String)makeOptMap.get(makeOpt);
            if (paramValue != null ) {
                param += equalSign + paramValue;
            }
            task.createArg().setValue( param );
            log.debug("SBSTask:makeOptions.variable-name:" + param);
        }
    }
    
        /**
         * Updates the make options with default values if not provided. 
         * @param engine - make engine for sbs command
         * @param prj - Ant project reference. 
        */
    private void updatedMakeOptions(String engine, HashMap makeOptsMap, Project prj) {
        log.info("Updating default make options along with passed options");
        if (engine.equals("emake")) {
            if (makeOptsMap.get("--emake-root") == null) {
                String emakeRoot = prj.getProperty("env.EMAKE_ROOT") + ";" + prj.getProperty("helium.dir") + ";" +
                        prj.getProperty("build.drive") + "/;" + prj.getProperty("env.SBS_HOME");
                makeOptsMap.put("--emake-root",emakeRoot);
                log.debug("SBSTask:adding --emake-root:" + emakeRoot);
            }
            if (makeOptsMap.get("--emake-annodetail") == null) {
                log.debug("SBSTask:adding --emake-annodetail:");
                makeOptsMap.put("--emake-annodetail","basic,history,waiting");
            }
            if (makeOptsMap.get("--emake-historyfile") == null) {
                log.debug("SBSTask:adding --emake-historyfile");
                String emakeHistoryDIR = prj.getProperty("build.log.dir") + "/ec_history/";
                File emakeHistoryDIRFile = new File(emakeHistoryDIR);
                if (!emakeHistoryDIRFile.exists()) {
                    boolean successus = emakeHistoryDIRFile.mkdir();
                    log.debug("SBSTask:history dir created status :" + emakeHistoryDIRFile + ":" + successus);
                }
                String emakeHistoryFile = emakeHistoryDIR + "emake_" + prj.getProperty("sysdef.configuration") + ".data";
                makeOptsMap.put("--emake-historyfile",emakeHistoryFile);
                log.debug("SBSTask:adding --emake-historyfile" + emakeHistoryFile);
            }
            if (makeOptsMap.get("--emake-annofile") == null) {
                log.debug("SBSTask:adding --emake-annofile");
                String annofile = prj.getProperty("build.log.dir") + "/" + 
                                prj.getProperty("build.id") + ".xml";
                makeOptsMap.put("--emake-annofile",annofile);
                log.debug("SBSTask:adding --emake-annofile" + annofile);
            }
            if (makeOptsMap.get("--emake-emulation") == null) {
                makeOptsMap.put("--emake-emulation", "gmake");
                log.debug("SBSTask:adding --emake-emulation:gmake");
            }
        }
    }
    
    private String convertSpecialCharacters(String inputFileName) {
        int colonIndex = 0;
        String resultString;
        colonIndex = inputFileName.indexOf(':');
        if ((colonIndex != -1) && (inputFileName.substring(0, colonIndex + 2)).endsWith(":\\")) {
            resultString = inputFileName.substring(0, colonIndex + 2);
            String remainingString = inputFileName.substring(colonIndex + 2);
            remainingString = remainingString.replaceAll(":","_");
            resultString += remainingString;
        } else {
            resultString = inputFileName.replaceAll(":", "_");
        }
        return resultString;
    }
}
