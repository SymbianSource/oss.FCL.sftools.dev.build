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
 
package com.nokia.ant.taskdefs;

import java.io.IOException;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.Project;
import org.dom4j.DocumentException;

import com.nokia.ant.ModelPropertiesParser;


/**
 * Renders model property and group description to Wiki Model Syntax.
 * Usage: &lt;hlm:parsemodel output="Output file path" input="Input file path"/&gt;
 * @ant.task name="parsemodel"
 */
public class ModelPropertiesTask extends Task
{
    private String outputFile;

    private String inputFile;
    
    public ModelPropertiesTask()
    {
        setTaskName("ModelPropertiesTask");
    }

    public void setOutput(String outputFile)
    {
        this.outputFile = outputFile;
    }

    public void setInput(String inputFile)
    {
        this.inputFile = inputFile;
    }

    /**
     * Executes ModelPropertyParser
     * @throws BuildException
     */    
    public void execute()
    {
        log("Parsing model properties ", Project.MSG_DEBUG);
        try
        {
            ModelPropertiesParser pmp = new ModelPropertiesParser(inputFile, outputFile);
            pmp.parsePropertiesDescription();
        }
        catch (IOException ioe)
        {
            throw new BuildException("Couldn't find model file" + ioe.getMessage());
        }
        catch (DocumentException be)
        {
            throw new BuildException("Error in creating model dom object " + be.getMessage());
        }
    }
}
