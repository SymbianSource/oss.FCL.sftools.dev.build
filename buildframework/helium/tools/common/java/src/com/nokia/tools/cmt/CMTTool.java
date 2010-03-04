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
 
package com.nokia.tools.cmt;

import com.nokia.helium.core.ant.types.VariableSet;
import com.nokia.helium.core.ant.types.Variable;
import com.nokia.tools.*;
import java.io.File;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.FileSet;
import java.io.FileWriter;
import java.io.BufferedWriter;
import org.apache.tools.ant.DirectoryScanner;
import org.apache.log4j.Logger;



/**
 * Command Line wrapper for configuration tools
 */
public class CMTTool implements Tool {
    
    private Logger log = Logger.getLogger(CMTTool.class);

    /**
     * Sets the command line variables to be used to execute and validates
     * for the required parameters 
     * @param varSet variable(name / value list)
     */    
       public void execute(VariableSet varSet, Project prj)throws ToolsProcessException {
        String input = null; 
        String output = null;
        String config = null;
        String pattern = null;
        String keepGoing = "false";
        String varName;
        String value;
        for (Variable variable : varSet.getVariables()) {
            varName = variable.getName();
            value = variable.getValue();
            if (varName.equals("input")) {
                input = value;
            } else if (varName.equals("config")) {
                config = value;
            } else if (varName.equals("output")) {
                output = value;
            } else if (varName.equals("pattern")) {
                pattern = value;
            }
        }
           if (input == null ) {
               throw new ToolsProcessException("CMTTool 'input' Parameter missing");
           }
           
           if ( output == null ) {
               throw new ToolsProcessException("CMTTool 'output' Parameter missing");
           }
           
           if ( pattern == null) {
               throw new ToolsProcessException("CMTTool 'pattern' Parameter missing");
           }
           generateFileList(input, output,pattern, prj);
           try {
             org.apache.tools.ant.taskdefs.ExecTask task = new org.apache.tools.ant.taskdefs.ExecTask();
             task.setDir(new File(prj.getProperty("build.drive")));
             task.setTaskName("cmttool");
             task.setExecutable("cmt.exe");
             task.createArg().setValue("-f");
             task.createArg().setValue(input + System.getProperty("file.separator") + "files.lst");
             task.createArg().setValue("-o");
             task.createArg().setValue(output);
             task.execute();
             org.apache.tools.ant.taskdefs.ExecTask cmt2task = new org.apache.tools.ant.taskdefs.ExecTask();
             File outputdir = new File(output.replace(".txt", "_cmt"));
             outputdir.mkdir();
             cmt2task.setDir(outputdir); 
             cmt2task.setTaskName("cmt2html");
             cmt2task.setExecutable("cmt2html.bat");
             cmt2task.createArg().setValue("-i");
             cmt2task.createArg().setValue(output);
             cmt2task.createArg().setValue("-nsb");
             cmt2task.execute();
        } catch (Exception e1) {
         // We are Ignoring the errors as no need to fail the build.
            log.error(e1.getMessage());
        }       
    }
    
    private void generateFileList(String input,String output, String pattern, Project prj) {
        FileSet fileset = new FileSet();
        String [] includes = pattern.split(",");
        fileset.setDir(new File(input));
        fileset.setProject(prj);
        fileset.appendIncludes(includes);
        DirectoryScanner ds = fileset.getDirectoryScanner();
        ds.scan();
        String [] filelist = ds.getIncludedFiles();
        String fileSeparator = System.getProperty("file.separator");
        File fileList = new File(input + fileSeparator + "files.lst");
        try {
            BufferedWriter outputFile = new BufferedWriter(new FileWriter(fileList));
            for (int i = 0; i < filelist.length; i++ ) {
                outputFile.write(input + fileSeparator  + filelist[i] + "\n");
            }
            outputFile.close();
        } catch (Exception e) {
            // We are Ignoring the errors as no need to fail the build.
            log.error(e.getMessage());
            e.printStackTrace();
        }
    }
}