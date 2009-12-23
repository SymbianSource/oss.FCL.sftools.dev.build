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

package com.nokia.helium.sbs.ant.taskdefs;

import java.util.List;
import org.w3c.dom.*;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import java.io.FileWriter;
import java.text.DecimalFormat;
import java.util.Date;
import com.nokia.helium.core.plexus.AntStreamConsumer;
import java.io.File;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import com.nokia.helium.core.ant.types.Variable;
import com.nokia.helium.core.ant.types.VariableSet;
import com.nokia.helium.sbs.ant.types.*;
import com.nokia.helium.sbs.ant.*;
import org.apache.log4j.Logger;
import org.apache.tools.ant.types.PatternSet;
import com.nokia.helium.sbs.SAXSysdefParser;
import com.nokia.helium.sbs.SBSCommandBase;
import com.nokia.helium.sbs.SBSException;
import java.util.ArrayList;
import java.util.Hashtable;
import com.nokia.helium.core.plexus.FileStreamConsumer;
import java.util.Collection;

public class SBSTask extends Task {

    private Logger log = Logger.getLogger(SBSTask.class);
    private String sbsInputName;
    private String layerPatternSetRef;
    private File sysDefFile;
    private File workingDir;
    private File errorFile;
    private String logSuffix;
    private String cleanLog;
    private String outputLogName;
    private File statsLog;
    private boolean executeCmd = true;
    private boolean failOnError = true;
    private Date startTime;
    private Date endTime;


    public void setCleanLog(String logPath) {
        cleanLog = logPath;
    }

    public void setOutputLog(String logName) {
        outputLogName = logName;
    }

    public void setStatsLog(File log) {
        statsLog = log;
    }
    
    public void setSBSInput(String inputName) {
        sbsInputName = inputName;
    }

    public void setErrorOutput(File file) {
        errorFile = file;
    }

    public void setSysDefFile(File file) {
        sysDefFile = file;
    }

    public void setLogSuffix(String suffix) {
        logSuffix = suffix;
    }

    public void setLayerPatternSetRef(String id) {
        layerPatternSetRef = id;
    }

    public void setWorkingDir(File dir) {
        workingDir = dir;
    }

    public void setExecute(boolean execute) {
        executeCmd = execute;
    }

    public void setFailOnError(boolean failBuild) {
        failOnError = failBuild;
    }

    /**
     *  Execute the task. Set the property with number of severities.  
     * @throws BuildException
     */
    public void execute() {
        if (sbsInputName == null) {
            throw new BuildException("sbsInputName is not defined");
        }
        if (sysDefFile == null) {
            throw new BuildException("System Definition file is missing");
        }
        if (workingDir == null) {
            throw new BuildException("workingDir must be set");
        }
        
        List <String> filteredLayers = getFilteredLayers();
        SBSCommandBase sbsCmd = new SBSCommandBase();
        sbsCmd.setWorkingDir(workingDir);
        if (cleanLog != null) {
            sbsCmd.setCleanLogFilePath(cleanLog);
        }
        try {
            log.debug("error stream file : " + errorFile);
            sbsCmd.addOutputLineHandler(new AntStreamConsumer(this));
            if (errorFile == null) {
                log.debug("redirecting error to Antstream");
                sbsCmd.addErrorLineHandler(new AntStreamConsumer(this));
            } else {
                log.debug("redirecting error to file stream");
                sbsCmd.addErrorLineHandler(new FileStreamConsumer(errorFile));
            }
        } catch (java.io.FileNotFoundException ex) {
            log.info("file path: " + errorFile + "Not valid" );
        }
        Object refObject = getProject().getReferences().get(sbsInputName);
        if (refObject == null) {
            throw new BuildException("invalid sbs input reference: " + sbsInputName);
        }
        if ( refObject != null && ! (refObject instanceof SBSInput)) {
            throw new BuildException("sbs input name " + sbsInputName + "is not valid");
        }
        SBSInput sbsInput = (SBSInput)refObject;
        StringBuffer cmdOptions = new StringBuffer();
        VariableSet sbsOptions = sbsInput.getFullSBSOptions();
        cmdOptions.append(" -s " + sysDefFile);
        Collection<Variable> variableList = sbsOptions.getVariables(); 
        if (sbsOptions != null ) {
           if (variableList.isEmpty()) {
               throw new BuildException("sbsoptions cannot be empty for input: " + sbsInputName);
           }
        }
        for (Variable variable : variableList) {
            cmdOptions.append(" " + variable.getParameter());
        }
        SBSMakeOptions sbsMakeOptions = sbsInput.getFullSBSMakeOptions();
        variableList = null;
        if (sbsMakeOptions != null) {
            cmdOptions.append(" -e " + sbsMakeOptions.getEngine());
            String ppThreads = sbsMakeOptions.getPPThreads();
            if (ppThreads != null) {
                cmdOptions.append(" -j " + ppThreads);
            }
            variableList = sbsMakeOptions.getVariables(); 
            //if (variableList.isEmpty()) {
            //    throw new BuildException("sbs make options cannot be empty for input: " + sbsInputName);
            //}
            for (Variable variable : variableList) {
                cmdOptions.append(" --mo=");
                cmdOptions.append(variable.getParameter());
            }
        }
        if (filteredLayers != null) {
            if (filteredLayers.isEmpty()) {
                log.info("Warning: No matching layers to build from system definition file, skipped");
                return;
            } else {
                for (String layer : filteredLayers) {
                    cmdOptions.append(" -l " + layer);
                }
            }
        }
        startTime = new Date();
        try {
            log("sbs commands: " + cmdOptions.toString());
            if (executeCmd) {
                sbsCmd.execute(cmdOptions.toString());
            }
        } catch (SBSException sex) {
            log.info("SBS exception occured during sbs execution");
            if (failOnError) {
                throw new BuildException("exception during SBS execution", sex);
            }
        } catch (Exception ex) {
            log.info("Exception occured during sbs execution");
            if (failOnError) {
                throw new BuildException("exception during SBS execution", ex);
            }
        }
        endTime = new Date();
        updateSBSLogStatistics(statsLog, outputLogName);
    }

