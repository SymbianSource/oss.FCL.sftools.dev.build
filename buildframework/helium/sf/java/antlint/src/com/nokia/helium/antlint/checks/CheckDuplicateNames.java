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
package com.nokia.helium.antlint.checks;

import java.util.ArrayList;
import java.util.Hashtable;

/**
 * <code>CheckDuplicateNames</code> is used to check for duplicate macro names.
 *
 */
public class CheckDuplicateNames extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public void run() {

        Hashtable<String, Class<Object>> taskdefs = getProject()
                .getTaskDefinitions();
        ArrayList<String> macros = new ArrayList<String>(taskdefs.keySet());
        for (String macroName : macros) {
            if (macros.contains(macroName + "Macro")
                    || macros.contains(macroName + "macro"))
                log(macroName + " and " + macroName + "Macro"
                        + " found duplicate name");
        }
    }

}
