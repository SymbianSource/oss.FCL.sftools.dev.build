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
import org.apache.log4j.Logger;
import org.apache.tools.ant.types.PatternSet;
import com.nokia.helium.sbs.SAXSysdefParser;
import com.nokia.helium.sbs.SBSCommandBase;
import com.nokia.helium.sbs.SBSException;
import java.util.ArrayList;
import java.util.Hashtable;
import com.nokia.helium.sbs.plexus.SBSErrorStreamConsumer;
import java.util.Collection;

/**
 * This task is to execute the actual sbs commands with the list of sbs parameters
 * using sbsinput type. Based on the raptor input list of additional log file path
 * used needs to be set, so that the scanlog, additional log files are generated 
 * properly.
 * 
 * <pre>
 * Example 1:
 * 
 * &lt;sbstask sbsinput=&quot;sbs.input&quot; sysdefFile=&quot;system.def.file&quot;
 *      layerPatternSetRef=&quot;sbs.patternset&quot; errorOutput=&quot;sbs.log.file.error.log&quot;
 *      workingDir=&quot;build.drive&quot; failOnError=&quot;false&quot; outputLog=&quot;sbs.log.file&quot;
 *      cleanLog=&quot;sbs.log.file.clean.log&quot; statsLog=&quot;sbs.log.file.info.xml&quot; /&gt;
 * </pre>
 * 
 * @ant.task name="sbstask" category="SBS"
 */
public class SBSTask extends Task {

    private Logger log = Logger.getLogger(SBSTask.class);
    private String sbsInputName;
    private String layerPatternSetRef;
    private File sysDefFile;
    private File workingDir;
    private File errorFile;
    private String logSuffix;
    private String cleanLog;
    private String whatLog;
    private String outputLogName;
    private File statsLog;
    private boolean executeCmd = true;
    private boolean failOnError = true;
    private boolean addMakeOptions = true;
    private Date startTime;
    private Date endTime;
    private SBSCommandBase sbsCmd = new SBSCommandBase();
    
    public SBSCommandBase getSbsCmd() { return sbsCmd; }

    /**
     *  Helper function to set the clean log file. The cleanlog file captures the 
     *  clean output from raptor and stores into a separate log. This is being used
     *  to backtrace the error information to associate the components. The clean log 
     *  contains the list of files has to be cleaned by the raptor command for a
     *  specific components. An environment varialbe is set which is used by 
     *  filterMetadata plugin to store the clean log file in python. 
     * @param logPath, path of the clean log file.
     */
    public void setCleanLog(String logPath) {
        cleanLog = logPath;
    }

    /**
     *  Helper function to set the what log file. The what log file captures the 
     *  what output from raptor and stores into a separate log. This is being used
     *  to backtrace the error information to associate the components. The clean log 
     *  contains the list of files has to be cleaned by the raptor command for a
     *  specific components. An environment varialbe is set which is used by 
     *  filterMetadata plugin to store the clean log file in python. 
     * @param logPath, path of the clean log file.
     */
    public void setWhatLog(String logPath) {
        whatLog = logPath;
    }

    /**
     * To get the whatlog value.
     * @return
     */
    public String getWhatLog() {
        return whatLog;
    }

    /**
     * To get the cleanlog value.
     * @return
     */
    public String getCleanLog() {
        return cleanLog;
    }

    /**
     *  Helper function to set the output log file name. Path of the output log
     *  where the raptor command output to be stored. This would be obtained from
     *  sbsinput, if the raptor argument --logfile set.
     * @param logName, name of the logfile to store the raptor output.
     */
    public void setOutputLog(String logName) {
        outputLogName = logName;
    }
    
    /**
     * To get the output log.
     * @return
     */
    public String getOutputLog() {
        return outputLogName ;
    }
    
    

    /**
     *  Helper function to set the statistics info of the raptor command. The
     *  stats file contains how long the build being executed, the log file for
     *  which the stats is obtained. Used during scanlog generation from template file.
     *  Once ORM is working an additional table could be created which stores the 
     *  statistics information, in which case, there won't be the need for the
     *  statistics file.
     * @param log name of the logfile to store the raptor command statistics information.
     */
    public void setStatsLog(File log) {
        statsLog = log;
    }
    
