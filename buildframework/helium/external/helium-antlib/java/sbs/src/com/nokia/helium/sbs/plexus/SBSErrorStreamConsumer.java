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

import org.apache.log4j.Logger;
import com.nokia.helium.core.plexus.FileStreamConsumer;

/**
 * Record a stream into a file. 
 *
 */
public class SBSErrorStreamConsumer extends FileStreamConsumer {
    private Logger log = Logger.getLogger(SBSErrorStreamConsumer.class);
    
    /**
     * Create a FileStreamConsumer which will record content to 
     * the output file.
     * @param output the file to write the output to.
     * @throws FileNotFoundException if an error occur while opening the file.
     */
    public SBSErrorStreamConsumer(File output) throws FileNotFoundException {
        super(output);
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public synchronized void consumeLine(String line) {
        try {
            BufferedWriter writer = getWriter();
            writer.write("[SBSTASK:] Error:" + line);
            writer.newLine();
        } catch (IOException e) {
            log.error("Error while writing to file: " + e.getMessage(), e);
        }
    }
}
