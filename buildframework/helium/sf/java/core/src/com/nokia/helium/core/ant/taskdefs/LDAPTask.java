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

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

import com.nokia.helium.core.LDAPException;
import com.nokia.helium.core.LDAPHelper;

/**
 * Task is to search data from LDAP server.
 * 
 * <pre>
 * Usage: &lt;hlm:ldap url=&quot;${ldap.server.url}&quot; 
 *                  rootdn=&quot;${ldap.root.dn}&quot; 
 *                  filter=&quot;uid=${env.USERNAME}&quot; 
 *                  outputproperty=&quot;email.from&quot; 
 *                  key=&quot;mail&quot;/&gt;
 * </pre>
 * @ant.task name="ldap" category="Core" 
 */
public class LDAPTask extends Task {
    private String url;
    private String rootdn;
    private String filter;
    private String key;
    private String property;
    private boolean failOnError = true;

    /**
     * Method executes current task.
     */
    public void execute() {
        if (url == null) {
            throw new BuildException("'url' attribute is not defined");
        }
        if (rootdn == null) {
            throw new BuildException("'rootdn' attribute is not defined");
        }
        if (filter == null) {
            throw new BuildException("'filter' attribute is not defined");
        }
        if (property == null) {
            throw new BuildException("'property' attribute is not defined");
        }
        if (key == null) {
            throw new BuildException("'key' attribute is not defined");
        }

        try {
            LDAPHelper helper = new LDAPHelper(url, rootdn);
            String value = helper.getAttributeAsString(filter, key);
            if (value != null) {
                getProject().setNewProperty(property, value);
            } else {
                log("Could not find value for key: " + key, Project.MSG_WARN);
            }
        } catch (LDAPException exc) {
            log(exc.getMessage(), Project.MSG_ERR);
            if (failOnError) {
                throw new BuildException(exc.getMessage(), exc);
            }
        } 
    }

    /**
     * Return the LDAP server URL.
     * 
     * @return the LDAP server URL.
     */
    public String getUrl() {
        return url;
    }

    /**
     * Set LDAP server URL.
     * 
     * @param url is the LDAP server URL to set.
     * @ant.required
     */
    public void setUrl(String url) {
        this.url = url;
    }

    /**
     * Return LDAP root distinguished name.
     * 
     * @return LDAP root distinguished name
     */
    public String getRootdn() {
        return rootdn;
    }

    /**
     * Set LDAP root distinguished name.
     * 
     * @param rootdn is the LDAP root distinguished name to set.
     * @ant.required
     */
    public void setRootdn(String rootdn) {
        this.rootdn = rootdn;
    }

    /**
     * Return object name to search in the LDAP.
     * 
     * @return the object name to search in the LDAP
     */
    public String getFilter() {
        return filter;
    }

    /**
     * Set the object name to search in the LDAP.
     * 
     * @param filter is the object name to set.
     * @ant.required
     */
    public void setFilter(String filter) {
        this.filter = filter;
    }

    /**
     * Return the output property to set.
     * 
     * @return is the output property to set.
     */
    public String getOutputProperty() {
        return property;
    }

    /**
     * Set the output property if the user found.
     * 
     * @param property is the property to be set.
     * @ant.required
     */
    public void setOutputProperty(String property) {
        this.property = property;
    }

    /**
     * Return the key search element to search user information.
     * 
     * @return the key search element.
     */
    public String getKey() {
        return key;
    }

    /**
     * Set the key search element to search the user information.
     * 
     * @param key is the key search element to set.
     * @ant.required
     */
    public void setKey(String key) {
        this.key = key;
    }

    /**
     * Defines if the task should fail on error or not found.
     * @param failOnError
     * @ant.not-required Default is true
     */
    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }

}
