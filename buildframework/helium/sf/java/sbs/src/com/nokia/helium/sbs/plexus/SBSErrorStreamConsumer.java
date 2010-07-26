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
package com.nokia.helium.sbs.plexus;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.BufferedWriter;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.log4j.Logger;
import com.nokia.helium.core.plexus.FileStreamConsumer;

/**
 * Record a stream into a file. 
 *
 */
public class SBSErrorStreamConsumer extends FileStreamConsumer {
    private Logger log = Logger.getLogger(SBSErrorStreamConsumer.class);
    private String errorPattern ;
    
    /**
     * Create a FileStreamConsumer which will record content to 
     * the output file.
     * @param output the file to write the output to.
     * @param string 
     * @throws FileNotFoundException if an error occur while opening the file.
     */
    public SBSErrorStreamConsumer(File output, String string) throws FileNotFoundException {
        super(output);
        this.errorPattern = string;
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public synchronized void consumeLine(String line) {
        if (this.errorPattern == null) {
            try {
                BufferedWriter writer = getWriter();
                writer.write("Error:" + line);
                writer.newLine();
            } catch (IOException e) {
                log.error("Error while writing to file: " + e.getMessage(), e);
            }
        } else {
            try {
                Pattern pattern = Pattern.compile(this.errorPattern, Pattern.CASE_INSENSITIVE);
                Matcher match = pattern.matcher(line);
                if (match.find()) {
                    BufferedWriter writer = getWriter();
                    writer.write("Error:" + line);
                    writer.newLine();
                }
                
            } catch (IOException e) {
                log.error("Error while writing to file: " + e.getMessage(), e);
            }
        }
        
    }
}
