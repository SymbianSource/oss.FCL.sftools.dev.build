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

import java.io.File;

import org.junit.*;

import com.nokia.helium.imaker.HelpConfigStreamConsumer;

import static org.junit.Assert.*;

/**
 * Test the HelpTargetStreamConsumer.
 *
 */
public class TestHelpConfigStreamConsumer {

    /**
     * Checking if the consumer is parsing correctly the output. 
     */
    @Test
    public void introspectConfiguration() {
        HelpConfigStreamConsumer consumer = new HelpConfigStreamConsumer();
        consumer.consumeLine("iMaker 09.24.01, 10-Jun-2009.");
        consumer.consumeLine("Finding available configuration file(s):");
        consumer.consumeLine("/epoc32/rom/config/platform/product/image_conf_product.mk");
        consumer.consumeLine("/epoc32/rom/config/platform/product/image_conf_product_ui.mk");
        consumer.consumeLine("");
        
        // Verifying string output
        String[] expected = new String[2];
        expected[0] = "/epoc32/rom/config/platform/product/image_conf_product.mk";
        expected[1] = "/epoc32/rom/config/platform/product/image_conf_product_ui.mk";
        assertArrayEquals(expected, consumer.getConfigurations().toArray(new String[2]));

        // Verifying the file output
        File[] expectedFile = new File[2];
        expectedFile[0] = new File(new File("."), "/epoc32/rom/config/platform/product/image_conf_product.mk");
        expectedFile[1] = new File(new File("."), "/epoc32/rom/config/platform/product/image_conf_product_ui.mk");
        assertArrayEquals(expectedFile, consumer.getConfigurations(new File(".")).toArray(new File[2]));
    }
}

