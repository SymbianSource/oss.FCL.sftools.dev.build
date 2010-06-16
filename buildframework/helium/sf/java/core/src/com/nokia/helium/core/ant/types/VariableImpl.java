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

import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.BuildException;
import org.apache.commons.lang.StringUtils;

import com.nokia.helium.core.ant.MappedVariable;
import java.util.Arrays;

/**
 * Helper class to store the command line variables
 * with name / value pair.
 * @ant.type name="arg" category="Core"
 * @ant.type name="makeOption" category="Core"
 */
public class VariableImpl extends DataType implements MappedVariable
{
    private String name;
    private String value;
    private String cmdLine;
    
    /**
     * Set the name of the variable.
     * @param name
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Get the name of the variable. Will return name is name attribute is set
     * or first command line parameter if line is used.
     * @return name.
     */
    public String getName() {
        if ( cmdLine == null) {
            if (name == null ) { 
                throw new BuildException( "'name' attribute must be defined");
            }
            if (value == null) {
                throw new BuildException( "'value' attribute must be defined");
            }
            return name;
        } else {
            if (name != null  && value != null) { 
                throw new BuildException( "You can define either name, value or line attribute and not both");
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
    public void setValue(String value) {
        this.value = value;
    }

    /**
     * Helper function to set the command line string
     * @param line, string as input to command line.
     */
    public void setLine(String line) {
        cmdLine = line;
    }
    
    /**
     * Get the value of the variable. Returns value if name/value are used, or the line attribute minus 
     * the first command line parameter. 
     * @return value.
     */
    public String getValue() {
        if ( cmdLine == null) {
            if (name == null ) { 
                throw new BuildException( "'name' attribute must be defined");
            }
            if (value == null) {
                throw new BuildException( "'value' attribute must be defined");
            }
            return value;
        } else {
            if (name != null  && value != null) { 
                throw new BuildException( "You can define either name, value or line attribute but not both");
            }
            
            String cmdPart = cmdLine.trim();
            List<String> cmdList = new ArrayList<String>(Arrays.asList(cmdPart.split(" ")));
            if (cmdList.size() > 0) {
                cmdList.remove(0);
            }
            return StringUtils.join(cmdList.toArray(), " "); // "-c armv5 -c foobar" : " armv5 -c foobar"
        }
    }

    /**
     * {@inheritDoc}
     */
    public String getParameter() {
        return getParameter("=");
    }
    
    /**
     * {@inheritDoc}
     */
    public String getParameter(String separator) {
        if ( cmdLine == null) {
            if (name == null ) { 
                throw new BuildException( "'name' attribute must be defined");
            }
            if (value == null) {
                throw new BuildException( "'value' attribute must be defined");
            }
            return name + separator + value;
        } else {
            if (name != null  && value != null) { 
                throw new BuildException( "You can define either name, value or line attribute but not both");
            }
            return cmdLine;
        }
    }

}