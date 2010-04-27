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

import static org.junit.Assert.*;

import org.junit.Test;

import com.nokia.helium.core.plexus.StreamRecorder;

/**
 * Unittests for the TestStreamRecorder class. 
 *
 */
public class TestStreamRecorder {

    @Test
    public void recordSomeLines() {
        StreamRecorder rec = new StreamRecorder();
        rec.consumeLine("1st line");
        rec.consumeLine("2nd line");
        assertTrue(rec.getBuffer().toString().equals("1st line\n2nd line\n"));
    }

    @Test
    public void recordSomeLinesWithOwnBuffer() {
        StringBuffer buffer = new StringBuffer();
        StreamRecorder rec = new StreamRecorder(buffer);
        assertTrue(rec.getBuffer() == buffer);
        rec.consumeLine("1st line");
        rec.consumeLine("2nd line");
        assertTrue(rec.getBuffer().toString().equals("1st line\n2nd line\n"));
    }

    @Test
    public void setGetBuffer() {
        StringBuffer buffer = new StringBuffer();
        StreamRecorder rec = new StreamRecorder();
        assertTrue(rec.getBuffer() != buffer);
        rec.setBuffer(buffer);
    }
}
