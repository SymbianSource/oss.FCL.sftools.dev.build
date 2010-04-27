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

import static org.junit.Assert.*;

import java.io.File;
import java.util.List;

import org.junit.Test;

import com.nokia.helium.imaker.IMaker;
import com.nokia.helium.imaker.IMakerException;

/**
 * Testing IMaker class.
 */
public class TestIMaker {

    private File epocroot = new File(System.getProperty("testdir"), "tests/epocroot");

    /**
     * Test the getVersion is retrieving the output from imaker correctly.
     * @throws IMakerException
     */
    @Test
    public void testGetVersion() throws IMakerException {
        String expectedVersion = "iMaker 09.24.01, 10-Jun-2009.";
        IMaker imaker = new IMaker(epocroot);
        assertEquals(expectedVersion, imaker.getVersion());
    }

    /**
     * Test the introspection of an existing variable.
     * @throws IMakerException
     */
    @Test
    public void testGetVariable() throws IMakerException {
        IMaker imaker = new IMaker(epocroot);
        assertEquals("VALUE", imaker.getVariable("VARIABLE"));
    }
    
    /**
     * Test the introspection of an existing variable.
     * @throws IMakerException
     */
    @Test
    public void testGetVariableFromConfiguration() throws IMakerException {
        IMaker imaker = new IMaker(epocroot);
        assertEquals("PRODUCT_VALUE", imaker.getVariable("VARIABLE", new File("/epoc32/rom/config/platform/product/image_conf_product.mk")));
    }

    /**
     * Test the introspection of a non-existing variable.
     * @throws IMakerException
     */
    @Test
    public void testGetNotExistingVariable() throws IMakerException {
        IMaker imaker = new IMaker(epocroot);
        assertEquals(null, imaker.getVariable("NOTEXISTINGVARIABLE"));
    }
    
    /**
     * Test the introspection of existing configurations.
     * @throws IMakerException
     */
    @Test
    public void testGetConfigurations() throws IMakerException {
        IMaker imaker = new IMaker(epocroot);
        String[] expected = new String[2];
        expected[0] = "/epoc32/rom/config/platform/product/image_conf_product.mk";
        expected[1] = "/epoc32/rom/config/platform/product/image_conf_product_ui.mk";
        assertArrayEquals(expected, imaker.getConfigurations().toArray(new String[2]));
    }
    
    /**
     * Test the introspection of existing target for a configuration.
     * @throws IMakerException
     */
    @Test
    public void testGetTargets() throws IMakerException {
        IMaker imaker = new IMaker(epocroot);
        List<String> targets = imaker.getTargets("/epoc32/rom/config/platform/product/image_conf_product.mk");
        
        String[] expected = new String[5];
        expected[0] = "all";
        expected[1] = "core";
        expected[2] = "core-dir";
        expected[3] = "help-%-list";
        expected[4] = "langpack_01";
        assertArrayEquals(expected, targets.toArray(new String[5]));
    }

    /**
     * Test the introspection of existing target for a configuration using file
     * object.
     * @throws IMakerException
     */
    @Test
    public void testGetTargetsFromFile() throws IMakerException {
        IMaker imaker = new IMaker(epocroot);
        List<String> targets = imaker.getTargets(new File("/epoc32/rom/config/platform/product/image_conf_product.mk"));
        
        String[] expected = new String[5];
        expected[0] = "all";
        expected[1] = "core";
        expected[2] = "core-dir";
        expected[3] = "help-%-list";
        expected[4] = "langpack_01";
        assertArrayEquals(expected, targets.toArray(new String[5]));
    }
    
    /**
     * Test the introspection of existing target for a configuration.
     * @throws IMakerException
     */
    @Test
    public void testGetTargetsWithInvalidProductConf() throws IMakerException {
        IMaker imaker = new IMaker(epocroot);
        try {
            imaker.getTargets("/epoc32/rom/config/platform/product/image_conf_invalid.mk");
            fail("We should catch a failure from iMaker.");
        } catch(IMakerException e) {
            // Exception should be raised
        }
    }
}
