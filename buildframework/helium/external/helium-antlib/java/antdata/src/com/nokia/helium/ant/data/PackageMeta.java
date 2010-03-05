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

import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.Project;

/**
 * A package is a collection of related Ant projects.
 */
public class PackageMeta {
    private Project rootProject;
    private String name;
    private String summary = "";
    private ArrayList<RootAntObjectMeta> objects = new ArrayList<RootAntObjectMeta>();

    public PackageMeta(String name) {
        this.name = name;
    }

    public Project getRuntimeProject() {
        return rootProject;
    }

    public void setRuntimeProject(Project project) {
        this.rootProject = project;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getSummary() {
        return summary;
    }

    public String getDocumentation() {
        return summary;
    }

    public void addObject(RootAntObjectMeta rootAntObjectMeta) {
        objects.add(rootAntObjectMeta);
    }

    public List<ProjectMeta> getProjects() {
        List<ProjectMeta> projects = new ArrayList<ProjectMeta>();
        for (RootAntObjectMeta objectMeta : objects) {
            if (objectMeta instanceof ProjectMeta) {
                projects.add((ProjectMeta) objectMeta);
            }
        }
        return projects;
    }

    public List<AntlibMeta> getAntlibs() {
        List<AntlibMeta> antlibs = new ArrayList<AntlibMeta>();
        for (RootAntObjectMeta objectMeta : objects) {
            if (objectMeta instanceof AntlibMeta) {
                antlibs.add((AntlibMeta) objectMeta);
            }
        }
        return antlibs;
    }
}
