/*
 * Copyright (c) 2010-2011 Nokia Corporation and/or its subsidiary(-ies).
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
package com.nokia.helium.core;

import java.util.Hashtable;

import javax.naming.Context;
import javax.naming.NameNotFoundException;
import javax.naming.NamingEnumeration;
import javax.naming.NamingException;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import javax.naming.directory.SearchControls;
import javax.naming.directory.SearchResult;

/**
 * Simpler LDAP interface to retrieve user base attribute. 
 *
 */
public class LDAPHelper {
    public static final String EMAIL_ATTRIBUTE_NAME = "mail";
    private String ldapURL;
    private String rootdn;
    
    /**
     * Construct a LDAP helper for a specific server.
     * @param ldapURL the ldap url (e.g: ldap://server:389)
     * @param rootdn the rootdn value.
     */
    public LDAPHelper(String ldapURL, String rootdn) {
        if (ldapURL == null) {
            throw new IllegalArgumentException("The ldap server url cannot be null.");
        }
        if (rootdn == null) {
            throw new IllegalArgumentException("The rootdn cannot be null.");
        }
        this.ldapURL = ldapURL;
        this.rootdn = rootdn;
    }
    
    /**
     * Get the value of the LDAP attribute for a filter.
     * @param filter the filter to search for
     * @param attribute the attribute name.
     * @return the value of the attribute as a string., if the value is not a String then it is 
     *         stringify using toString. Returns null if not found.
     * @throws LDAPException
     */
    public String getAttributeAsString(String filter, String attribute) throws LDAPException {
        if (filter == null) {
            throw new IllegalArgumentException("filter cannot be null.");
        }
        if (attribute == null) {
            throw new IllegalArgumentException("attribute cannot be null.");
        }
        // Set up environment for creating initial context
        Hashtable<String, String> env = new Hashtable<String, String>(11);
        env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
        env.put(Context.PROVIDER_URL, ldapURL + "/" + rootdn);

        // Create initial context
        try {
            DirContext ctx = new InitialDirContext(env);
            SearchControls controls = new SearchControls();
            controls.setSearchScope(SearchControls.SUBTREE_SCOPE);
            NamingEnumeration<SearchResult> en = ctx.search("", filter, controls);
            if (en.hasMore()) {
                SearchResult sr = en.next();
                if (sr.getAttributes().get(attribute) != null) {
                    Object value = sr.getAttributes().get(attribute).get();
                    if (value instanceof String) {
                        return (String)value;
                    } else {
                        return value.toString();
                    }
                }
            }
        } catch (NameNotFoundException ex) {
            throw new LDAPException("Could not find " +  filter + " attribute " + attribute + " in LDAP: " + ex.getMessage(), ex);
        } catch (NamingException ex) {
            throw new LDAPException("Could not find " +  filter + " attribute " + attribute + " in LDAP: " + ex.getMessage(), ex);
        }
        return null;
    }

    /**
     * Get the value of the LDAP attribute for current user. (based on user.name).
     * @param attribute the attribute name.
     * @return the value of the attribute as a string., if the value is not a String then it is 
     *         stringify using toString. Returns null if not found.
     * @throws LDAPException
     */
    public String getUserAttributeAsString(String attribute) throws LDAPException {
        return getUserAttributeAsString(System.getProperty("user.name"), attribute);
    }

    /**
     * Get the value of the LDAP attribute for username.
     * @param username the user to search for
     * @param attribute the attribute name.
     * @return the value of the attribute as a string., if the value is not a String then it is 
     *         stringify using toString. Returns null if not found.
     * @throws LDAPException
     */
    public String getUserAttributeAsString(String username, String attribute) throws LDAPException {
        return getAttributeAsString("uid=" + username, attribute);
    }

}
