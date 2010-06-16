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
 * This Type is to specify and use the abld logparser type to parse and store
 * the data.
 * 
 * <pre>
 * &lt;hlm:metadatafilterset id="abld.metadata.filter"&gt;
 *    &lt;metadatafilterset filterfile="common.csv" /&gt;
 * &lt;/hlm:metadatafilterset&gt;
 * 
 * &lt;hlm:imakermetadatainput&gt;
 *    &lt;fileset dir="${project.dir}/../data/"&gt;
 *        &lt;include name="*_compile*.log"/&gt;
 *    &lt;/fileset&gt;
 *    &lt;metadatafilterset refid="abld.metadata.filter" /&gt;
 * &lt;/hlm:imakermetadatainput&gt;
 * </pre>
 * 
 * @ant.task name="imakermetadatainput" category="Metadata"
 */
public class IMakerLogMetaDataInput extends TextLogMetaDataInput {

    /** Internal data storage. */
    private class Entry {

        private String fileName;
        private int lineNumber;
        private String text;
        private String severity;

        public Entry(String fileName, int lineNumber, String text, String severity) {
            super();
            this.text = text;
            this.lineNumber = lineNumber;
            this.fileName = fileName;
            this.severity = severity;
        }

        public String getText() {
            return text;
        }

        public int getLineNumber() {
            return lineNumber;
        }

        public String getFileName() {
            return fileName;
        }

        public String getSeverity() {
            return severity;
        }

    }

    private Logger log = Logger.getLogger(AbldLogMetaDataInput.class);

    private Pattern iMakerFpsxPattern = Pattern.compile("/([^/]*?\\.fpsx)");

    private String currentComponent;

    private boolean entryCreated;

    private boolean isRecordingIssues;

    public IMakerLogMetaDataInput() {
    }

    /**
     * Function to check from the input stream if is there any entries
     * available.
     * 
     * @return true if there are any entry available otherwise false.
     */
    public boolean isEntryCreated(File currentFile) {
        String exceptions = "";
        entryCreated = false;
        int lineNumber = getLineNumber();
        BufferedReader currentReader = getCurrentReader();
        log.debug("Getting next set of log entries for iMaker input");
        try {
            if (currentReader == null) {
                lineNumber = 0;
                setLineNumber(lineNumber);
                log.debug("Processing iMaker log file name: " + currentFile);
                currentReader = new BufferedReader(new FileReader(currentFile));
                setCurrentReader(currentReader);
            }

            List<Entry> entriesCache = new ArrayList<Entry>();
            String logText = null;
            while ((logText = currentReader.readLine()) != null) {
                lineNumber++;
                setLineNumber(lineNumber);

                // Remove Ant task comment text, e.g. "[imaker]"
                logText = logText.replaceFirst("'^\\s*\\[.+?\\]\\s*", "");
                // log.debug("Parsing log line: " + logText);

                // See if the line should be captured
                if (isRecordingIssues) {
                    // Check for a line with an issue
                    String severity = getSeverity(logText);
                    if (severity != null) {
                        Entry entry = new Entry(currentFile.toString(), lineNumber, logText, severity);
                        entriesCache.add(entry);
                    }

                    // Check if the iMaker FPSX image name is on this line, to
                    // get the component
                    if (currentComponent == null) {
                        Matcher componentMatch = iMakerFpsxPattern.matcher(logText);
                        if (componentMatch.find()) {
                            currentComponent = componentMatch.group(1);
                            log.debug("Matched component: " + currentComponent);
                        }
                    }

                    // See if the component log block has ended
                    if (logText.startsWith("++ Finished at")) {
                        // Add all cached issues
                        if (currentComponent != null && entriesCache.size() > 0) {
                            for (int i = 0; i < entriesCache.size(); i++) {
                                Entry entry = entriesCache.get(i);
                                addEntry(entry.getSeverity(), currentComponent, entry.getFileName(), entry.getLineNumber(), entry.getText());
                            }
                            entryCreated = true;
                            currentComponent = null;
                            return true;
                        }
                        // Or add a default entry to record the logfile
                        else {
                            addEntry("DEFAULT", currentComponent, currentFile.toString(), lineNumber, "");
                            entryCreated = true;
                            currentComponent = null;
                            return true;
                        }
                    }
                }
                else {
                    // Check for the start of a block
                    if (logText.startsWith("++ Started at")) {
                        isRecordingIssues = true;
                    }
                }
            }
            currentReader.close();
            currentReader = null;
            setCurrentReader(currentReader);
        }
        catch (FileNotFoundException ex) {
            log.debug("FileNotFoundException in AbldLogMetadata", ex);
            try {
                if (currentReader != null) {
                    currentReader.close();
                }
            }
            catch (IOException iex) {
                // We are Ignoring the errors as no need to fail the build.
                log.debug("Exception in closing reader", iex);
            }
            currentReader = null;
            setCurrentReader(null);
            exceptions = exceptions + ex.getMessage() + "\n";
            return false;
        }
        catch (IOException ex) {
            log.debug("IOException in AbldLogMetadata", ex);
            try {
                if (currentReader != null) {
                    currentReader.close();
                }
            }
            catch (IOException iex) {
                // We are Ignoring the errors as no need to fail the build.
                log.debug("IOException in closing reader", iex);
            }
            currentReader = null;
            setCurrentReader(null);
            exceptions = exceptions + ex.getMessage() + "\n";
            return false;
        }
        if (!exceptions.equals("")) {
            throw new BuildException(exceptions);
        }
        return entryCreated;
    }
}
