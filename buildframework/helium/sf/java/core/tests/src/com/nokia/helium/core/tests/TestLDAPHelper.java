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
package com.nokia.helium.core.tests;

import static org.junit.Assert.assertNotNull;

import org.junit.Test;

import com.nokia.helium.core.LDAPException;
import com.nokia.helium.core.LDAPHelper;

/**
 * Testing the LDAPHelper class. Test are limited to what
 * can be check locally.
 * 
 */
public class TestLDAPHelper {

    /**
     * Test that construction fails if ldap is null
     */
    @Test
    public void checkContstrutorValidationForLDAP() {
        IllegalArgumentException error = null;
        try {
            new LDAPHelper(null, "");
        } catch (IllegalArgumentException ex) {
            error = ex;
        }
        assertNotNull(error);
    }

    /**
     * Test that construction fails if rootdn is null
     */
    @Test
    public void checkContstrutorValidationForRootDN() {
        IllegalArgumentException error = null;
        try {
            new LDAPHelper("", null);
        } catch (IllegalArgumentException ex) {
            error = ex;
        }
        assertNotNull(error);
    }

    /**
     * Test that construction fails if rootdn is null
     * @throws LDAPException 
     */
    @Test
    public void checkGetAttributeAsStringNullUsername() throws LDAPException {
        IllegalArgumentException error = null;
        LDAPHelper helper = new LDAPHelper("", "");
        try {
            helper.getAttributeAsString(null, "");
        } catch (IllegalArgumentException ex) {
            error = ex;
        }
        assertNotNull(error);
    }

    /**
     * Test that construction fails if rootdn is null
     * @throws LDAPException 
     */
    @Test
    public void checkGetAttributeAsStringNullAttribute() throws LDAPException {
        IllegalArgumentException error = null;
        LDAPHelper helper = new LDAPHelper("", "");
        try {
            helper.getAttributeAsString("", null);
        } catch (IllegalArgumentException ex) {
            error = ex;
        }
        assertNotNull(error);
    }

    /**
     * Test that construction fails if rootdn is null
     * @throws LDAPException 
     */
    @Test
    public void checkGetAttributeAsStringNullAttributeCurrentUser() throws LDAPException {
        IllegalArgumentException error = null;
        LDAPHelper helper = new LDAPHelper("", "");
        try {
            helper.getUserAttributeAsString(null);
        } catch (IllegalArgumentException ex) {
            error = ex;
        }
        assertNotNull(error);
    }


    /**
     * Test that construction fails if rootdn is null
     * @throws LDAPException 
     */
    @Test
    public void checkGetAttributeAsStringInvalidUser() {
        LDAPException error = null;
        LDAPHelper helper = new LDAPHelper("", "");
        try {
            helper.getAttributeAsString("invaliduser", LDAPHelper.EMAIL_ATTRIBUTE_NAME);
        } catch (LDAPException ex) {
            error = ex;
        }
        assertNotNull(error);
    }
}
