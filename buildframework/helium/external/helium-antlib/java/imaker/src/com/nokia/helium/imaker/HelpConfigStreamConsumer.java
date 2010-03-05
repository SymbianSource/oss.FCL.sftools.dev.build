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
package com.nokia.helium.imaker;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * This class implements the help-config output parser for iMaker. 
 * The list of configuration will be stored into an internal list 
 * object. 
 * 
 */
public class HelpConfigStreamConsumer implements StreamConsumer {
    private List<String> configurations = new ArrayList<String>();
    
    /**
     * {@inheritDoc}
     * Only list starting with '/' and ending with '.mk' will be considered.
     */
    @Override
    public void consumeLine(String line) {
        line = line.trim();
        if (line.startsWith("/") && line.endsWith(".mk")) {
            configurations.add(line);
        }
    }
    
    /**
     * Get the list of configurations as File objects.
     * @return
     */
    public List<File> getConfigurations(File epocroot) {
        List<File> confs = new ArrayList<File>();
        for (String config : configurations) {
            confs.add(new File(epocroot, config));
        }
        return confs; 
    }
    
    /**
     * Get the list of configuration as strings.
     * @return the list of configurations
     */
    public List<String> getConfigurations() {
        return configurations;
    }
}
