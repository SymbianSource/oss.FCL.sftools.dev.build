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
import java.text.BreakIterator;
import java.util.ArrayList;
import java.util.List;

import org.dom4j.Comment;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.Node;

/**
 * Meta object for an Ant project.
 */
public class ProjectMeta extends RootAntObjectMeta {
    private static final String DOC_COMMENT_MARKER = "*";

    private String description = "";

    public ProjectMeta(AntFile antFile, Element node) throws DocumentException, IOException {
        super(antFile, node);

        // Only parse a project comment if it is marked
        if (!getComment().isMarkedComment()) {
            setComment(getEmptyComment());
        }

        Element descriptionNode = ((Element) getNode()).element("description");
        // System.out.println(descriptionNode);
        if (descriptionNode != null) {
            description = AntComment.getCleanedDocNodeText(descriptionNode);
        }
    }

    public File getFile() {
        return this.getAntFile().getFile();
    }

    public String getDefault() {
        return getAttr("default");
    }

    public String getDescription() {
        return description;
    }

    public String getPackage() {
        return getComment().getTagValue("package", DEFAULT_PACKAGE);
    }

    public String getSummary() {
        String text = getDescription();
        if (text.length() == 0) {
            text = getDocumentation();
        }
        BreakIterator iterator = BreakIterator.getSentenceInstance();
        // BreakIterator iterator = BreakIterator.getLineInstance();
        iterator.setText(text);
        String summary = "";
        if (iterator.next() > 0) {
            summary = text.substring(0, iterator.current()).trim();
        }
        return summary;
    }

    @SuppressWarnings("unchecked")
    public List<TargetMeta> getTargets() throws IOException {
        ArrayList<TargetMeta> objects = new ArrayList<TargetMeta>();
        List<Node> nodes = getNode().selectNodes("target");
        for (Node targetNode : nodes) {
            TargetMeta targetMeta = new TargetMeta(this, targetNode);
            targetMeta.setRuntimeProject(getRuntimeProject());
            if (targetMeta.matchesScope(getScopeFilter())) {
                objects.add(targetMeta);
            }
        }
        return objects;
    }

    @SuppressWarnings("unchecked")
    public List<PropertyMeta> getProperties() throws IOException {
        List<PropertyMeta> properties = new ArrayList<PropertyMeta>();
        List<Node> propertyNodes = getNode().selectNodes("//property");
        for (Node propNode : propertyNodes) {
            PropertyMeta propertyMeta = new PropertyMeta(this, propNode);
            propertyMeta.setRuntimeProject(getRuntimeProject());
            if (propertyMeta.matchesScope(getScopeFilter())) {
                properties.add(propertyMeta);
            }
        }
        return properties;
    }

    @SuppressWarnings("unchecked")
    public List<MacroMeta> getMacros() throws IOException {
        ArrayList<MacroMeta> objects = new ArrayList<MacroMeta>();
        List<Element> nodes = getNode().selectNodes("//macrodef | //scriptdef");
        for (Element node : nodes) {
            MacroMeta macroMeta = new MacroMeta(this, node);
            macroMeta.setRuntimeProject(getRuntimeProject());
            if (macroMeta.matchesScope(getScopeFilter())) {
                objects.add(macroMeta);
            }
        }
        return objects;
    }

    @SuppressWarnings("unchecked")
    public List<String> getProjectDependencies() {
        ArrayList<String> objects = new ArrayList<String>();
        List<Element> importNodes = getNode().selectNodes("//import");
        for (Element node : importNodes) {
            objects.add(node.attributeValue("file"));
        }
        return objects;
    }

    @SuppressWarnings("unchecked")
    public List<String> getLibraryDependencies() {
        ArrayList<String> objects = new ArrayList<String>();
        List<Element> nodes = getNode().selectNodes("//typedef");
        for (Element node : nodes) {
            if (node.attributeValue("file") != null) {
                objects.add(node.attributeValue("file"));
            }
            else if (node.attributeValue("resource") != null) {
                objects.add(node.attributeValue("resource"));
            }
        }
        return objects;
    }

    @SuppressWarnings("unchecked")
    public List<PropertyCommentMeta> getPropertyCommentBlocks() throws IOException {
        ArrayList<PropertyCommentMeta> objects = new ArrayList<PropertyCommentMeta>();
        List<Node> nodes = getNode().selectNodes("//comment()");
        for (Node node : nodes) {
            String text = node.getText().trim();
            if (text.startsWith(DOC_COMMENT_MARKER + " @property")) {
                PropertyCommentMeta propertyCommentMeta = new PropertyCommentMeta(this, (Comment) node);
                propertyCommentMeta.setRuntimeProject(getRuntimeProject());
                objects.add(propertyCommentMeta);
            }
        }
        return objects;
    }
}
