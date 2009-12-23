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
    
    private int lineNumber;
    
    private BufferedReader currentReader;

    /**
     * Constructor
     */
    public TextLogMetaDataInput() {
        
    }

    /**
     * Helper function to set the line number
     * @param lineNo to be set for the entry
     */
    protected void setLineNumber(int lineNo) {
        lineNumber = lineNo;
    }

    /**
     * Helper function to return the line number of this entry.
     * @return line number of the entry.
     */
    protected int getLineNumber() {
        return lineNumber;
    }

    /**
     * Helper function to set the reader of this stream
     * @param reader to process the stream.
     */
    protected void setCurrentReader(BufferedReader reader) {
        currentReader = reader;
    }

    /**
     * Function to check if is there any additionaly entry. This is being used for example during streaming
     * recorded and at the end of streaming use the recorded data to add any additional entry. Used by
     * @return true if there are any additional entries which are to be recorded in the database.
     */
    public boolean isAdditionalEntry() {
        return false;
    }

    /**
     * Helper function to return the lbuffer reader for the current meta data input
     * @return buffer reader object for the current metadata input.
     */
    protected BufferedReader getCurrentReader() {
        return currentReader;
    }

    public boolean isEntryCreated(File currentFile) throws Exception {
        String exceptions = "";
        try {
            if (currentReader == null) {
                lineNumber = 0;
                log.debug("Current Text log file name:" + currentFile);
                log.debug("Processing file: " + currentFile);
                currentReader = new BufferedReader(new FileReader(currentFile));
            }
            String logText = null;
            while ((logText = currentReader.readLine()) != null) {
                logText = logText.replaceFirst("^[ ]*\\[.+?\\][ ]*", "");
                String severity = getSeverity(logText);
                if (severity != null) {
                    addEntry(severity, currentFile.getName(), currentFile.toString(), 
                            lineNumber, logText );
                    lineNumber ++;
                    return true;
                }
            }
            currentReader.close();
            currentReader = null;
            if (isAdditionalEntry()) {
                return true;
            }
        } catch (Exception ex) {
            log.debug("Exception in TextLogMetadata", ex);
            try {
                currentReader.close();
                currentReader = null;
            } catch (Exception ex1) {
                // We are Ignoring the errors as no need to fail the build.
                log.debug("Exception in TextLogMetadata", ex1);
                try {
                    currentReader.close();
                } catch ( IOException iex) {
                 // We are Ignoring the errors as no need to fail the build.
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