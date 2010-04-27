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
import java.io.File;
import java.io.FileReader;


import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.LogManager;
import org.junit.Test;




import com.nokia.helium.internaldata.ant.listener.EmailDataSender;

public class TestEmailDataSender {
	
	@Test
	public void testSendData(){
		EmailDataSender emailDataSender = new EmailDataSender();
		Logger log = Logger.getLogger(EmailDataSender.class);
		log.setLevel(Level.DEBUG);
		emailDataSender.sendData("Helium antlib internaldata junit test");	
		LogManager.shutdown(); // to flush the log output to file
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
		assertFalse(fileContent.contains("Internal data failure:"));
	}		
}


