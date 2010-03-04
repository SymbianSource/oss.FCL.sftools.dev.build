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
package com.nokia.helium.imaker.tests;

import org.junit.*;

import com.nokia.helium.imaker.PrintVarSteamConsumer;

import static org.junit.Assert.*;

public class TestPrintVarStreamConsumer {

    @Test
    public void readSimpleVar() {
        PrintVarSteamConsumer consumer = new PrintVarSteamConsumer("WORKDIR");
        consumer.consumeLine("iMaker 09.24.01, 10-Jun-2009.");
        consumer.consumeLine("WORKDIR = `/.'");
        consumer.consumeLine("");
        assertEquals(consumer.getValue(), "/.");
    }

    @Test
    public void readMultilineVar() {
        PrintVarSteamConsumer consumer = new PrintVarSteamConsumer("LONGVAR");
        consumer.consumeLine("iMaker 09.24.01, 10-Jun-2009.");
        consumer.consumeLine("LONGVAR = `some text");
        consumer.consumeLine("second line");
        consumer.consumeLine("end of text'");
        consumer.consumeLine("");
        assertEquals(consumer.getValue(), "some text\nsecond line\nend of text");
    }
}
