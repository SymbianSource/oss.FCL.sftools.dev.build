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

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.nokia.helium.core.plexus.FileStreamConsumer;
import org.apache.log4j.Logger;


/**
 * Record a stream into a file. 
 *
 */
public class CoverityErrorStreamConsumer extends FileStreamConsumer {
    
    private Logger log = Logger.getLogger(CoverityErrorStreamConsumer.class);
    /**
     * @param output
     * @throws FileNotFoundException
     */
    public CoverityErrorStreamConsumer(File output) throws FileNotFoundException {
        super(output);
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public synchronized void consumeLine(String line) {
        try {
            Pattern pattern = Pattern.compile("ERROR", Pattern.CASE_INSENSITIVE);
            Matcher match = pattern.matcher(line);
            if (match.find()) {
                BufferedWriter writer = getWriter();
                writer.write("[SBSCoverity:] Error:" + line);
                writer.newLine();
            }
            
        } catch (IOException e) {
            log.error("Error while writing to file: " + e.getMessage(), e);
        }
    }
    
    
    

}
