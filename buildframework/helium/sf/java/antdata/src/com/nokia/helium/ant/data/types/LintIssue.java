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

import com.nokia.helium.ant.data.AntFile;

/**
 * An Ant lint issue.
 */
public class LintIssue {
    private String description;
    private int level;
    private AntFile antfile;
    private String location;
    
    public LintIssue(String description, int level, String location) {
        super();
        this.description = description;
        this.level = level;
        this.location = location;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public int getSeverity() {
        return level;
    }

    public void setLevel(int level) {
        this.level = level;
    }

    public AntFile getAntfile() {
        return antfile;
    }

    public void setAntfile(AntFile antfile) {
        this.antfile = antfile;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }
}
