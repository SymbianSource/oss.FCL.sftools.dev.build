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
 
package com.nokia.helium.core.ant.types;

import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.BuildException;
import org.apache.log4j.Logger;

/**
 * Helper class to store the command line variables
 * with name / value pair.
 * @ant.type name="arg" category="Core"
 * @ant.type name="makeOption" category="Core"
 */
public class Variable extends DataType
{
    private static Logger log = Logger.getLogger(Variable.class);
    private String name;
    private String value;
    private String cmdLine;

    
    public Variable() {
    }
    
    /**
     * Set the name of the variable.
     * @param name
     */
    public void setName(String nm) {
        name = nm;
    }

    
    /**
     * Get the name of the variable.
     * @return name.
     */
    public String getName() {
        if ( cmdLine == null) {
            if (name == null ) { 
                throw new BuildException( "name should not be null");
            }
            if (value == null) {
                throw new BuildException( "value should not be null");
            }
            return name;
        } else {
            if (name != null  && value != null) { 
                throw new BuildException( "you can define either name, value or line attribute and not both");
            }
            String cmdPart = cmdLine.trim();
            String[] cmdArgs = cmdPart.split(" ");
            return cmdArgs[0];
        }
    }

    /**
     * Set the value of the variable.
     * @param value
     */
    public void setValue(String vlue) {
        value = vlue;
    }

    /**
     * Helper function to set the command line string
     * @param line, string as input to command line.
     */
    public void setLine(String line) {
        cmdLine = line;
    }
    
    /**
     * Get the value of the variable.
     * @return value.
     */
    public String getValue() {
        if ( cmdLine == null) {
            if (name == null ) { 
                throw new BuildException( "name should not be null");
            }
            if (value == null) {
                throw new BuildException( "value should not be null");
            }
            return value;
        } else {
            if (name != null  && value != null) { 
                throw new BuildException( "you can define either name, value or line attribute and not both");
            }
            return cmdLine;
        }
    }
    /**
     * Get the command line parameter
     * @return command line string.
     */
    public String getParameter() {
        if ( cmdLine == null) {
            if (name == null ) { 
                throw new BuildException( "name should not be null");
            }
            if (value == null) {
                throw new BuildException( "value should not be null");
            }
            return name + "=" + value;
        } else {
            if (name != null  && value != null) { 
                throw new BuildException( "you can define either name, value or line attribute and not both");
            }
            return cmdLine;
        }
    }

}