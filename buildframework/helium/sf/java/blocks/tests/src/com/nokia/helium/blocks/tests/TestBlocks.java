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

package com.nokia.helium.blocks.tests;

import java.io.File;

import com.nokia.helium.blocks.Blocks;
import com.nokia.helium.blocks.BlocksException;

import org.junit.*;
import static org.junit.Assert.*;

public class TestBlocks {
    
    boolean blocksPresent;
    
    @Before
    public void setUp() {
        // check if blocks is installed. Then test could take place.
        try {
            Process p = null;
            if (System.getProperty("os.name").toLowerCase().startsWith("win")) {
                p = Runtime.getRuntime().exec("blocks.bat");
            } else {
                p = Runtime.getRuntime().exec("blocks");
            }
            p.getErrorStream().close();
            p.getOutputStream().close();
            p.getInputStream().close();
            blocksPresent = (p.waitFor()==0);
        } catch (Exception e) {
            System.err.println("Blocks is not installed so unittest will be skipped: " + e);
        }
    }

    @After
    public void tearDown() {
    }
    
    /**
     * Test the simple execution of a blocks command
     * @throws Exception
     */
    @Test
    public void test_simpleBlocksExecution() throws Exception {
        if (blocksPresent) {
            Blocks blocks = new Blocks();
            blocks.execute(new String[0]);
        }
    }
    
    /**
     * Test the simple execution of a blocks command
     * @throws Exception
     */
    @Test
    public void test_simpleBlocksExecutionFails() throws Exception {
        if (blocksPresent) {
            Blocks blocks = new Blocks();
            String[] args = new String[1];
            args[0] = "non-existing-command";
            try {
                blocks.execute(args);
                fail("This blocks command must fail!");
            } catch (BlocksException e) {
                // nothing to do
            }
        }
    }

    @Test
    public void test_addWorkspace() throws Exception {
        if (blocksPresent) {
            Blocks blocks = new Blocks();
            try {
                blocks.addWorkspace(new File("not-existing-dir"), "Not existing dir.");
                fail("This blocks command must fail!");
            } catch (BlocksException e) {
                // nothing to do
            }
        }
    }

    @Test
    public void test_listWorkspaces() throws Exception {
        if (blocksPresent) {
            Blocks blocks = new Blocks();
            blocks.listWorkspaces();
        }
    }
}