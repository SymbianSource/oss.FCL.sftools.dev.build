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

import org.apache.tools.ant.Project;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.io.SAXReader;

/**
 * An Ant build file. It could be a project file or an antlib file.
 */
public class AntFile {
    private Database database;
    private File path;
    private Document doc;
    private RootAntObjectMeta fileObjectMeta;
    private Project rootProject;

    public AntFile(Database database, String path) throws IOException {
        this(database, path, Database.DEFAULT_SCOPE);
    }

    public AntFile(Database database, String path, String scope) throws IOException {
        this.database = database;
        this.path = new File(path);
        SAXReader xmlReader = new SAXReader();
        try {
            doc = xmlReader.read(path);

            Element node = doc.getRootElement();
            if (node.getName().equals("project")) {
                fileObjectMeta = new ProjectMeta(this, node);
            }
            else {
                fileObjectMeta = new AntlibMeta(this, node);
            }

            fileObjectMeta.setScopeFilter(scope);
            fileObjectMeta.setRuntimeProject(rootProject);
        }
        catch (DocumentException e) {
            throw new IOException(e.getMessage());
        }
    }

    public Project getProject() {
        return rootProject;
    }

    public void setProject(Project project) {
        this.rootProject = project;
        fileObjectMeta.setRuntimeProject(rootProject);
    }

    public void setScope(String scope) {
        fileObjectMeta.setScopeFilter(scope);
    }

    /**
     * Get the meta object for the Ant project in this build file.
     * 
     * @return The project meta object.
     * @throws DocumentException
     */
    public RootAntObjectMeta getRootObjectMeta() throws IOException {
        return fileObjectMeta;
    }

    /**
     * The File path of the Ant file.
     * 
     * @return Path.
     */
    public File getFile() {
        return path;
    }

    public Database getDatabase() {
        return database;
    }

    @SuppressWarnings("unchecked")
    public List<AntFile> getAntlibs() throws IOException {
        Element node = doc.getRootElement();
        List<AntFile> antlibFiles = new ArrayList<AntFile>();
        if (node.getName().equals("project")) {
            List<Node> typedefs = node
                    .selectNodes("//*[namespace-uri()='http://www.nokia.com/helium' and local-name()='typedef']");
            for (Node typedefNode : typedefs) {
                String filePath = ((Element) typedefNode).attributeValue("file");
                filePath = getProject().replaceProperties(filePath);
                antlibFiles.add(new AntFile(database, filePath));
            }
        }
        return antlibFiles;
    }
}
