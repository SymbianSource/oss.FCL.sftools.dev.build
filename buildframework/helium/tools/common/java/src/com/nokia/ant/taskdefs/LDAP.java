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
 
package com.nokia.ant.taskdefs;

import org.apache.tools.ant.Task;
import org.apache.tools.ant.BuildException;
import javax.naming.*;
import javax.naming.directory.*;
import java.util.Hashtable;

/**
 * Task is to search data from LDAP server.
 *
 * Usage: &lt;hlm:ldap url="${ldap.server.url}" rootdn="${ldap.root.dn}" filter="uid=${env.USERNAME}" outputproperty="email.from" key="mail"/&gt;
 */
public class LDAP extends Task 
{
    private String url;
    private String rootdn;
    private String filter;
    private String key;
    private String property;
    
        
    public void execute()
    {
        
        if (url == null)
            throw new BuildException("'url' attribute is not defined");
        if (rootdn == null)
            throw new BuildException("'rootdn' attribute is not defined");
        if (filter == null)
            throw new BuildException("'filter' attribute is not defined");
        if (property == null)
            throw new BuildException("'property' attribute is not defined");
        if (key == null)
            throw new BuildException("'key' attribute is not defined");    
        
        // Set up environment for creating initial context
        Hashtable<String, String> env = new Hashtable<String, String>();
        env.put(Context.INITIAL_CONTEXT_FACTORY,
                "com.sun.jndi.ldap.LdapCtxFactory");
        env.put(Context.PROVIDER_URL, url + "/" + rootdn);

        // Create initial context
        try 
        {
            DirContext ctx = new InitialDirContext(env);
            SearchControls controls = new SearchControls();
            controls.setSearchScope(SearchControls.SUBTREE_SCOPE);
            NamingEnumeration<SearchResult> en = ctx.search("", filter, controls);
            if (en.hasMore()) 
            {
                SearchResult sr = en.next();
                getProject().setProperty(property, (String)sr.getAttributes().get(key).get());
                return;
            }
        } 
        catch (NamingException exc) 
        {
            throw new BuildException(exc.getMessage());
        }
        catch (NullPointerException e) 
        {
            // As uer will not get affected due to this error not failing build.
            log("Not able to retrive LDAP information for " + filter);
        }
    }

    public String getUrl() 
    {
        return url;
    }

    public void setUrl(String url) 
    {
        this.url = url;
    }
    

    public String getRootdn() 
    {
        return rootdn;
    }

    public void setRootdn(String rootdn) 
    {
        this.rootdn = rootdn;
    }

    public String getFilter() 
    {
        return filter;
    }

    public void setFilter(String filter) 
    {
        this.filter = filter;
    }

    public String getOutputProperty() 
    {
        return property;
    }

    public void setOutputProperty(String property) 
    {
        this.property = property;
    }

    public String getKey() 
    {
        return key;
    }

    public void setKey(String key) 
    {
        this.key = key;
    }
}
