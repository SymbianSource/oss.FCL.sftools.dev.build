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

import org.apache.log4j.Logger;
import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * Record the consumed lines into a StringBuffer.
 *
 */
public class StreamRecorder implements StreamConsumer {
    private Logger log = Logger.getLogger(this.getClass());    
    private StringBuffer buffer = new StringBuffer();
    
    /**
     * Default constructor.
     */
    public StreamRecorder() {
    }

    /**
     * This constructor allows you to set a custom
     * buffer.
     * @param buffer custom buffer object.
     */
    public StreamRecorder(StringBuffer buffer) {
        this.buffer = buffer;
    }

    /**
     * Get the current buffer.
     * @return the current buffer object
     */
    public StringBuffer getBuffer() {
        return buffer;
    }

    /**
     * Set the buffer object.
     * @param buffer custom buffer object.
     */
    public synchronized void setBuffer(StringBuffer buffer) {
        this.buffer = buffer;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public synchronized void consumeLine(String line) {
        log.debug(line);
        buffer.append(line + "\n");
    }
}