    /**
     *  To get the status log file.
     * @return
     */
    public File getStatsLog() {
        return statsLog ;
    }
    
    
    

    /**
     *  Helper function to set the sbsinput name for which the sbs to be executed.
     *  The sbsinput contains the raptor parameter both the sbs options and sbs make options.
     * @param inputName name of the sbs input which contains the list of sbs parameters.
     */
    public void setSBSInput(String inputName) {
        sbsInputName = inputName;
    }
    
    /**
     * To get the sbs name.
     * @return
     */
    public String getSBSInput() {
        return sbsInputName ;
    }
    
    

    /**
     *  Helper function to set the sbs error log file path. The error log file contains
     *  the errors captured from the raptor error stream and processed separately.
     * @param file path of the error output to be stored for the raptor command execution.
     */
    public void setErrorOutput(File file) {
        errorFile = file;
    }
    
    /**
     * To get the error output file.
     * @return
     */
    public File getErrorOutput() {
        return errorFile ;
    }

    /**
     *  Helper function to set the sysdef file path. System definition file contains
     *  the full list of components to be build with the sbs input. For 1.4.0 schema
     *  the sysdef file should be already filtered for the corresponding abld configuration
     *  and the sysdef file associated here contains only layers for which the sbs command
     *  needs to be executed with sbsinput arguments. 
     * @param file sysdef file path.
     */
    public void setSysDefFile(File file) {
        sysDefFile = file;
    }
    
    /**
     * To get the sysdef file.
     * @return
     */
    public File getSysDefFile() {
        return sysDefFile ;
    }
    

    /**
     *  Helper function to set the log suffix.
     *  @param suffix logfile suffix.
     */
    public void setLogSuffix(String suffix) {
        logSuffix = suffix;
    }
    
    /**
     * To get the logsuffix.
     * @return
     */
    public String getLogSuffix() {
        return logSuffix ;
    }

    /**
     *  Patternset is used to filter the layers from the sysdef file for which the sbs
     *  commands need to be executed instead of all the layers in the system definition files.
     *  This is useful for example in order to execute only the test layer, a patter set could
     *  contain test*, then all the layers begining with test are matched and passed as 
     *  raptor input.
     *  @param id patternset id, for which the patterns to be filtered.
     */
    public void setLayerPatternSetRef(String id) {
        layerPatternSetRef = id;
    }
    
    /**
     * 
     * To get the layer pattern set. 
     * @return
     */
    public String getLayerPatternSetRef() {
        return layerPatternSetRef ;
    }

    /**
     * Helper function to set the current working directory. This would be mostly the
     * root of the build area.
     *  @param dir root of the build area location from which to execute the raptor commands.
     */
    public void setWorkingDir(File dir) {
        workingDir = dir;
    }
    
    /**
     * To get the working dir.
     * @return
     */
    public File getWorkingDir() {
        return workingDir ;
    }
    


    /**
     * Helper function to execute the actual commands or just print the commands and 
     * not execute the actual commands.
     *  @param execute true / false if true print and execute the commands, otherwise just
     *  print the commands.
     */
    public void setExecute(boolean execute) {
        executeCmd = execute;
    }
    
    /**
     * To get execute value.
     * @return
     */
    public boolean getExecute() {
        return executeCmd ;
    }

    /**
     * Helper function to set whether to fail the build or not. 
     *
     * @param failBuild true / false - true to fail the build otherwise false.
     */
    public void setFailOnError(boolean failBuild) {
        failOnError = failBuild;
    }
    
    /**
     * To get the failonError value.
     * @return
     */
    public boolean getFailOnError() {
        return failOnError ;
    }

    /**
     * @param addMakeOptions the addMakeOptions to set
     */
    protected void setAddMakeOptions(boolean addMakeOptions) {
        this.addMakeOptions = addMakeOptions;
    }

