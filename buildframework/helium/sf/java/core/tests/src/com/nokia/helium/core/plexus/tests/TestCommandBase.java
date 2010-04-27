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

import hidden.org.codehaus.plexus.interpolation.os.Os;

import java.util.Hashtable;

import org.junit.Test;
import static org.junit.Assert.*;

import com.nokia.helium.core.plexus.CommandBase;
import com.nokia.helium.core.plexus.StreamRecorder;

/**
 * Unittests for the CommandBase class. 
 *
 */
public class TestCommandBase {

    /**
     * The simplest possible implementation possible.
     *
     */
    public class CommandImpl extends CommandBase<Exception> {

        @Override
        protected String getExecutable() {
            if (Os.isFamily(Os.FAMILY_WINDOWS)) {
                return "echo";
            } else {
                return System.getProperty("testdir") +  "/tests/echo.sh";
            }
        }

        @Override
        protected void throwException(String message, Throwable t)
                throws Exception {
            throw new Exception(message, t);
        }
        
    }
    
    @Test
    public void simpleExecution() {
        CommandImpl cmd = new CommandImpl();
        try {
            cmd.execute(null);
        } catch (Exception e) {
            fail("Exception should not happen.");
        }

    }

    @Test
    public void simpleExecutionWithArgs() {
        CommandImpl cmd = new CommandImpl();
        String args[] = new String[2];
        args[0] = "foo";
        args[1] = "bar";
        try {
            cmd.execute(args);
        } catch (Exception e) {
            fail("Exception should not happen.");
        }
    }
    
    @Test
    public void simpleExecutionWithArgsAndRecorder() throws Exception {
        CommandImpl cmd = new CommandImpl();
        String args[] = new String[2];
        args[0] = "foo";
        args[1] = "bar";
        StreamRecorder rec = new StreamRecorder();
        cmd.execute(args, rec);
        assertTrue(rec.getBuffer().toString().startsWith("foo bar"));
    }

    @Test
    public void simpleExecutionWithArgsAndRecorderAsOutputHandler() throws Exception {
        CommandImpl cmd = new CommandImpl();
        StreamRecorder rec = new StreamRecorder();
        cmd.addOutputLineHandler(rec);
        String args[] = new String[2];
        args[0] = "foo";
        args[1] = "bar";
        cmd.execute(args, rec);
        assertTrue(rec.getBuffer().toString().startsWith("foo bar"));
    }

    @Test
    public void simpleExecutionWithEnv() throws Exception {
        CommandImpl cmd = new CommandImpl();
        StreamRecorder rec = new StreamRecorder();
        cmd.addOutputLineHandler(rec);
        String args[] = new String[2];
        if (Os.isFamily(Os.FAMILY_WINDOWS)) {
            args[0] = "%TEST_FOO%";
            args[1] = "%TEST_BAR%";
        } else {
            args[0] = "$TEST_FOO";
            args[1] = "$TEST_BAR";
        }
        Hashtable<String, String> env = new Hashtable<String, String>();
        env.put("TEST_FOO", "foo");
        env.put("TEST_BAR", "bar");
        cmd.execute(args, env, rec);
        assertTrue(rec.getBuffer().toString().startsWith("foo bar"));
    }

}
