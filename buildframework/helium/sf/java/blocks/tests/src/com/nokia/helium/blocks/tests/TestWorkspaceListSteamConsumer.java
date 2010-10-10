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

import org.junit.*;

import com.nokia.helium.blocks.Workspace;
import com.nokia.helium.blocks.WorkspaceListStreamConsumer;

import static org.junit.Assert.*;

public class TestWorkspaceListSteamConsumer {

    @Test
    public void simpleParsing() {
        WorkspaceListStreamConsumer consumer = new WorkspaceListStreamConsumer();
        consumer.consumeLine("");
        consumer.consumeLine("foo");
        consumer.consumeLine("bar");
        assertEquals(consumer.getWorkspaces().length, 0);
    }
    
    @Test
    public void simpleWorkspaceParsing() {
        WorkspaceListStreamConsumer consumer = new WorkspaceListStreamConsumer();
        consumer.consumeLine("1");
        consumer.consumeLine("  name: foobar");
        consumer.consumeLine("  path: C:\\workspace\\foo");
        consumer.consumeLine("");
        assertEquals(consumer.getWorkspaces().length, 1);
    }

    @Test
    public void realWorkspaceParsing() {
        WorkspaceListStreamConsumer consumer = new WorkspaceListStreamConsumer();
        consumer.consumeLine("1");
        consumer.consumeLine("  name: foo");
        consumer.consumeLine("  path: C:\\workspaces\\foo");
        consumer.consumeLine("");
        consumer.consumeLine("2*");
        consumer.consumeLine("  name: foobar");
        consumer.consumeLine("  path: C:\\workspaces\\tests");
        consumer.consumeLine("");
        Workspace[] ws = consumer.getWorkspaces();
        assertEquals(ws.length, 2);
        assertEquals(ws[0].getName(), "foo");
        assertEquals(ws[0].getLocation().toString(), "C:\\workspaces\\foo");
        assertEquals(ws[1].getName(), "foobar");
        assertEquals(ws[1].getLocation().toString(), "C:\\workspaces\\tests");
    }
    
}
