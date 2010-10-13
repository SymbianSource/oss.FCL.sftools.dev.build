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
package com.nokia.helium.antlint.ant.types;

import com.nokia.helium.ant.data.ProjectMeta;
import com.nokia.helium.ant.data.PropertyCommentMeta;
import com.nokia.helium.ant.data.PropertyMeta;
import com.nokia.helium.ant.data.RootAntObjectMeta;

/**
 * <code>CheckPropertyTypeAndValueMismatch</code> is used to check the property
 * type and value mismatch.
 * 
 * <pre>
 * Usage:
 * 
 *  &lt;antlint&gt;
 *       &lt;fileset id=&quot;antlint.files&quot; dir=&quot;${antlint.test.dir}/data&quot;&gt;
 *               &lt;include name=&quot;*.ant.xml&quot;/&gt;
 *               &lt;include name=&quot;*build.xml&quot;/&gt;
 *               &lt;include name=&quot;*.antlib.xml&quot;/&gt;
 *       &lt;/fileset&gt;
 *       &lt;checkPropertyTypeAndValueMismatch severity=&quot;error&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkPropertyTypeAndValueMismatch" category="AntLint"
 * 
 */
public class CheckPropertyTypeAndValueMismatch extends AbstractProjectCheck {

    /**
     * {@inheritDoc}
     */
    protected void run(RootAntObjectMeta root) {
        if (root instanceof ProjectMeta) {
            ProjectMeta projectMeta = (ProjectMeta) root;
            for (PropertyMeta propertyMeta : projectMeta.getProperties()) {
                validateType(propertyMeta.getName(), propertyMeta.getType(),
                        propertyMeta.getLineNumber());
                validateValue(propertyMeta);
            }
            for (PropertyCommentMeta propertyMeta : projectMeta.getPropertyCommentBlocks()) {
                validateType(propertyMeta.getName(), propertyMeta.getType(),
                        propertyMeta.getLineNumber());
                validateValue(propertyMeta);
            }

        }
    }

    /**
     * Method validates the type of the given property.
     *  
     * @param propetyName is the name of the property to be validated.
     * @param propertyType is the type of property to be validated.
     * @param lineNumber indicates the location of property.
     */
    private void validateType(String propetyName, String propertyType, int lineNumber) {
        if (!(propertyType.equalsIgnoreCase(PropertyMeta.BOOLEAN_TYPE)
                || propertyType.equalsIgnoreCase(PropertyMeta.FLOAT_TYPE)
                || propertyType.equalsIgnoreCase(PropertyMeta.INTEGER_TYPE) || propertyType
                .equalsIgnoreCase(PropertyMeta.STRING_TYPE))) {
            report("Property '" + propetyName + "' has invalid type as '" + propertyType
                    + "'. (Valid types: boolean|float|integer|string)", lineNumber);
        }
    }

    /**
     * Method validates the given property.
     * 
     * @param propertyMeta is the property to be validated.
     */
    private void validateValue(PropertyMeta propertyMeta) {
        String type = propertyMeta.getType();
        String value = propertyMeta.getRuntimeProject().getProperty(propertyMeta.getName());
        if (PropertyMeta.BOOLEAN_TYPE.equalsIgnoreCase(type)) {
            validateBooleanValue(propertyMeta.getName(), value, propertyMeta.getLineNumber());
        }

        if (PropertyMeta.INTEGER_TYPE.equalsIgnoreCase(type)) {
            validateIntegerValue(propertyMeta.getName(), value, propertyMeta.getLineNumber());
        }

        if (PropertyMeta.FLOAT_TYPE.equalsIgnoreCase(type)) {
            validateFloatValue(propertyMeta.getName(), value, propertyMeta.getLineNumber());
        }
    }

    /**
     * Method validates the given comment property.
     * 
     * @param propertyMeta is the comment property to be validated.
     */
    private void validateValue(PropertyCommentMeta propertyMeta) {
        String type = propertyMeta.getType();
        String value = propertyMeta.getRuntimeProject().getProperty(propertyMeta.getName());
        if (PropertyMeta.BOOLEAN_TYPE.equalsIgnoreCase(type)) {
            validateBooleanValue(propertyMeta.getName(), value, propertyMeta.getLineNumber());
        }

        if (PropertyMeta.INTEGER_TYPE.equalsIgnoreCase(type)) {
            validateIntegerValue(propertyMeta.getName(), value, propertyMeta.getLineNumber());
        }

        if (PropertyMeta.FLOAT_TYPE.equalsIgnoreCase(type)) {
            validateFloatValue(propertyMeta.getName(), value, propertyMeta.getLineNumber());
        }
    }

    /**
     * Method validates the given boolean property.
     * 
     * @param propertyName is the name of the property to be validated.
     * @param value is the property value to be validated.
     * @param lineNumber indicates the location of the property.
     */
    private void validateBooleanValue(String propertyName, String value, int lineNumber) {
        if (value != null && !value.equalsIgnoreCase("true") && !value.equalsIgnoreCase("false")) {
            report("Property '" + propertyName + "' has invalid boolean value set as '" + value
                    + "'. (Valid values: true|false)", lineNumber);
        }
    }

    /**
     * Method validates the given integer property.
     * 
     * @param propertyName is the name of the property to be validated.
     * @param value is the property value to be validated.
     * @param lineNumber indicates the location of the property.
     */
    private void validateIntegerValue(String propertyName, String value, int lineNumber) {
        try {
            if (value != null) {
                Integer.parseInt(value);
            }
        } catch (NumberFormatException nfe) {
            report("Property '" + propertyName + "' has invalid integer value set as '" + value
                    + "'.", lineNumber);
        }
    }

    /**
     * Method validates the given float property.
     * 
     * @param propertyName is the name of the property to be validated.
     * @param value is the property value to be validated.
     * @param lineNumber indicates the location of the property.
     */
    private void validateFloatValue(String propertyName, String value, int lineNumber) {
        try {
            if (value != null) {
                Double.parseDouble(value);
            }
        } catch (NumberFormatException nfe) {
            report("Property '" + propertyName + "' has invalid float value set as '" + value
                    + "'.", lineNumber);
        }
    }
}
