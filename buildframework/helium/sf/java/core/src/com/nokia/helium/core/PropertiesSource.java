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

package com.nokia.helium.core;

import java.util.Hashtable;
import java.util.Map;
import java.util.Properties;
import java.util.Map.Entry;

/**
 * Property set configuration holder. Will make the defined properties available
 * under a named variable.
 */
public class PropertiesSource extends AbstractTemplateInputSource {
    private Map<String, String> properties;

    /**
     * Constructor
     * 
     * @param String
     *            Name of template
     * @param Hashtable
     *            properties
     */
    public PropertiesSource(String name, Map<String, String> props) {
        setSourceName(name);
        properties = props;
    }

    /**
     * Constructor
     * 
     * @param String
     *            Name of template
     * @param Properties
     *            properties
     */
    public PropertiesSource(String name, Properties props) {
        setSourceName(name);
        properties = new Hashtable<String, String>();
        for (Entry<Object, Object> entry : props.entrySet()) {
            properties.put((String) entry.getKey(), (String) entry.getValue());
        }
    }

    /**
     * Get properties.
     * 
     * @return Properties.
     */
    public Map<String, String> getProperties() {
        return properties;
    }
}