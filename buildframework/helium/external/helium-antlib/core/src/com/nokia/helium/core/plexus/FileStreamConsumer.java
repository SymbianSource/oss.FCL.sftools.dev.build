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
package com.nokia.helium.core.plexus;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.BufferedWriter;

import org.apache.log4j.Logger;
import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * Record a stream into a file. 
 *
 */
public class FileStreamConsumer implements StreamConsumer {
    private Logger log = Logger.getLogger(getClass());
    private BufferedWriter writer;
    
    /**
     * Create a FileStreamConsumer which will record content to 
     * the output file.
     * @param output the file to write the output to.
     * @throws FileNotFoundException if an error occur while opening the file.
     */
    public FileStreamConsumer(File output) throws FileNotFoundException {
        writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(output)));
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public synchronized void consumeLine(String line) {
        try {
            writer.write(line);
            writer.newLine();
        } catch (IOException e) {
            log.error("Error while writing to file: " + e.getMessage(), e);
        }
    }
    
    /**
     * Closing the file.
     */
    public void close() {
        try {
            writer.flush();
            writer.close();
        } catch (IOException e) {
            log.error("Error while writing to file: " + e.getMessage(), e);
        }
    }

    /**
     * Helper function to return the writer instance for sub classes
     * to write if any additional information.
     * @return writer of the stream consumer. 
     */
    public BufferedWriter getWriter() {
        return writer;
    }
}