    private List<String> getFilteredLayers() {
        List<String> filteredLayers = null;
        if (layerPatternSetRef != null) {
            Hashtable references = getProject().getReferences();
            Object layerPatternSetObject = references.get(layerPatternSetRef); 
            if ( layerPatternSetObject != null && ! (layerPatternSetObject instanceof PatternSet)) {
                throw new BuildException("Layer Pattern set is not of type PatternSet");
            }
            if (layerPatternSetObject != null) {
                PatternSet layerPatternSet = (PatternSet) layerPatternSetObject;
                SAXSysdefParser sysDefParser = new SAXSysdefParser(sysDefFile);
                List<String> fullLayerList = sysDefParser.getLayers(); 
                filteredLayers = new ArrayList<String>();
                String[] includes = layerPatternSet.getIncludePatterns(getProject());
                String[] excludes = layerPatternSet.getExcludePatterns(getProject());
                if (includes == null && excludes == null) {
                    throw new BuildException("No patterns specified");
                }
                for (String layer : fullLayerList) {
                    if (includes == null) {
                        if (!isExcluded(layer, excludes)) {
                            filteredLayers.add(layer);
                        }
                        continue;
                    }
                    if (isIncluded(layer, includes) ) {
                        if (!isExcluded(layer, excludes)) {
                            filteredLayers.add(layer);
                        }
                    }
                }
            }
        }
        return filteredLayers;
    }

    
    private boolean isIncluded(String text, String[] includes) {
        if (includes != null) {
            for (String pattern : includes) {
                if (text.matches(pattern)) {
                    return true;
                }
            }
        }
        return false;
    }

    private void updateSBSLogStatistics(File infoFileName, 
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

            long timeDiff = (endTime.getTime() - startTime.getTime()) / 1000;
            child = doc.createElement("durationlong");
            child.setAttribute("time", "" + timeDiff);
            root.appendChild(child);
            child = doc.createElement("duration");
            int hours = (int) (timeDiff / 3600);
            int minutesSeconds = (int)(timeDiff % 3600);
            int minutes = minutesSeconds / 60;
            int seconds = minutesSeconds % 60;
            DecimalFormat decimalFormat =  new DecimalFormat();
            decimalFormat.setMinimumIntegerDigits(2);
            String duration = decimalFormat.format(hours) + "H:" +  
                    decimalFormat.format(minutes) +  "M:"  + decimalFormat.format(seconds) + "S";
            //Todo: handle if the time difference is greater than 24 hours
            child.setAttribute("time", duration);
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

    private boolean isExcluded(String text, String[] excludes) {
        if (excludes != null) {
            for (String pattern : excludes) {
                if (text.matches(pattern)) {
                    return true;
                }
            }
        }
        return false;
    }
}