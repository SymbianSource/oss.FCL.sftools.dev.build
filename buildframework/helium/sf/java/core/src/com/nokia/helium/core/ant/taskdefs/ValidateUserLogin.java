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
 
package com.nokia.helium.core.ant.taskdefs;

import org.apache.tools.ant.Task;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.BuildException;
import javax.naming.*;
import javax.naming.directory.*;
import java.util.Hashtable;
import org.apache.tools.ant.taskdefs.condition.Condition;

/**
 * Task is to validate noe user with LDAP server.
 * <pre>
 * Usage: &lt;hlm:ldapauthenticate url="${email.ldap.server}" 
                                rootdn="${email.ldap.rootdn}" 
                                searchdn="${ldap.organization.unit.rootdn}, ${ldap.people.rootdn}" 
                                filter="uid=${env.USERNAME}" 
                                outputproperty="is.authentication.sucess" 
                                key="employeeNumber"
                                password="${noe.password}"/&gt;
   </pre>
   <pre>
 * Usage:   &lt;condition property="is.authentication.sucess" &gt;
                &lt;hlm:ldapauthenticate url="${email.ldap.server}" 
                                rootdn="${email.ldap.rootdn}" 
                                searchdn="${ldap.organization.unit.rootdn}, ${ldap.people.rootdn}" 
                                filter="uid=${env.USERNAME}" 
                                key="employeeNumber"
                                password="${noe.password}"/&gt;
            &lt;condition/&gt;
   </pre>
   @ant.task name="ldapauthenticate" category="Core" 
 */
public class ValidateUserLogin extends Task implements Condition
{
    private String url;
    private String rootdn;
    private String filter;
    private String key;
    private String property;
    private String searchdn;
    private String password;
        
    public void execute()
    {
        
        if (property == null)
            throw new BuildException("'property' attribute is not defined");
        validateParameters(url, rootdn, filter, key, searchdn, password);
        log("Authenticating the user...");
        if (authenticateUser(url, searchUser(url, rootdn, filter, key, searchdn))) {
            getProject().setProperty(property, "true");
        }
        else {
            getProject().setProperty(property, "false");
        }
    }
    
    public boolean eval() {
        
        validateParameters(url, rootdn, filter, key, searchdn, password);
        return authenticateUser(url, searchUser(url, rootdn, filter, key, searchdn)); 
         
    }
    
    public String searchUser(String url, String rootdn, String filter, String key, String searchdn) {
        
        String userSearchDN = null;
        // Set up environment for creating initial context
        Hashtable<String, String> env = new Hashtable<String, String>();
        env.put(Context.INITIAL_CONTEXT_FACTORY,
                "com.sun.jndi.ldap.LdapCtxFactory");
        env.put(Context.PROVIDER_URL, url + "/" + rootdn);

        // Create initial context
        env.put(Context.SECURITY_AUTHENTICATION, "simple");
        DirContext ctx = null;
        NamingEnumeration results = null;
        try {
            ctx = new InitialDirContext(env);
            SearchControls controls = new SearchControls();
            controls.setSearchScope(SearchControls.SUBTREE_SCOPE);
            results = ctx.search("", filter, controls);
            while (results.hasMore()) {
                SearchResult searchResult = (SearchResult) results.next();
                Attributes attributes = searchResult.getAttributes();
                Attribute attr = attributes.get(key);
                userSearchDN = key + "=" + (String) attr.get() + ", " + searchdn + ", " + rootdn;
            }
        } catch (NamingException e) {
            e.printStackTrace(); 
            throw new BuildException("LDAP Naming exception"); 
        }
        return userSearchDN;
    }
    
    public void validateParameters(String url, String rootdn, String filter, String key, String searchdn, String password) {
        
        if (url == null)
            throw new BuildException("'url' attribute is not defined");
        if (rootdn == null)
            throw new BuildException("'rootdn' attribute is not defined");
        if (filter == null)
            throw new BuildException("'filter' attribute is not defined");
        if (key == null)
            throw new BuildException("'key' attribute is not defined");
        if (searchdn == null)
            throw new BuildException("'searchdn' attribute is not defined");
        if (password == null)
            throw new BuildException("'password' attribute is not defined");
    }
    
    public boolean authenticateUser(String ldapurl, String rooTdn) {
    
        Hashtable<String, String> env = new Hashtable<String, String>(11);
        env.put(Context.INITIAL_CONTEXT_FACTORY,"com.sun.jndi.ldap.LdapCtxFactory");
        env.put(Context.PROVIDER_URL, ldapurl);
        env.put(Context.SECURITY_AUTHENTICATION, "simple");
        env.put(Context.SECURITY_PRINCIPAL, rooTdn);
        env.put(Context.SECURITY_CREDENTIALS, password);
        try {
            DirContext authContext = new InitialDirContext(env);
            return true;
        } catch (NamingException e) {
            // We are Ignoring the errors as no need to fail the build.
            log("Not able to validate the user. " + e.getMessage(), Project.MSG_DEBUG);
            return false;  
        }

    }
    public String getUrl() 
    {
        return url;
    }
    /**
     * ldap URL
     * @ant.required
     */
    public void setUrl(String url) 
    {
        this.url = url;
    }
    

    public String getRootdn() 
    {
        return rootdn;
    }
    /**
     * user password to authenticate
     * @ant.required
     */
    public void setpassword(String password) 
    {
        this.password = password;
    }
    
    public String getpassword() 
    {
        return password;
    }
    /**
     * ldap root distinguished name to search user.
     * @ant.required
     */
    public void setRootdn(String rootdn) 
    {
        this.rootdn = rootdn;
    }
    
    public String getsearchdn() 
    {
        return searchdn;
    }
    /**
     * ldap distinguished name to search user
     * @ant.required
     */
    public void setsearchdn(String searchdn) 
    {
        this.searchdn = searchdn;
    }

    public String getFilter() 
    {
        return filter;
    }
    /**
     * object name to search in the ldap.
     * @ant.required
     */
    public void setFilter(String filter) 
    {
        this.filter = filter;
    }

    public String getOutputProperty() 
    {
        return property;
    }
    /**
     * output property to set if the user found.
     * @ant.required
     */
    public void setOutputProperty(String property) 
    {
        this.property = property;
    }

    public String getKey() 
    {
        return key;
    }
    /**
     * key to search the user information
     * @ant.required
     */
    public void setKey(String key) 
    {
        this.key = key;
    }
}
