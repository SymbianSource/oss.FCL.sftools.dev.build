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

import static org.junit.Assert.assertTrue;

import org.junit.Test;

import com.nokia.helium.core.plexus.StreamMultiplexer;
import com.nokia.helium.core.plexus.StreamRecorder;

/**
 * Testing the StreamMultiplexer class.
 *
 */
public class TestStreamMultiplexer {

    /**
     * Having an empty list of handler should not cause any problem.
     */
    @Test
    public void noHandler() {
        StreamMultiplexer mux = new StreamMultiplexer();
        mux.consumeLine("1st line");
        mux.consumeLine("2nd line");
    }
    
    /**
     * The two recorders should record the same stuff.
     */
    @Test
    public void recordSomeLines() {
        StreamMultiplexer mux = new StreamMultiplexer();
        StreamRecorder rec = new StreamRecorder();
        StreamRecorder rec2 = new StreamRecorder();
        mux.addHandler(rec);
        mux.addHandler(rec2);
        mux.consumeLine("1st line");
        mux.consumeLine("2nd line");
        assertTrue(rec.getBuffer().toString().equals("1st line\n2nd line\n"));
        assertTrue(rec2.getBuffer().toString().equals("1st line\n2nd line\n"));
    }

}
