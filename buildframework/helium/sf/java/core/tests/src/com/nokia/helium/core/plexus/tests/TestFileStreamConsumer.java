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
package com.nokia.helium.core.plexus.tests;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

import org.junit.Test;
import static org.junit.Assert.*;
import com.nokia.helium.core.plexus.FileStreamConsumer;

public class TestFileStreamConsumer {
    
    @Test
    public void testContentGoesToFile() throws FileNotFoundException, IOException {
        // Setting up an Ant task
        File temp = File.createTempFile("temp_",".log");
        temp.deleteOnExit();
        FileStreamConsumer consumer = new FileStreamConsumer(temp);
        consumer.consumeLine("Hello World!");
        consumer.consumeLine("Bonjour monde!");
        consumer.close();
        assertTrue(temp.length() == 26 + System.getProperty("line.separator").length()*2);
    }

}
