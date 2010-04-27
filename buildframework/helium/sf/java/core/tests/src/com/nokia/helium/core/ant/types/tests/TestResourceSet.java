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
package com.nokia.helium.core.ant.types.tests;

import org.apache.tools.ant.BuildFileTest;
import org.junit.Test;

import com.nokia.helium.core.ant.types.ResourceSet;

public class TestResourceSet extends BuildFileTest {

    public TestResourceSet() {
        String testdir = System.getProperty("testdir");
        this.configureProject(testdir + "/tests/data/resourceset/build.xml");
    }
    
    @Test
    public void testResourceSet1() {
        assertTrue(this.getProject().getReference("test1") != null);
        assertTrue(((ResourceSet)this.getProject().getReference("test1")).getData() != null);
        assertEquals(1, ((ResourceSet)this.getProject().getReference("test1")).getData().size());
    }

    @Test
    public void testResourceSet2() {
        assertTrue(this.getProject().getReference("test2") != null);
        assertTrue(((ResourceSet)this.getProject().getReference("test2")).getData() != null);
        assertEquals(2, ((ResourceSet)this.getProject().getReference("test2")).getData().size());
    }
    
    @Test
    public void testResourceSetEmpty() {
        assertTrue(this.getProject().getReference("test.empty") != null);
        assertTrue(((ResourceSet)this.getProject().getReference("test.empty")).getData() != null);
        assertEquals(0, ((ResourceSet)this.getProject().getReference("test.empty")).getData().size());
    }
}
