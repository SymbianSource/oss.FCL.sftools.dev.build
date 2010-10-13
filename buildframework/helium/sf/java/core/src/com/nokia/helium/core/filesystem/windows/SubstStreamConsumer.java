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
package com.nokia.helium.core.filesystem.windows;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * Parse subst output.
 *
 */
public class SubstStreamConsumer implements StreamConsumer {
    private Map<File, File> substDrives = new HashMap<File, File>();

    /**
     * {@inheritDoc}
     */
    @Override
    public void consumeLine(String line) {
        if (line.trim().length() > 0) {
            substDrives.put( new File(line.substring(0, 2)), new File(line.substring(8)));
        }
    }
    
    /**
     * Get the mapping between subst drive and folder.
     * @return the mapping.
     */
    public Map<File, File> getSubstDrives() {
        return substDrives;
    }
}
