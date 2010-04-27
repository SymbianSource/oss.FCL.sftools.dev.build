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

package com.nokia.helium.ant.data.types;

import java.io.IOException;
import java.util.List;

import org.apache.tools.ant.Project;

import com.nokia.helium.ant.data.PropertyMeta;

/**
 * An AntLint check of the type of a property.
 */
public class WrongTypePropertyCheck extends AntLintCheck {
    public static final String DESCRIPTION = "Property value does not match type";

    public WrongTypePropertyCheck() {
    }

    @Override
    public void run() throws IOException {
        List<PropertyMeta> properties = getDb().getProperties();
        log("Properties total: " + properties.size(), Project.MSG_DEBUG);
        for (PropertyMeta propertyMeta : properties) {
            String type = propertyMeta.getType();
            String value = propertyMeta.getValue();
            if (value != null) {
                log("Testing for wrong type: " + propertyMeta.getName() + ", type: " + type, Project.MSG_DEBUG);
                if (type.equals("integer")) {
                    try {
                        Integer.decode(value);
                    }
                    catch (NumberFormatException e) {
                        getTask().addLintIssue(new LintIssue(DESCRIPTION, getSeverity(), propertyMeta.getLocation()));
                    }
                }
            }
            else {
                log("Testing for wrong type: " + propertyMeta.getName() + ": value cannot be found", Project.MSG_DEBUG);
            }
        }
    }
}



