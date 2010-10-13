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

import static org.junit.Assert.fail;

import java.io.File;
import java.io.IOException;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import com.nokia.helium.blocks.Bundle;
import com.nokia.helium.blocks.BundleException;

/**
 * Test bundle command interface.
 */
public class TestBundle {
    boolean bundlePresent;
    
    @Before
    public void setUp() {
        // check if blocks is installed. Then test could take place.
        try {
            Process p = null;
            if (System.getProperty("os.name").toLowerCase().startsWith("win")) {
                p = Runtime.getRuntime().exec("bundle.bat");
            } else {
                p = Runtime.getRuntime().exec("bundle");
            }
            p.getErrorStream().close();
            p.getOutputStream().close();
            p.getInputStream().close();
            bundlePresent = (p.waitFor()==0);
        } catch (Exception e) {
            System.err.println("Bundler is not installed so unittest will be skipped: " + e);
        }
    }

    @After
    public void tearDown() {
    }

    @Test
    public void test_simpleBundleExecution() throws BundleException {
        if (bundlePresent) {
            Bundle bundle = new Bundle();
            bundle.execute(new String[0]);
        }
    }
    
    @Test
    public void test_createIndexNullArg() {
        if (bundlePresent) {
            Bundle bundle = new Bundle();
            try {
                bundle.createRepositoryIndex(null);
                fail("createRepositoryIndex must fail in case of invalid arg.");
            } catch (BundleException exc) {
                // ignore exception
            }
        }
    }

    @Test
    public void test_createIndexInvalidDir() throws IOException {
        if (bundlePresent) {
            Bundle bundle = new Bundle();
            try {
                File file = File.createTempFile("invalid", ".dir");
                file.deleteOnExit();
                bundle.createRepositoryIndex(file);
                fail("createRepositoryIndex must fail in case of invalid arg.");
            } catch (BundleException exc) {
                // ignore exception
            }
        }
    }

    
}
