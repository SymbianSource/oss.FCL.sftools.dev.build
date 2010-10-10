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

import org.junit.Test;

import com.nokia.helium.blocks.GroupListStreamConsumer;

import static org.junit.Assert.assertEquals;

/**
 * Tests related to the GroupStreamConsumer class.
 */
public class TestGroupStreamConsumer {
   
    @Test
    public void parsingOfData() {
        GroupListStreamConsumer consumer = new GroupListStreamConsumer();
        consumer.consumeLine("");
        consumer.consumeLine("   My group");
        consumer.consumeLine("   My second group");
        consumer.consumeLine("");
        assertEquals(consumer.getGroups().size(), 2);
        assertEquals(consumer.getGroups().get(0).getName(), "My group");
        assertEquals(consumer.getGroups().get(1).getName(), "My second group");
    }
    
}
