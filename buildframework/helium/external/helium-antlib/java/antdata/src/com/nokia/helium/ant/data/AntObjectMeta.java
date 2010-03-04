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

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.tools.ant.Project;
import org.dom4j.Comment;
import org.dom4j.Element;
import org.dom4j.Node;

/**
 * Base class for all Ant Meta objects. Each Ant object is represented by a meta
 * object that provides core and additional data about it.
 */
public class AntObjectMeta {

    public static final Map<String, Integer> SCOPES = new HashMap<String, Integer>() {
        {
            put("public", new Integer(1));
            put("protected", new Integer(2));
            put("private", new Integer(3));
        }
    };
    /** The default scope if an element does not have a defined scope. */
    public static final String DEFAULT_SCOPE = "public";

    private static AntComment emptyComment;

    private Project rootProject;

    /** The parent meta object. */
    private AntObjectMeta parent;
    /** The dom4j XML Element of the Ant object represented by this meta object. */
    private Node node;
    /** The AntComment of any preceeding comment block. */
    private AntComment comment = emptyComment;

    static {
        try {
            emptyComment = new AntComment();
        }
        catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * Constructor.
     * 
     * @param parent The parent meta object.
     * @param node The XML node of the Ant object.
     * @throws IOException
     */
    public AntObjectMeta(AntObjectMeta parent, Node node) throws IOException {
        this.parent = parent;
        this.node = node;
        processComment();
    }

    public Project getRuntimeProject() {
        return rootProject;
    }

    public void setRuntimeProject(Project project) {
        this.rootProject = project;
    }

    /**
     * Gets an attribute if a value is available, otherwise returns an emtpy
     * string.
     * 
     * @param name Attribute name.
     * @return Attribute value.
     */
    protected String getAttr(String name) {
        if (node.getNodeType() == Node.ELEMENT_NODE) {
            String value = ((Element) node).attributeValue(name);
            if (value != null) {
                return value;
            }
        }
        return "";
    }

    protected Node getNode() {
        return node;
    }

    protected AntComment getEmptyComment() {
        return emptyComment;
    }

    /**
     * Returns the meta object of the top-level project for this Ant object.
     */
    public RootAntObjectMeta getRootMeta() {
        if (parent instanceof RootAntObjectMeta) {
            return (RootAntObjectMeta) parent;
        }
        return parent.getRootMeta();
    }

    /**
     * Returns the Ant file this Ant object is contained in.
     */
    public AntFile getAntFile() {
        return getRootMeta().getAntFile();
    }

    /**
     * Returns the top-level database object.
     */
    public Database getDatabase() {
        return getAntFile().getDatabase();
    }

    /**
     * Returns the name of the object or an empty string.
     * 
     * @return Object name.
     */
    public String getName() {
        String name = getAttr("name");
        if (name.length() == 0) {
            name = getComment().getObjectName();
            if (name.length() == 0) {
                try {
                    System.out.println("name is 0 length: " + getLocation());
                    // System.out.println(node.toString());
                }
                catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        return name;
    }

    /**
     * Returns the location path of the object.
     * 
     * @return Location path string.
     * @throws IOException
     */
    public String getLocation() throws IOException {
        RootAntObjectMeta rootMeta = getRootMeta();
        return rootMeta.getFile().getCanonicalPath();
    }

    /**
     * Returns the first line summary from a doc comment.
     * 
     * @return The documentation text.
     */
    public String getSummary() {
        return getComment().getSummary();
    }

    /**
     * Returns the documentation block from a associated comment.
     * 
     * @return The documentation text.
     */
    public String getDocumentation() {
        return getComment().getDocumentation();
    }

    /**
     * Returns the scope of the object, or an empty string. This could be
     * public, protected or private.
     * 
     * @return The object scope.
     */
    public String getScope() {
        String scope = getComment().getTagValue("scope");
        if (scope.equals("")) {
            scope = DEFAULT_SCOPE;
        }
        return scope;
    }

    public boolean matchesScope(String scopeFilter) {
        if (!SCOPES.containsKey(scopeFilter)) {
            throw new IllegalArgumentException("Invalid scope filter: " + scopeFilter);
        }
        String scope = getScope();
        if (!SCOPES.containsKey(scope)) {
            log("Invalid scope: " + scope + ", " + toString(), Project.MSG_WARN);
            return false;
        }
        return SCOPES.get(scope).compareTo(SCOPES.get(scopeFilter)) <= 0;
    }

    /**
     * Returns the deprecated text if the object has been deprecated, or an
     * empty string.
     * 
     * @return Deprecated descripion.
     */
    public String getDeprecated() {
        return comment.getTagValue("deprecated");
    }

    /**
     * Returns the source XML of the object.
     * 
     * @return The XML string.
     */
    public String getSource() {
        // Add the raw XML content of the element
        String sourceXml = node.asXML();
        // Replace the CDATA end notation to avoid nested CDATA sections
        sourceXml = sourceXml.replace("]]>", "] ]>");
        return sourceXml;
    }

    /**
     * Returns the AntComment that represents a preceeding comment.
     * 
     * @return An Ant comment.
     */
    protected AntComment getComment() {
        return comment;
    }

    protected void setComment(AntComment comment) {
        this.comment = comment;
    }

    private void processComment() throws IOException {
        Comment commentNode = getCommentNode();
        if (commentNode != null) {
            comment = new AntComment(commentNode);
        }
    }

    @SuppressWarnings("unchecked")
    private Comment getCommentNode() {
        Node commentNode = null;
        if (node.getNodeType() == Node.COMMENT_NODE) {
            commentNode = node;
        }
        else {
            List<Node> children = node.selectNodes("preceding-sibling::node()");
            if (children.size() > 0) {
                // Scan past the text nodess, which are most likely whitespace
                int index = children.size() - 1;
                Node child = children.get(index);
                while (index > 0 && child.getNodeType() == Node.TEXT_NODE) {
                    index--;
                    child = children.get(index);
                }

                // Check if there is a comment node
                if (child.getNodeType() == Node.COMMENT_NODE) {
                    commentNode = child;
                    log("Node has comment: " + node.getStringValue(), Project.MSG_DEBUG);
                }
                else {
                    log("Node has no comment: " + node.toString(), Project.MSG_WARN);
                }
            }
        }
        return (Comment)commentNode;
    }

    public void log(String text, int level) {
        Project project = getRuntimeProject();
        if (project != null) {
            project.log(text, level);
        }
    }
}
