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
package com.nokia.helium.metadata.ant.types;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.EnumeratedAttribute;

/**
 * Defines an Ant enumerated type for the severity. 
 */
public class SeverityEnum extends EnumeratedAttribute {

    /**
     * Defines a list of enumerated severities.
     */
    public enum Severity {
        FATAL("FATAL"), ERROR("ERROR"), CRITICAL("CRITICAL"), WARNING("WARNING"), REMARK(
                "REMARK"), INFO("INFO"), NONE("NONE");
        
        private final String value;

        Severity(String value) {
            this.value = value;
        }

        public String toString() {
            return this.value;
        }
    }

    private static String[] values;
    
    static {
        // Let's support upper case and lower case string.
        values = new String[Severity.values().length * 2];
        int i = 0;
        for (Severity severity : Severity.values()) {
            values[i++] = severity.toString();
            values[i++] = severity.toString().toLowerCase();
        }
    }

    /**
     * Get the list of supported severity types.
     * @return List of supported severity types.
     */
    @Override
    public String[] getValues() {
        return values;
    }

    /**
     * Get the severity as a Severity enum.
     * @return The severity value.
     */
    public Severity getSeverity() {
        for (Severity severity : Severity.values()) {
            if (severity.toString().equalsIgnoreCase(getValue())) {
                return severity;
            }
        }
        throw new BuildException("Invalid severity: " + getValue());
    }

}
