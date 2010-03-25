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

package com.nokia.helium.internaldata.ant.listener;

import java.util.Iterator;
import java.util.Vector;
import java.util.Hashtable;
import java.util.Enumeration;
import java.io.ByteArrayOutputStream;

import org.dom4j.Document;
import org.dom4j.DocumentHelper;
import org.dom4j.Element;
import org.dom4j.io.XMLWriter;
import org.dom4j.io.OutputFormat;

import org.apache.tools.ant.BuildEvent;
/**
 * This xml render object does the following - 
 * Generates target only for TargetNode type of node
 * Creates the targets section.
 * Generates task only for TargetNode type of node
 * Creates the task section.
 * Creates execution tree recursively, visiting the DataNodes.
 * Creates the execution tree section.
 * Creates the property section.
 * Renders the build node into XML string. 
 */
public class XMLRenderer {

    // Dump of properties
    private Hashtable<String, String> properties;
    // the toplevel node.
    private BuildNode root;
    // Helium content database. 
    private Document database;
    
    // Deps hashes: helper to remove duplicates.
    private Vector<String> targetList = new Vector<String>();
    private Vector<String> assertList = new Vector<String>();
    
    public XMLRenderer(BuildNode root, Document database, Hashtable<String, String> properties, BuildEvent event) {
        this.root = root; 
        this.database = database;
        this.properties = properties;
    }

    /**
     * Generating target only for TargetNode type of node
     * @param node
     * @param targets
     */
    protected void createTarget(DataNode node, Element targets) {
        if (node instanceof TargetNode) {
            TargetNode targetNode = (TargetNode)node;            
            if (!targetList.contains(targetNode.getName() + targetNode.getFilename())) {
                targetList.add(targetNode.getName() + targetNode.getFilename());
                Element target = targets.addElement("target");
                target.addAttribute("id", "target@" + targetList.indexOf(targetNode.getName() + targetNode.getFilename()));
                target.addAttribute("name", targetNode.getName());
                target.addAttribute("file", targetNode.getFilename());
                target.addAttribute("line", "" + targetNode.getLine());
            }
        }
        for (Iterator<DataNode> i = node.iterator() ; i.hasNext() ; ) {
            createTarget(i.next(), targets);
        }
    }

    /**
     * Creating the targets section.
     * @param statistics
     */
    protected void createTargets(Element statistics) {
        Element targets = statistics.addElement("targets");
        if (root != null) {
            createTarget(root, targets);
        }
    }
    
    /**
     * Creating the assert section.
     * @param statistics
     */
    protected void createAsserts(Element statistics) {
        Element asserts = statistics.addElement("asserts");
        if (root != null) {
            createAssert(root, asserts);
        }
    }
    
    /**
     * Generating assert only for TargetNode type of node
     * @param node
     * @param targets
     */
    protected void createAssert(DataNode node, Element targets) {
        
        if (node instanceof AssertNode) {
            AssertNode assertNode = (AssertNode)node;
            if (assertNode.getAssertName() != null) {
                assertList.add(assertNode.getAssertName());
                Element target = targets.addElement("assert");
                target.addAttribute("id", "assert@" + assertList.indexOf(assertNode.getAssertName()));
                target.addAttribute("name", assertNode.getAssertName());
                target.addAttribute("file", assertNode.getFilename());
                target.addAttribute("line", "" + assertNode.getLine());
                target.addAttribute("message", "" + assertNode.getMessage());
            }
            
        }
        for (Iterator<DataNode> i = node.iterator() ; i.hasNext() ; ) {
            createAssert(i.next(), targets);
        }
    }

    /**
     * Creating execution tree recursively, visiting the DataNodes.
     * @param node
     * @param tree
     */
    protected void createTree(DataNode node, Element tree) {
        Element elt = null;
        if (node instanceof BuildNode) {
            BuildNode buildNode = (BuildNode)node;
            elt = tree.addElement("build");
            elt.addAttribute("name", buildNode.getName());            
            elt.addAttribute("startTime", "" + buildNode.getStartTime().getTime());
            elt.addAttribute("endTime", "" + buildNode.getEndTime().getTime());
            elt.addAttribute("status", buildNode.getSuccessful() ? "successful" : "failed");            
            elt.addAttribute("thread", "" + buildNode.getThreadId());            
        } else if (node instanceof TargetNode) {
            TargetNode targetNode = (TargetNode)node;
            elt = tree.addElement("targetRef");
            elt.addAttribute("reference", "target@" + targetList.indexOf(targetNode.getName() + targetNode.getFilename()));
            elt.addAttribute("startTime", "" + targetNode.getStartTime().getTime());
            elt.addAttribute("endTime", "" + targetNode.getEndTime().getTime());
            elt.addAttribute("thread", "" + targetNode.getThreadId());
            elt.addAttribute("startUsedHeap", "" + targetNode.getStartUsedHeap());
            elt.addAttribute("startCommittedHeap", "" + targetNode.getStartCommittedHeap());
            elt.addAttribute("endUsedHeap", "" + targetNode.getEndUsedHeap());
            elt.addAttribute("endCommittedHeap", "" + targetNode.getEndCommittedHeap());
        } else if (node instanceof AssertNode) {
            AssertNode assertNode = (AssertNode)node;
            if (assertNode.getAssertName() != null) {
                elt = tree.addElement("assertRef");
                elt.addAttribute("reference", "assert@" + assertList.indexOf(assertNode.getAssertName()));
                elt.addAttribute("startTime", "" + assertNode.getStartTime().getTime());
                elt.addAttribute("endTime", "" + assertNode.getEndTime().getTime());
                elt.addAttribute("thread", "" + assertNode.getThreadId());
            }
        }
        
        if (elt != null) {
            for (Iterator<DataNode> i = node.iterator() ; i.hasNext() ; ) {
                createTree(i.next(), elt);
            }
        }
    }
    
    /**
     * Creating the execution tree section.
     * @param statistics
     */
    protected void createExecutionTree(Element statistics) {
        Element executionTree = statistics.addElement("executionTree");
        if (root != null) {
            createTree(root, executionTree);
        }
    }

    /**
     * Creating the property section.
     * @param statistics
     */
    protected void createProperties(Element statistics) {
        Element propertiesElt = statistics.addElement("properties");
        if (properties != null) {
            for (Enumeration<String> e = properties.keys(); e.hasMoreElements() ; ) {
                String key = e.nextElement();
                Element propertyElt = propertiesElt.addElement("property");
                propertyElt.addAttribute("name", key);
                propertyElt.addAttribute("value", properties.get(key));
            }
        }
    }
    
    protected void insertDatabase(Element statistics) {
        if (database != null) {
            Element databaseElt = statistics.addElement("database");
            databaseElt.add(database.getRootElement().detach());
        }
    }
    
    /**
     * Rendering the build node into XML string. 
     */
    public String toString() {
        // Creating the XML document
        Document document = DocumentHelper.createDocument();
        Element statistics = document.addElement( "statistics" );
        statistics.addAttribute("version", "1.1");
        
        // Creating the document content.
        insertDatabase(statistics);
        createTargets(statistics);
        createAsserts(statistics);
        createExecutionTree(statistics);
        createProperties(statistics);
        try {
            ByteArrayOutputStream output = new ByteArrayOutputStream(); 
            XMLWriter out = new XMLWriter(output, OutputFormat.createPrettyPrint());
            out.write(document);
            return output.toString();
        } catch (Exception exc) {
            return document.asXML();            
        }        
    }
    
}
