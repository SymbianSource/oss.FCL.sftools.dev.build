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
import java.util.*;
import org.apache.log4j.Logger;

/**
 * This Type is to specify and use the text logparser type to parse and store the data.
 *
 * <pre>
 * &lt;hlm:metadatafilterset id="text_log_metadata_input"&gt;
 *    &lt;metadatafilterset filterfile="${project.dir}/../data/common.csv" /&gt;
 * &lt;/hlm:metadatafilterset&gt;
 * 
 * &lt;hlm:textmetadatainput&gt;
 *    &lt;fileset dir="${project.dir}/../data/"&gt;
 *        &lt;include name="*_fixslashes*.log"/&gt;
 *    &lt;/fileset&gt;
 *    &lt;metadatafilterset refid="text_log_metadata_input" /&gt;
 * &lt;/hlm:textmetadatainput&gt;
 * </pre>
 * 
 * @ant.task name="textmetadatainput" category="Metadata"
 */
public class TextLogMetaDataInput extends LogMetaDataInput {

    private Logger log = Logger.getLogger(TextLogMetaDataInput.class);
    
    private int currentFileIndex;
    
    private int lineNumber;
    
    private BufferedReader currentReader;

    public TextLogMetaDataInput() {
        
    }
    
    protected void setCurrentFileIndex(int fileIndex) {
        currentFileIndex = fileIndex;
    }

    protected void setLineNumber(int lineNo) {
        lineNumber = lineNo;
    }

    protected int getCurrentFileIndex() {
        return currentFileIndex;
    }
    
    protected int getLineNumber() {
        return lineNumber;
    }

    protected void setCurrentReader(BufferedReader reader) {
        currentReader = reader;
    }
    
    protected BufferedReader getCurrentReader() {
        return currentReader;
    }

    public boolean isEntryAvailable() throws Exception {
        //Todo: Optimize the function so the most of the statements could
        //be reused with other metadata input.
        String exceptions = "";
        //log.debug("Getting next set of log entries for Text Input");
        //log.debug("currentFileIndex" + currentFileIndex);
        List<File> fileList = getFileList();
        //log.debug("is filelist empty" + fileList.isEmpty());
        int fileListSize = fileList.size();
        while (currentFileIndex < fileListSize) {
            try {
                //log.debug("currentfileindex while getting file name: " + currentFileIndex);
                File currentFile = fileList.get(currentFileIndex);
                if (currentReader == null) {
                    lineNumber = 0;
                    log.debug("Current Text log file name:" + currentFile);
                    log.info("Processing file: " + currentFile);
                    currentReader = new BufferedReader(new FileReader(currentFile));
                }
                String logText = null;
                while ((logText = currentReader.readLine()) != null) {
                    //log.debug("logtext : " + logText + " line-number: " + lineNumber);
                    //log.debug("logtext : " + logText + " line-number: " + lineNumber);
                    logText = logText.replaceFirst("^[ ]*\\[.+?\\][ ]*", "");
                    String severity = getSeverity(logText);
                    if (severity != null) {
//                        log.debug("severity:" + severity);
//                        log.debug("currentFile:" + currentFile);
//                        log.debug("lineNumber:" + lineNumber);
//                        log.debug("logText:" + logText);
                        
                        addEntry(severity, currentFile.getName(), currentFile.toString(), 
                                lineNumber, logText );
                        lineNumber ++;
                        return true;
                    }
                    lineNumber ++;
                }
                currentReader.close();
                currentReader = null;
                currentFileIndex ++;
            } catch (Exception ex) {
                log.debug("Exception in TextLogMetadata", ex);
                try {
                    currentReader.close();
                } catch ( IOException iex) {
                    log.info("exception in closing reader");
                    log.debug("Exception in closing reader", iex);
                }
                currentReader = null;
                exceptions = exceptions + ex.getMessage() + "\n";
                return false;
            }
        }
        if (!exceptions.equals("")) {
            throw new Exception(exceptions);
        }
        
        return false;
    }
}