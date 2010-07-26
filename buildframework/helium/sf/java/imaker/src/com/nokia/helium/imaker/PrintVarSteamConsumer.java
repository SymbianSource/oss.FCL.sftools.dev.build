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

import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * Parsing iMaker printvar calls.
 * Output from iMaker should match:
 * NAME = `some content'
 *
 */
public class PrintVarSteamConsumer implements StreamConsumer {

    private String name;
    private String value;
    private boolean inParsing;
    
    /**
     * Construct a PrintVarSteamConsumer for a variable named by name.
     * @param name
     */
    public PrintVarSteamConsumer(String name) {
        this.name = name;
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void consumeLine(String line) {
        String varPrefix = name + " = `";
        if (!inParsing && line.startsWith(varPrefix)) {
            value = line.substring(varPrefix.length());
            inParsing = true;
        } else if (inParsing) {
            value += "\n" + line;
        }
        if (value != null && value.endsWith("'")) {
            value = value.substring(0, value.length() - 1);
            inParsing = false;
        }
    }
    
    /**
     * Get the variable value returned by iMaker.
     * @return the variable content return by iMaker.
     */
    public String getValue() {
        return value;
    }

}
