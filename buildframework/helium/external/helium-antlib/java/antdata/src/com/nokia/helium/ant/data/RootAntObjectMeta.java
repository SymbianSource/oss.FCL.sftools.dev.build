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

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.dom4j.Element;

/**
 * Abstract meta object that represents the root objects found in Ant files.
 */
public class RootAntObjectMeta extends AntObjectMeta {
    static final String DEFAULT_PACKAGE = "(default)";

    private AntFile antFile;
    private String scopeFilter;

    public RootAntObjectMeta(AntFile antFile, Element node) throws IOException {
        super(null, node);
        this.antFile = antFile;
    }

    public String getPackage() {
        return getComment().getTagValue("package", DEFAULT_PACKAGE);
    }

    public File getFile() {
        return antFile.getFile();
    }

    public AntFile getAntFile() {
        return antFile;
    }

    public void setScopeFilter(String scopeFilter) {
        this.scopeFilter = scopeFilter;
    }

    public String getScopeFilter() {
        return scopeFilter;
    }

    public RootAntObjectMeta getRootMeta() {
        return this;
    }

    @SuppressWarnings("unchecked")
    public List<MacroMeta> getMacros() throws IOException {
        ArrayList<MacroMeta> objects = new ArrayList<MacroMeta>();
        List<Element> nodes = getNode().selectNodes("//macrodef | //scriptdef");
        for (Element node : nodes) {
            MacroMeta macroMeta = new MacroMeta(this, node);
            macroMeta.setRuntimeProject(getRuntimeProject());
            if (macroMeta.matchesScope(scopeFilter)) {
                objects.add(macroMeta);
            }
        }
        return objects;
    }
}
