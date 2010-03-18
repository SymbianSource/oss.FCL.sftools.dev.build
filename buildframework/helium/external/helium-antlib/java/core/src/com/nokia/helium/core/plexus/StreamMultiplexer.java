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

import java.util.Vector;
import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * Get the line consumed by a set of StreamConsumer.
 *
 */
public class StreamMultiplexer implements StreamConsumer {

    private Vector<StreamConsumer> handlers = new Vector<StreamConsumer>(); 
    
    /**
     * Add an StreamConsumer to the multiplexing. 
     * @param handler the StreamConsumer to add.
     */
    public void addHandler(StreamConsumer handler) {
        handlers.add(handler);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void consumeLine(String line) {
        for (StreamConsumer handler : handlers) {
            handler.consumeLine(line);
        }
    }

}
