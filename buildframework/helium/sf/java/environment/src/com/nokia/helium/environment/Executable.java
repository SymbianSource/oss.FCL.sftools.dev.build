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

package com.nokia.helium.environment;

import java.io.File;

/**
 * An executable on the file system.
 */
public class Executable {

    private String name;
    private String version = "unknown";
    private String path;
    private String hash;
    private long lastModified;
    private long length;
    private boolean executed;

    public Executable(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getNameNoExt() {
        String nameNoExt = name;
        if (nameNoExt.contains(".")) {
            nameNoExt = nameNoExt.substring(0, nameNoExt.indexOf("."));
        }
        return nameNoExt;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public String getHash() {
        return hash;
    }

    public void setHash(String hash) {
        this.hash = hash;
    }

    public long getLastModified() {
        return lastModified;
    }

    public void setLastModified(long lastModified) {
        this.lastModified = lastModified;
    }

    public long getLength() {
        return length;
    }

    public void setLength(long length) {
        this.length = length;
    }

    public boolean isExecuted() {
        return executed;
    }

    public void setExecuted(boolean executed) {
        this.executed = executed;
    }

    public boolean equals(Object object) {
        if (object != null && object instanceof Executable) {
            Executable executable = (Executable) object;
            if (executable.getPath() != null && path != null) {
                return executable.getPath().toLowerCase().equals(path.toLowerCase());
            }
            return executable.getName().equals(name);
        }
        return false;
    }

    public int hashCode() {
        return name.hashCode();
    }

    public String toString() {
        if (path != null) {
            return path + File.separator + name;
        }
        return name;
    }
}
