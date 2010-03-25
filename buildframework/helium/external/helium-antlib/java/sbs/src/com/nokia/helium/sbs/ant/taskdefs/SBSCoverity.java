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

import java.util.Date;
import java.util.Vector;
import java.util.Map.Entry;

import org.apache.tools.ant.BuildException;

import com.nokia.helium.core.ant.types.Variable;
import com.nokia.helium.core.ant.types.VariableSet;
import com.nokia.helium.core.plexus.AntStreamConsumer;
import com.nokia.helium.sbs.SBSCommandBase;
import com.nokia.helium.sbs.plexus.CoverityErrorStreamConsumer;

import org.apache.log4j.Logger;


/**
 * This task is to execute the cov-build command with the list of sbs parameters
 * using sbsinput type. Based on the raptor input list of additional log file path
 * used needs to be set, so that the scanlog, additional log files are generated 
 * properly.
 * 
 * <pre>
 * Example 1:
 * 
 * &lt;coveritybuild sbsinput=&quot;sbs.input&quot; sysdefFile=&quot;system.def.file&quot;
 *      workingDir=&quot;build.drive&quot; failOnError=&quot;false&quot; 
 *      cleanLog=&quot;sbs.log.file.clean.log&quot; 
 *      failOnError=&quot;false&quot; 
 *      errorfile=&quot;path to error file&quot;/&gt;
 * </pre>
 * 
 * @ant.task name="coveritybuild" category="SBS"
 */
public class SBSCoverity extends SBSTask {
        
    private Vector<VariableSet> coverityOptions = new Vector<VariableSet>();
    private Logger log = Logger.getLogger(SBSCoverity.class);
    private Date startTime;
    private Date endTime;
    
    public void execute() {
        
        validateParameter();
        // Disabling the emake options as sbs will not output emake output.
        setAddMakeOptions(false);
        CoverityErrorStreamConsumer coverityErrorConsumer = null;
        SBSCommandBase sbsCmd = new SBSCommandBase();
        sbsCmd.setWorkingDir(getWorkingDir());
        if (getCleanLog() != null) {
            sbsCmd.setCleanLogFilePath(getCleanLog());
        }
        
        try {
            log.debug("error stream file : " + getErrorOutput());
            sbsCmd.addOutputLineHandler(new AntStreamConsumer(this));
            if (getErrorOutput() == null) {
                log.debug("redirecting error to Antstream");
                sbsCmd.addErrorLineHandler(new AntStreamConsumer(this));
            } else {
                coverityErrorConsumer = new CoverityErrorStreamConsumer(getErrorOutput());
                log.debug("redirecting error to file stream");
                sbsCmd.addErrorLineHandler(coverityErrorConsumer);
            }
        } catch (java.io.FileNotFoundException ex) {
            log.info("file path: " + getErrorOutput() + "Not valid" );
        }
        
        StringBuffer coverityCmdOptions = new StringBuffer();
        
        sbsCmd.setExecutable("cov-build");
        String coverityConfig = "";
        for (VariableSet coverityArg : coverityOptions) {
            for (Entry<String, Variable> entry : coverityArg.getVariablesMap().entrySet() ) {
                coverityConfig = coverityConfig +  entry.getKey() + " " + entry.getValue().getValue() + " ";
            }
        }
        
        coverityCmdOptions.append(coverityConfig + "sbs" + getSBSCmdLine());
        startTime = new Date();
        try {
            log("cov-build commands: " + coverityCmdOptions.toString());
            if (getExecute()) {
                sbsCmd.execute(coverityCmdOptions.toString());
            }
        } catch (Exception ex) {
            log.debug("Exception occured during 'cov-build' execution", ex);
            if (getFailOnError()) {
                throw new BuildException("exception during 'cov-build' execution", ex);
            }
        } finally {
            //Called to update the error stream, better would be the commandbase
            //handling the closing of streams in case of exceptions.
            if (coverityErrorConsumer != null) {
                coverityErrorConsumer.close();
            }
        }
        endTime = new Date();
        updateSBSLogStatistics(getStatsLog(), getOutputLog(), startTime, endTime);
    }
    
    /**
     * To read the coverity arguments for cov-build command.
     * @param coverityArg
     */
    public void addCoverityOptions(VariableSet coverityArg) {
        if (!coverityOptions.contains(coverityArg)) {
            coverityOptions.add(coverityArg);
        }
    }
    

}
