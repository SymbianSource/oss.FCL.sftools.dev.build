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

import com.nokia.helium.blocks.SearchStreamConsumer;

import static org.junit.Assert.assertEquals;

/**
 * Tests related to the SearchStreamConsumer class.
 */
public class TestSearchStreamConsumer {

    @Test
    public void parsingOfInvalidData() {
        SearchStreamConsumer consumer = new SearchStreamConsumer();
        consumer.consumeLine("");
        consumer.consumeLine("foo-bar");
        consumer.consumeLine("bar");
        assertEquals(consumer.getSearchResults().size(), 0);
    }

    @Test
    public void parsingOfValidData() {
        SearchStreamConsumer consumer = new SearchStreamConsumer();
        consumer.consumeLine("");
        consumer.consumeLine("foo.src - n/a");
        consumer.consumeLine("foo-dev.src - n/a");
        assertEquals(consumer.getSearchResults().size(), 2);
        assertEquals(consumer.getSearchResults().get(0), "foo.src");
        assertEquals(consumer.getSearchResults().get(1), "foo-dev.src");
    }
    
}