    /**
     *  Execute the sbs commands from sbsinput.  
     * @throws BuildException
     */
    public void execute() {
        SBSErrorStreamConsumer sbsErrorConsumer = null;
        validateParameter();
        sbsCmd.setWorkingDir(workingDir);
        if (cleanLog != null) {
            sbsCmd.setCleanLogFilePath(cleanLog);
        }
        if (whatLog != null) {
            sbsCmd.setWhatLogFilePath(whatLog);
        }
        try {
            log.debug("error stream file : " + errorFile);
            sbsCmd.addOutputLineHandler(new AntStreamConsumer(this));
            if (errorFile == null) {
                log.debug("redirecting error to Antstream");
                sbsCmd.addErrorLineHandler(new AntStreamConsumer(this));
            } else {
                sbsErrorConsumer = new SBSErrorStreamConsumer(errorFile);
                log.debug("redirecting error to file stream");
                sbsCmd.addErrorLineHandler(sbsErrorConsumer);
            }
        } catch (java.io.FileNotFoundException ex) {
            log.info("file path: " + errorFile + "Not valid" );
        }
        
        startTime = new Date();
        try {
            log("sbs commands: " + getSBSCmdLine());
            if (executeCmd) {
                sbsCmd.execute(getSBSCmdLine());
            }
        } catch (SBSException sex) {
            log.debug("SBS exception occured during sbs execution", sex);
            if (failOnError) {
                throw new BuildException("exception during SBS execution", sex);
            }
        } catch (Exception ex) {
            log.debug("Exception occured during sbs execution", ex);
            if (failOnError) {
                throw new BuildException("exception during SBS execution", ex);
            }
        } finally {
            //Called to update the error stream, better would be the commandbase
            //handling the closing of streams in case of exceptions.
            if (sbsErrorConsumer != null) {
                sbsErrorConsumer.close();
            }
        }
        endTime = new Date();
        if (statsLog != null) {
            updateSBSLogStatistics(statsLog, outputLogName, startTime, endTime);
        }
    }

    /**
     * Internal function to get the filtered layers by
     * processing the system definition file with list of matched layers. 
     * 
     * @return list of filtered layers from the sysdef file for which
     * the raptor commands to be executed.
     */
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

    /**
     * Update the raptor build statistics by generating an xml file containing
     * the build time and the log file name, used to generate the scanlog. 
     * @param infoFileName
     * @param logFileName
     * @param startTime
     * @param endTime
     */
    protected void updateSBSLogStatistics(File infoFileName, String logFileName, Date startTime, Date endTime) {

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


    /**
     * Internal function to find the included layer patterns. 
     *
     * @param text - layer name to be compared with
     * @param includes - compare the layer name with the includes list.
     * @return true if the text containing layer name to be included.
     */
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

    /**
     * Internal function to find the excluded layer patterns. 
     *
     * @param text - layer name to be compared with
     * @param excludes - compare the layer name with the excludes list.
     * @return true if the text containing layer name to be excluded.
     */
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
    
    
    /**
     * To Validate the parameters passed.
     */
    protected void validateParameter() {
        
        if (getSBSInput() == null) {
            throw new BuildException("'sbsInputName' is not defined");
        }
        if (getSysDefFile() == null) {
            throw new BuildException("'System Definition' file is missing");
        }
        if (getWorkingDir() == null) {
            throw new BuildException("'workingDir' must be set");
        }
        if (getOutputLog() == null) {
            throw new BuildException("'OutputLog' must be set");
        }
        
    }
    
    /**
     * To get the SBS command line parameters.
     * @return
     */
    protected String getSBSCmdLine() {
        
        List <String> filteredLayers = getFilteredLayers();
        
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
            if (variable.getParameter().startsWith("--logfile")) {
                cmdOptions.append(" --logfile " + getOutputLog());
            } else {
                cmdOptions.append(" " + variable.getParameter());
            }
        }
        SBSMakeOptions sbsMakeOptions = sbsInput.getFullSBSMakeOptions();
        variableList = null;
        if (sbsMakeOptions != null && addMakeOptions) {
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
                log("Warning: No matching layers to build from system definition file, skipped");
                return null;
            } else {
                for (String layer : filteredLayers) {
                    cmdOptions.append(" -l " + layer);
                }
            }
        }
        return cmdOptions.toString();
        
    }
    
}