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

package com.nokia.helium.signaling.tests;

import org.junit.*;
import static org.junit.Assert.*;
import java.io.*;
import java.util.*;
import com.nokia.helium.signal.ant.types.*;
import org.apache.tools.ant.Project;

public class TestEmailSender {
    
    @Before
    public void setUp() {
    }

    @After
    public void tearDown() {
    }
    
    /**
     * @throws Exception
     */
    @Test
    public void test_simpleMergeNode() throws Exception {
        EMAILNotifier en = new EMAILNotifier();
        Project p = new Project();
        p.setNewProperty("user.name", "test");
        en.setProject(p);
        en.setNotifyWhen("always");
        en.setTitle("test");
        en.setSmtp("test");
        en.setLdap("test");
        NotifierInput input = new NotifierInput();
        input.setFile(new File(System.getProperty("testdir") + "/tests/test_signal/data/test.log_status.html"));
        en.sendData("test", true, input, "Test Message");
    }

   

}