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

import java.io.File;

import org.apache.tools.ant.Project;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import com.nokia.helium.signal.ant.types.EMAILNotifier;
import com.nokia.helium.signal.ant.types.NotifierInput;
import com.nokia.helium.signal.ant.types.NotifyWhenEnum;

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
    public void test_simpleEmailNotification() throws Exception {
        EMAILNotifier en = new EMAILNotifier();
        Project p = new Project();
        p.setNewProperty("user.name", "test");
        en.setProject(p);
        en.setNotifyWhen((NotifyWhenEnum)NotifyWhenEnum.getInstance(NotifyWhenEnum.class, "always"));
        en.setTitle("test");
        en.setSmtp("test");
        en.setLdap("test");
        NotifierInput input = new NotifierInput(p);
        input.setFile(new File(System.getProperty("testdir") + "/tests/data/test.log_status.html"));
        en.sendData("test", true, input, "Test Message");
    }

    /**
     * This test should not fail the build, when no log are found, or default template 
     * is missing just skip the notification and log an error.
     * @throws Exception
     */
    public void test_emailNotificationWithoutNotifyFileAndTemplate() throws Exception {
        EMAILNotifier en = new EMAILNotifier();
        Project p = new Project();
        p.setNewProperty("user.name", "test");
        en.setProject(p);
        en.setNotifyWhen((NotifyWhenEnum)NotifyWhenEnum.getInstance(NotifyWhenEnum.class, "always"));
        en.setTitle("test");
        en.setSmtp("test");
        en.setLdap("test");
        NotifierInput input = new NotifierInput(p);
        en.sendData("test", true, input, "Test Message");
    }   

}