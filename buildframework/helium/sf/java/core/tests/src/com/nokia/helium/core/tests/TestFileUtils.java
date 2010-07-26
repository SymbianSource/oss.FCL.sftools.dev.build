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
package com.nokia.helium.core.tests;

import static org.junit.Assert.assertTrue;

import org.junit.Test;

import com.nokia.helium.core.FileUtils;

public class TestFileUtils {

    /**
     * This test search the foobar excutable that should not exists.
     */
    @Test
    public void findNonExistingBinary() {
        assertTrue(FileUtils.findExecutableOnPath("foobar") == null);
    }

    /**
     * This test is looking for ant executable, which must exists as
     * we are running the test through Ant.
     */
    @Test
    public void findExistingBinary() {
        assertTrue(FileUtils.findExecutableOnPath("ant") != null);
    }
}
