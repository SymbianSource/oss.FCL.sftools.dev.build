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
import java.util.Iterator;
import java.util.List;

import org.dom4j.Comment;
import org.dom4j.Document;
import org.dom4j.DocumentHelper;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.XPath;

/**
 * Meta object for an Ant project.
 */
public class ProjectMeta extends RootAntObjectMeta {
    private static final String DOC_COMMENT_MARKER = "*";

    private String description = "";

    public ProjectMeta(AntFile antFile, Element node) throws IOException {
        super(antFile, node);

        // Only parse a project comment if it is marked
        if (!getComment().isMarkedComment()) {
            setComment(getEmptyComment());
        }

        Element descriptionNode = ((Element) getNode()).element("description");
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
        iterator.setText(text);
        String summary = "";
        if (iterator.next() > 0) {
            summary = text.substring(0, iterator.current()).trim();
        }
        return summary;
    }

    @SuppressWarnings("unchecked")
    public List<TargetMeta> getTargets() {
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
    public List<PropertyMeta> getProperties() {
        List<PropertyMeta> properties = new ArrayList<PropertyMeta>();
        List<Node> propertyNodes = getNode().selectNodes("//property[string-length(@name)>0]");
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
    public List<PropertyCommentMeta> getPropertyCommentBlocks() {
        ArrayList<PropertyCommentMeta> objects = new ArrayList<PropertyCommentMeta>();
        List<Node> nodes = getNode().selectNodes("//comment()");
        for (Node node : nodes) {
            String text = node.getText().trim();
            if (text.startsWith(DOC_COMMENT_MARKER + " @property")) {
                PropertyCommentMeta propertyCommentMeta = new PropertyCommentMeta(this, (Comment) node);
                propertyCommentMeta.setRuntimeProject(getRuntimeProject());
                if (propertyCommentMeta.matchesScope(getScopeFilter())) {
                    objects.add(propertyCommentMeta);
                }
            }
        }
        return objects;
    }

    @SuppressWarnings("unchecked")
    public void getConfigSignals(String targetName, List<String> signals) {
        XPath xpath = DocumentHelper.createXPath("//hlm:signalListenerConfig[@target='"
            + targetName + "']");
        xpath.setNamespaceURIs(Database.NAMESPACE_MAP);
        List<Node> signalNodes = xpath.selectNodes(getNode());
        for (Iterator<Node> iterator = signalNodes.iterator(); iterator.hasNext();) {
            Element propertyNode = (Element) iterator.next();
            String signalid = propertyNode.attributeValue("id");
            String failbuild = findSignalFailMode(signalid, getNode().getDocument());
            signals.add(signalid + "(" + failbuild + ")");
        }
    }

    @SuppressWarnings("rawtypes")
    private String findSignalFailMode(String signalid, Document antDoc) {
        XPath xpath2 = DocumentHelper.createXPath("//hlm:signalListenerConfig[@id='" + signalid
            + "']/signalNotifierInput/signalInput");
        xpath2.setNamespaceURIs(Database.NAMESPACE_MAP);
        List signalNodes3 = xpath2.selectNodes(antDoc);
        for (Iterator iterator3 = signalNodes3.iterator(); iterator3.hasNext();) {
            Element propertyNode3 = (Element) iterator3.next();
            String signalinputid = propertyNode3.attributeValue("refid");

            XPath xpath3 = DocumentHelper.createXPath("//hlm:signalInput[@id='" + signalinputid
                + "']");
            xpath3.setNamespaceURIs(Database.NAMESPACE_MAP);
            List signalNodes4 = xpath3.selectNodes(antDoc);
            for (Iterator iterator4 = signalNodes4.iterator(); iterator4.hasNext();) {
                Element propertyNode4 = (Element) iterator4.next();
                return propertyNode4.attributeValue("failbuild");
            }
        }
        return null;
    }
}
