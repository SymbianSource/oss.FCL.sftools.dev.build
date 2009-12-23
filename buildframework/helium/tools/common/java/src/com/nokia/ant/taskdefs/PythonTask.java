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

import org.apache.tools.ant.*;
import org.apache.tools.ant.taskdefs.*;
import org.apache.tools.ant.types.*;
import java.io.*;

/**
 * Embed python code in ant, generates temporary python file and executes it
 */
public class PythonTask extends Task
{
    private static final String TEMPFILE_PROPERTY = "python.script.tempfile";

    //private ExecTask execTask = new ExecTask();
    
    private String iText;

    private String outputProperty;

    private String resultProperty;

    private String script;
    
    private File dir;
    
    private File output;
    
    private boolean iFailonerror;
    
    private Commandline cmdl = new Commandline();
    
    public PythonTask()
    {
        setTaskName("python");
        /*execTask.setProject(getProject());
        execTask.setTaskName("python");
        execTask.setExecutable("python.exe");*/
    }

    public void setOutputProperty(String propertyname)
    {
        outputProperty = propertyname;
    }

    public void setResultProperty(String propertyname)
    {
        resultProperty = propertyname;
    }

    public void addText(String text)
    {
        iText = getProject().replaceProperties(text);
    }

    public void setScript(String scriptname)
    {
        script = scriptname;
    }
    
    public void setFailonerror(boolean failonerror)
    {
        iFailonerror = failonerror;
    }

    public void setOutput(File outputname)
    {
        output = outputname;
    }
    
    public void setDir(File dirname)
    {
        dir = dirname;
    }
    
    public Commandline.Argument createArg()
    {
        return cmdl.createArgument();
    }
    
   /* private void allAttrSet()
    {
        execTask.setOutputproperty(outputProperty);
        execTask.setResultProperty(resultProperty);
        execTask.setDir(dir);
        execTask.setOutput(output);
    }*/
    
    public void execute()
    {
        if (script != null)
        {
            // Run the Python script
            ExecTask execTask = new ExecTask();
            execTask.setProject(getProject());
            execTask.setTaskName("python");
            execTask.setExecutable("python");
            execTask.setFailonerror(true);
            Commandline.Argument scriptArg = cmdl.createArgument(true);
            scriptArg.setValue(script);
            //allAttrSet();
            execTask.setCommand(cmdl);
            execTask.setOutputproperty(outputProperty);
            execTask.setResultProperty(resultProperty);
            execTask.setDir(dir);
            execTask.setOutput(output);
            try
            {
                execTask.execute();
            }
            catch (BuildException t)
            {
                if (iFailonerror)
                    throw new BuildException(t.getMessage());
                else
                    log(t.getMessage(), 0);     //MSG_ERR=0    
            }
        }
        else
        {            
            // Write the content of the script using Echo task
            File tempfile = null;
            try
            {
                // Create a temporary file to contain the script
                tempfile = File.createTempFile("helium", null);
                PrintWriter out = new PrintWriter(new FileWriter(tempfile));
                out.write(iText);
                out.close();

                // Run the temporary Python script
                ExecTask execTask = new ExecTask();
                execTask.setProject(getProject());
                execTask.setTaskName("python");
                execTask.setExecutable("python");
                execTask.setFailonerror(iFailonerror);
                Commandline.Argument scriptArg = execTask.createArg();
                scriptArg.setValue(tempfile.getAbsolutePath());
                //allAttrSet();
                execTask.setOutputproperty(outputProperty);
                execTask.setResultProperty(resultProperty);
                execTask.setDir(dir);
                execTask.setOutput(output);
                execTask.execute();
            
                // Delete temporary script file
                boolean fileDeleted = tempfile.delete();
                if (!fileDeleted && iFailonerror)
                {
                    throw new BuildException("Could not delete script file!");
                }            
            }
            catch (IOException e)
            {
                if (iFailonerror) {
                    throw new BuildException(e.getMessage());
                }
                log("Error while running python task " + e.getMessage());
            }
            finally
            {
                // make sure we delete the file anyway
                if (tempfile != null)
                    tempfile.delete();
            }
        }
    }

}