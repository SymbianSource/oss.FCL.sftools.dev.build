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

package com.nokia.helium.ant.data;

import java.io.IOException;

import org.apache.tools.ant.Project;
import org.dom4j.Element;
import org.dom4j.Node;

/**
 * Meta object for an Ant property.
 */
public class PropertyMeta extends AntObjectMeta {
    public static final String DEFAULT_EDITABLE = "optional";
    public static final String STRING_TYPE = "string";
    public static final String INTEGER_TYPE = "integer";
    public static final String BOOLEAN_TYPE = "boolean";
    public static final String DEFAULT_TYPE = STRING_TYPE;

    public PropertyMeta(AntObjectMeta parent, Node propNode) throws IOException {
        super(parent, propNode);
    }

    /**
     * Returns the default value of the property.
     * 
     * @return A default value.
     */
    public String getDefaultValue() {
        String value = getAttr("value");
        if (value.length() == 0) {
            value = getAttr("location");
        }
        return value;
    }

    public String getType() {
        return getComment().getTagValue("type", PropertyMeta.DEFAULT_TYPE);
    }

    public String getEditable() {
        return getComment().getTagValue("editable", PropertyMeta.DEFAULT_EDITABLE);
    }

    /**
     * Attempts to get the actual value of this current property.
     * 
     * @return The property's current value.
     */
    public String getValue() {
        String value = null;
        Project project = getRuntimeProject();
        if (project != null) {
            value = project.getProperty(getName());
        }
        return value;
    }

    /**
     * Handling of scope is overridden here to make properties declared at the
     * project root to be public and those nested inside targets, etc to be
     * private by default. This is only if there is no scope defined in the
     * comment for the property.
     */
    @Override
    public String getScope() {
        String scope = getComment().getTagValue("scope");
        if (scope.equals("")) {
            Element parent = getNode().getParent();
            if (parent.getName().equals("project")) {
                scope = "public";
            }
            else {
                scope = "private";
                if (!getComment().getDocumentation().equals("")) {
                    System.out.println(getName() + " no scope");
                }
            }
        }
        return scope;
    }
}
