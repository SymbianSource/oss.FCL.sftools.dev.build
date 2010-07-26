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
package com.nokia.helium.sbs.tests;

import static org.junit.Assert.assertTrue;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;

import org.junit.Test;

import com.nokia.helium.sbs.plexus.SBSErrorStreamConsumer;


public class TestSBSErrorStreamConsumer {
	
	@Test
	public void testSBSErrorStreamConsumerValid() throws Exception {	
		File file = File.createTempFile("sbs_unit_test", ".txt"); 
		file.deleteOnExit();
		File testFile = new File(file.getAbsolutePath());
		String line = "Error: This is a sample error for unit testing";		

		SBSErrorStreamConsumer sbsErrorConsumer = null;
		sbsErrorConsumer = new SBSErrorStreamConsumer(testFile, null);
		sbsErrorConsumer.consumeLine(line);
		sbsErrorConsumer.close();      
		String fileContent = null;
		try {
			BufferedReader br = new BufferedReader(new FileReader(file.getAbsolutePath()));
			String s;	
			while((s = br.readLine()) != null) {
				fileContent = fileContent + s;
			}	
			br.close();
		}
		catch (Exception e){
			System.out.println("File "+file.getAbsolutePath()+" can not be read" + e.getMessage() + e);
		}
		assertTrue(fileContent.contains("Error:Error: This is a sample error for unit testing"));
	}
}
