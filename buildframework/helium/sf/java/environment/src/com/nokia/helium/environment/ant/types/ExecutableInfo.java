/*
 * Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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

package com.nokia.helium.environment.ant.types;

import org.apache.tools.ant.types.DataType;

/**
 * Provides information about an executable.
 * 
 * @ant.task name="executableinfo" category="Environment"
 */
public class ExecutableInfo extends DataType {
    private String name;
    private String dir;
    private String versionArgs;
    private String versionRegex;
    private String output;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDir() {
        return dir;
    }

    public void setDir(String dir) {
        this.dir = dir;
    }

    public String getVersionArgs() {
        return versionArgs;
    }

    public void setVersionArgs(String versionArgs) {
        this.versionArgs = versionArgs;
    }

    public String getVersionRegex() {
        return versionRegex;
    }

    public void setVersionRegex(String versionRegex) {
        this.versionRegex = versionRegex;
    }

    public String getOutput() {
        return output;
    }

    public void setOutput(String output) {
        this.output = output;
    }

    public boolean equals(Object obj) {
        if (obj == null || !(obj instanceof ExecutableInfo)) {
            return false;
        }
        ExecutableInfo def = (ExecutableInfo) obj;
        if (this.name.equals(def.getName())) {
            if ((this.dir == null && def.getDir() == null)
                    || (this.dir != null && def.getDir() != null && this.dir.toLowerCase().equals(def.getDir().toLowerCase()))) {
                return true;
            }
        }
        return false;
    }
    
    public int hashCode() {
        return name.hashCode();
    }

    public String toString() {
        return name + " " + versionArgs;
    }
}


