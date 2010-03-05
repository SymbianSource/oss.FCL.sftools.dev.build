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
package com.nokia.helium.logger.ant.types;

import java.io.File;

import org.apache.tools.ant.types.DataType;
import com.nokia.helium.logger.ant.listener.AntLoggingHandler;
import com.nokia.helium.logger.ant.listener.StatusAndLogListener;
import org.apache.log4j.Logger;

/**
 * A 'StageRecord' is a Data type which stores attributes for stage recording/logging.
 * 
 * 
 * Usage:
 * <pre>
 * &lt;hlm:stagerecord id="record.default" defaultoutput="${build.log.dir}/${build.id}_main.ant.log" loglevel="info" append="false"/&gt;
 *      
 *                  
 * &lt;hlm:stagerecord id="record.prep"  
 *                  stagerefid="preparation" 
 *                  output="${build.log.dir}/${build.id}_prep.ant.log" 
 *                  loglevel="info"
 *                  append="false"/&gt;
 *                                  
 * </pre>
 * 
 * 
 * @ant.task name="stagerecord" category="Logging"
 */
public class StageLogging extends DataType {
    
    private static boolean isAntLoggerRegistered;
    private String logLevel = "info";
    private File logFile;
    private File defaultLogFile;
    private boolean append = true;
    private String stageRefId;
    private Logger log = Logger.getLogger(getClass());
    
    /**
     * Constructor which will register the logging handler
     */
    public StageLogging () {
        if (!isAntLoggerRegistered && StatusAndLogListener.getStatusAndLogListener() != null) {
            log.debug("Registering stage record to the StatusAndLogListener listener");
            StatusAndLogListener.getStatusAndLogListener().register(new AntLoggingHandler(getProject()));
            isAntLoggerRegistered = true;
        }
    }
    
    /**
     * Sets output log file name.
     * @param output the file to log into
     * @ant.required
     */
    
    public void setOutput(File output) {
        this.logFile = output;
    }
    
    /**
     * Returns output log file name.
     * @return
     */
    
    public File getOutput() {
        return this.logFile;
    }
    
    /**
     * Sets log level for respective stage.
     * @param logLevel
     * @ant.not-required
     */
    
    public void setLogLevel(String logLevel) {
        this.logLevel = logLevel;
    }
    
    /**
     * Returns log level of respective stage.
     * @return
     */
    
    public String getLogLevel() {
        return this.logLevel;
    }
    
    /**
     * Get the name of this StageRefID.
     * 
     * @return name of the Phase.
     */
    public String getStageRefID() {
        return this.stageRefId;
    }

    /**
     * Set the name of the StageRefID.
     * 
     * @param name
     *            is the name to set.
     * @ant.required
     */
    public void setStageRefId(String name) {
        this.stageRefId = name;
    }
    
    /**
     * Return default ant log file name.
     * @return
     */
    public File getDefaultOutput() {
        return this.defaultLogFile;
    }

   /**
    * Set the default ant log name.
    * @param name
    * @ant.required
    */
    public void setDefaultOutput(File name) {
        this.defaultLogFile = name;
    }
    
    /**
     * Set append value.
     * @param append
     * @ant.not-required Default is true
     */
    public void setAppend(boolean append) {
        this.append = append;
    }
    
    /**
     * Return the append value.
     * @param append
     * @return
     */
    public boolean getAppend() {
        return this.append;
    }
    
     
}
