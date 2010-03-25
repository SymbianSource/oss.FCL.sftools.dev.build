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

import java.util.ArrayList;
import java.util.List;

import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 *  Helper class to parse the output form help-target-*-list. 
 *
 */
public class HelpTargetListStreamConsumer implements StreamConsumer {

    private List<String> targets = new ArrayList<String>();
    
    /**
     * {@inheritDoc}
     * iMaker targets should match the following patterns to be selected: [A-za-z0-9\\-_%]+.
     */
    @Override
    public void consumeLine(String line) {
        line = line.trim();
        if (line.matches("^[A-za-z0-9\\-_%]+$")) {
            targets.add(line);
        }
    }

    /**
     * Get the list of found targets.
     * @return the target list.
     */
    public List<String> getTargets() {
        return targets;
    }

}
