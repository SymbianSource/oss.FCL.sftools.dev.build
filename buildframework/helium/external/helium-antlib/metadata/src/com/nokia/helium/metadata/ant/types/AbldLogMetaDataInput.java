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

    public boolean isEntryAvailable() {
        String exceptions = "";
        int currentFileIndex = getCurrentFileIndex();
        int lineNumber = getLineNumber(); 
        BufferedReader currentReader = getCurrentReader();
        
        log.debug("Getting next set of log entries for Abld Input");
        //log.debug("currentFileIndex" + currentFileIndex);
        List<File> fileList = getFileList();
        int fileListSize = fileList.size();
        log.debug("fileList.size" + fileListSize);
        while (currentFileIndex < fileListSize) {
            try {
                //log.debug("currentfileindex while getting file name: " + currentFileIndex);
                File currentFile = fileList.get(currentFileIndex);
                if (currentReader == null) {
                    lineNumber = 0;
                    setLineNumber(lineNumber);
                    log.debug("Current abld log file name:" + currentFile);
                    log.info("Processing file: " + currentFile);
                    currentReader = new BufferedReader(new FileReader(currentFile));
                    setCurrentReader(currentReader);
                }
                String logText = null;
                while ((logText = currentReader.readLine()) != null) {
                    lineNumber ++;
                    setLineNumber(lineNumber);
                    logText = logText.replaceFirst("'^\\s*\\[.+?\\]\\s*", "");
                    if (logText.startsWith("++ Finished at")) {
                        //log.debug("matching finished regex");
                        if (currentComponent != null && !entryCreated) {
                            addEntry("DEFAULT", currentComponent, currentFile.toString(), 
                                    0, "" );
                            entryCreated = true;
                            recordText = false;
                            return true;
                        }
                        entryCreated = false;
                    } else if (logText.startsWith("=== ")) {
                        //log.debug("trying to match with finish pattern =======");
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
                            //log.debug("trying to match the start pattern");
                            Matcher componentMatch = abldComponentPattern.matcher(logText);
                            if (componentMatch.matches()) {
                                //log.debug("matched abldComponentPattern");
                                currentComponent = componentMatch.group(2);
                                recordText = true;
                            }

                            Matcher startMatch = abldStartedPattern.matcher(logText);
                            if (startMatch.matches()) {
                                //log.debug("matched abldStartedPattern");
                                currentComponent = startMatch.group(1);
                                recordText = true;
                            }
                        }
                    } else {
                        if (recordText) {
                            String severity = getSeverity(logText);
                            if (severity != null) {
                                //log.debug("severity:" + severity);
                                //log.debug("currentFile:" + currentFile);
                                //log.debug("lineNumber:" + lineNumber);
                                //log.debug("logText:" + logText);
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
                currentFileIndex ++;
                setCurrentFileIndex(currentFileIndex);
                //log.debug("currentfileindex: " + currentFileIndex);
                //log.debug("fileListSize: " + fileListSize);
            } catch (Exception ex) {
                log.debug("Exception in AbldLogMetadata", ex);
               try {
                   currentReader.close();
               } catch ( IOException iex) {
                   log.debug("Exception in closing reader");
               }
               currentReader = null;
               setCurrentReader(null);
               exceptions = exceptions + ex.getMessage() + "\n";
               return false;
            }
        }
        if (!exceptions.equals("")) {
            throw new BuildException(exceptions);
        }
        return false;
    }
}