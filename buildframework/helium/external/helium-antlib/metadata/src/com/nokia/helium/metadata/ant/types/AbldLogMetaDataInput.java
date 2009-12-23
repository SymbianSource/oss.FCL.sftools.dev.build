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

package com.nokia.helium.metadata.ant.types;

import java.io.*;
import org.apache.tools.ant.BuildException;
import java.util.*;
import org.apache.log4j.Logger;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

/**
 * This Type is to specify and use the abld logparser type to parse and store the data.
 *
 * <pre>
 * &lt;hlm:metadatafilterset id="abld.metadata.filter"&gt;
 *    &lt;metadatafilterset filterfile="common.csv" /&gt;
 * &lt;/hlm:metadatafilterset&gt;
 * 
 * &lt;hlm:abldmetadatainput&gt;
 *    &lt;fileset dir="${project.dir}/../data/"&gt;
 *        &lt;include name="*_compile*.log"/&gt;
 *    &lt;/fileset&gt;
 *    &lt;metadatafilterset refid="abld.metadata.filter" /&gt;
 * &lt;/hlm:antmetadatainput&gt;
 * </pre>
 * 
 * @ant.task name="abldmetadatainput" category="Metadata"
 */
public class AbldLogMetaDataInput extends TextLogMetaDataInput {

    private Logger log = Logger.getLogger(AbldLogMetaDataInput.class);
    
    private Pattern abldFinishedPattern = Pattern.compile("^===\\s+.+\\s+finished.*");
    private Pattern abldStartedPattern = Pattern.compile("^===\\s+(.+)\\s+started.*");
    private Pattern abldComponentPattern = Pattern.compile("^===\\s+(.+?)\\s+==\\s+(.+)");
    

    private String currentComponent;
    
    private boolean entryCreated;

    private boolean recordText;
    
    public AbldLogMetaDataInput() {
    }

    /**
     * Function to check from the input stream if is there any entries available.
     * @return true if there are any entry available otherwise false.
     */
    public boolean isEntryCreated(File currentFile) {
        String exceptions = "";
        int lineNumber = getLineNumber(); 
        BufferedReader currentReader = getCurrentReader();
        log.debug("Getting next set of log entries for Abld Input");
        try {
            if (currentReader == null) {
                lineNumber = 0;
                setLineNumber(lineNumber);
                log.debug("Current abld log file name:" + currentFile);
                log.debug("Processing file: " + currentFile);
                currentReader = new BufferedReader(new FileReader(currentFile));
                setCurrentReader(currentReader);
            }
            String logText = null;
            while ((logText = currentReader.readLine()) != null) {
                lineNumber ++;
                setLineNumber(lineNumber);
                logText = logText.replaceFirst("'^\\s*\\[.+?\\]\\s*", "");
                if (logText.startsWith("++ Finished at")) {
                    if (currentComponent != null && !entryCreated) {
                        addEntry("DEFAULT", currentComponent, currentFile.toString(), 
                                0, "" );
                        entryCreated = true;
                        recordText = false;
                        return true;
                    }
                    entryCreated = false;
                } else if (logText.startsWith("=== ")) {
                    Matcher finishMatch = abldFinishedPattern.matcher(logText);
                    if (finishMatch.matches()) {
                        if (currentComponent != null && !entryCreated) {
                            addEntry("DEFAULT", currentComponent, currentFile.toString(), 
                                    0, "" );
                            entryCreated = true;
                            recordText = false;
                            return true;
                        }
                        entryCreated = false;
                    } else {
                        Matcher componentMatch = abldComponentPattern.matcher(logText);
                        if (componentMatch.matches()) {
                            currentComponent = componentMatch.group(2);
                            recordText = true;
                        }

                        Matcher startMatch = abldStartedPattern.matcher(logText);
                        if (startMatch.matches()) {
                            currentComponent = startMatch.group(1);
                            recordText = true;
                        }
                    }
                } else {
                    if (recordText) {
                        String severity = getSeverity(logText);
                        if (severity != null) {
                            entryCreated = true; 
                            addEntry(severity, currentComponent, currentFile.toString(), 
                                    lineNumber, logText );
                            return true;
                        }
                    }
                }
            }
            currentReader.close();
            currentReader = null;
            setCurrentReader(currentReader);
        } catch (Exception ex) {
            log.debug("Exception in AbldLogMetadata", ex);
           try {
               currentReader.close();
           } catch ( IOException iex) {
               // We are Ignoring the errors as no need to fail the build. 
               log.debug("Exception in closing reader", iex);
           }
           currentReader = null;
           setCurrentReader(null);
           exceptions = exceptions + ex.getMessage() + "\n";
           return false;
        }
        if (!exceptions.equals("")) {
            throw new BuildException(exceptions);
        }
        return false;
    }
}