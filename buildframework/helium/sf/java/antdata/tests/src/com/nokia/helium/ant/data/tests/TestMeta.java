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

package com.nokia.helium.ant.data.tests;

import java.io.File;
import java.io.IOException;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.List;

import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.DocumentHelper;
import org.dom4j.Node;
import org.junit.Test;
import static org.junit.Assert.*;

import com.nokia.helium.ant.data.Database;

public class TestMeta {
    @Test
    public void testProjectMeta() throws IOException, DocumentException {
        Database db = new Database(null, "public");
        List<String> paths = new ArrayList<String>();
        File testAntFile = new File(System.getProperty("testdir"), "tests/data/test_project.ant.xml");
        paths.add(testAntFile.getCanonicalPath());
        db.addAntFilePaths(paths);
        StringWriter out = new StringWriter();
        db.toXML(out);

        Document doc = DocumentHelper.parseText(out.toString());
        System.out.println(doc.asXML());

        Node database = doc.selectSingleNode("//antDatabase");

        Node project = database.selectSingleNode("project");
        assertTrue(project.valueOf("name").equals("test_project"));
        assertTrue(project.valueOf("scope").equals("public"));
        assertTrue(project.valueOf("default").equals("check-target"));
        assertTrue(project.valueOf("deprecated").equals(""));
        assertTrue(project.valueOf("description").contains("A test Ant project."));
        assertTrue(project.valueOf("location").contains("test_project.ant.xml"));
        assertTrue(project.valueOf("projectDependency").equals("random.xml"));
        assertTrue(project.valueOf("libraryDependency").equals("common.antlib.xml"));

        Node target = project.selectSingleNode("target[1]");
        assertTrue(target.valueOf("name").equals("check-target"));
        assertTrue(target.valueOf("ifDependency").equals("foo"));
        assertTrue(target.valueOf("unlessDependency").equals("bar"));
        assertTrue(target.valueOf("description").contains("A test target"));
        assertTrue(target.valueOf("scope").equals("public"));
        assertTrue(target.valueOf("deprecated").equals("Lets pretend this target is deprecated."));
        assertTrue(target.valueOf("location").contains("test_project.ant.xml"));

        Node property = project.selectSingleNode("property");
        assertTrue(property.valueOf("name").equals("property1"));
        assertTrue(property.valueOf("defaultValue").equals("value1"));
        assertTrue(property.valueOf("type").equals("string"));
        assertTrue(property.valueOf("editable").equals("recommended"));
        assertTrue(property.valueOf("scope").equals("public"));
        assertTrue(property.valueOf("deprecated").equals("Since 6.0."));
        assertTrue(property.valueOf("location").contains("test_project.ant.xml"));
        assertTrue(property.valueOf("summary").startsWith("This is a property comment summary."));

        Node macro = project.selectSingleNode("macro");
        assertTrue(macro.valueOf("name").equals("test_macro"));
        assertTrue(macro.valueOf("scope").equals("public"));
        assertTrue(macro.valueOf("deprecated").equals(""));
    }
}
