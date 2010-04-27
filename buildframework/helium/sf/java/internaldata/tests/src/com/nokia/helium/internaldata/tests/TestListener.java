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
package com.nokia.helium.internaldata.tests;

import static org.junit.Assert.assertFalse;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

import org.apache.log4j.Level;
import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.taskdefs.Ant;
import org.junit.Test;
import com.nokia.helium.internaldata.ant.listener.Listener;

public class TestListener {
	
	@Test
	public void testInternaldataListener(){
			try {				
				// Create temp file.
				File temp = File.createTempFile("subbuild_test", ".xml"); 
				// Delete temp file when program exits. 
				temp.deleteOnExit(); 
				// Write to temp file 
				BufferedWriter out = new BufferedWriter(new FileWriter(temp)); 
				out.write("<project name=\"test-sub-build\" default=\"test-target2\"><target name=\"test-target2\" /></project>"); 
				out.close(); 
				// Creating a project to test build started and build finished				
			 	Project project = new Project();
			 	Logger log = Logger.getLogger(Listener.class);
			 	log.setLevel(Level.DEBUG);
		        project.addBuildListener(new Listener());
		        project.fireBuildStarted();  	           
		        project.init();
		        project.setName("test-project");
		        // Creating a target to test target started and finished.
		        Target target1 = new Target();
		        target1.setName("test-target");
		        project.addTarget("test-target",target1);
		        // Creating a sub-project to test sub-build started and sub-build finished
		        Ant ant = new Ant();   		        
		        ant.setProject(project);
		        ant.setAntfile(temp.getAbsolutePath());		        
	        
		        target1.addTask(ant);
		        project.executeTarget("test-target");
		        project.fireBuildFinished(null);   
				LogManager.shutdown(); // to flush the log output to file

			} catch (Exception e) {
				System.out.println("Error testing listener: " + e.getMessage() + e);
			}
	        String fileContent = "";
	        String fileName = "hlm_debug.log";
			try {
				BufferedReader br = new BufferedReader(new FileReader(fileName));
				String s;	
				while((s = br.readLine()) != null) {
					fileContent = fileContent + s;
				}	
				br.close();
			}
			catch (Exception e){
				System.out.println("File hlm_debug.log can not be read" + e.getMessage() + e);
			}
			// delete the debug log which we created
		    File f = new File(fileName);
			boolean success = f.delete();
		    if (!success){
		      throw new IllegalArgumentException("Delete: deletion failed");
		    }
			assertFalse(fileContent.contains("Error: error generating the InterData database XML."));
	}
}
