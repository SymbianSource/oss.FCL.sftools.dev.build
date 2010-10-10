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
package com.nokia.helium.core.filesystem.windows.test;

import static org.junit.Assert.assertTrue;

import java.io.File;
import java.util.Locale;
import java.util.Map;

import org.junit.Test;

import com.nokia.helium.core.filesystem.windows.SubstStreamConsumer;

public class TestSubstStreamConsumer {
    
    /**
     * This test should only run on windows as subst is only
     * meaningful on that platform.
     */
    @Test
    public void validateSubstOutputParsing() {
        String osName = System.getProperty("os.name").toLowerCase(Locale.US);
        if (osName.contains("windows")) {
            // Setting up an Ant task
            SubstStreamConsumer consumer = new SubstStreamConsumer();
            consumer.consumeLine("");
            consumer.consumeLine("I:\\: => E:\\Build_E\\buildarea\\tb92_201012");
            consumer.consumeLine("J:\\: => E:\\Build_E\\buildarea\\tb92_201013");
            Map<File, File> substDrives = consumer.getSubstDrives();
            assertTrue(substDrives.size() == 2);
            assertTrue(substDrives.containsKey(new File("I:")));
            assertTrue(substDrives.containsKey(new File("J:")));
            assertTrue(substDrives.containsValue(new File("E:\\Build_E\\buildarea\\tb92_201012")));
            assertTrue(substDrives.containsValue(new File("E:\\Build_E\\buildarea\\tb92_201013")));
        }
    }

}
