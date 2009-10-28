/* 
============================================================================ 
Name        : TestModificationCache.java
Part of     : Helium 

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.
This component and the accompanying materials are made available
under the terms of the License "Eclipse Public License v1.0"
which accompanies this distribution, and is available
at the URL "http://www.eclipse.org/legal/epl-v10.html".

Initial Contributors:
Nokia Corporation - initial contribution.

Contributors:

Description:

============================================================================
 */
package com.nokia.cruisecontrol.sourcecontrol.tests;

import org.junit.*;

import com.nokia.cruisecontrol.sourcecontrol.ModificationCache;

import static org.junit.Assert.*;
import net.sourceforge.cruisecontrol.Modification;
import java.util.Date;
import java.util.List;

public class TestModificationCache 
{
    @Before
    public void setUp() {
    }

    @After
    public void tearDown() {
    }

    /**
     * Check the getModifications.
     * @throws Exception
     */
    @Test
    public void test_getModifications() throws Exception {
        ModificationCache cache = new ModificationCache();
        // before
        Modification m = new Modification();
        m.comment = "before";
        m.modifiedTime = new Date(100);
        cache.add(m);

        // in
        m = new Modification();
        m.comment = "in";
        m.modifiedTime = new Date(150);
        cache.add(m);

        // after
        m = new Modification();
        m.comment = "after";
        m.modifiedTime = new Date(200);
        cache.add(m);
        
        List<Modification> mods = cache.getModifications(new Date(110), new Date(199));
        assertTrue("The result must contain only one element.", mods.size() == 1);
        assertTrue("The element should have the comment 'in'.", mods.get(0).comment.equals("in"));
    }

    /**
     * Check the cleanup.
     * @throws Exception
     */
    @Test
    public void test_cleanup() throws Exception {
        ModificationCache cache = new ModificationCache();
        // before
        Modification m = new Modification();
        m.comment = "before";
        m.modifiedTime = new Date(100);
        cache.add(m);

        // in
        m = new Modification();
        m.comment = "in";
        m.modifiedTime = new Date(150);
        cache.add(m);

        // after
        m = new Modification();
        m.comment = "after";
        m.modifiedTime = new Date(200);
        cache.add(m);
        
        cache.cleanup(new Date(199));
        List<Modification> mods = cache.getModifications(new Date(0), new Date(1000));
        assertTrue("The result must contain only one element.", mods.size() == 1);
        assertTrue("The element should have the comment 'in'.", mods.get(0).comment.equals("after"));
    }
}
