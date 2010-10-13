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

import com.nokia.helium.blocks.RepositoryListStreamConsumer;

import static org.junit.Assert.assertEquals;

/**
 * Tests related to the GroupStreamConsumer class.
 */
public class TestRepositoryListStreamConsumer {
   
    @Test
    public void parsingOfData() {
        RepositoryListStreamConsumer consumer = new RepositoryListStreamConsumer();
        consumer.consumeLine("1");
        consumer.consumeLine("  Name: sbs_22");
        consumer.consumeLine("  URI: file:///e:/repo1");
        consumer.consumeLine("");
        consumer.consumeLine("2");
        consumer.consumeLine("  Name: sbs_23");
        consumer.consumeLine("  URI: file:///e:/repo2");
        consumer.consumeLine("");
        assertEquals(consumer.getRepositories().size(), 2);
        assertEquals(consumer.getRepositories().get(0).getName(), "sbs_22");
        assertEquals(consumer.getRepositories().get(0).getId(), 1);
        assertEquals(consumer.getRepositories().get(0).getUrl(), "file:///e:/repo1");
        assertEquals(consumer.getRepositories().get(1).getName(), "sbs_23");
        assertEquals(consumer.getRepositories().get(1).getId(), 2);
        assertEquals(consumer.getRepositories().get(1).getUrl(), "file:///e:/repo2");
    }
    
}
