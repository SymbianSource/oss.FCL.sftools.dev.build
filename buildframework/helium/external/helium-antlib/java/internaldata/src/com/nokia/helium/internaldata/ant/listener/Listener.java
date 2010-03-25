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

import java.util.Hashtable;
import java.util.Date;
import com.nokia.helium.internaldata.ant.taskdefs.HlmAssertMessage;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.SubBuildListener;
import org.dom4j.Document;
import org.apache.log4j.Logger;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.MemoryUsage;

/**
 * Listener class for the Logger.
 *
 */
public class Listener implements BuildListener, SubBuildListener {

    // Logger for listener
    private Logger log;
        
    // Root node.
    private BuildNode buildNode;
    
    // Ant build Stack. Useful to associate with current parent.
    private EndLessStack<DataNode> buildEventStack = new EndLessStack<DataNode>();
    
    // default list of properties to extract.
    private String[] propList = {"os.name", "user.name", "build.name", "build.number", "build.id", "build.family", "build.system", "env.NUMBER_OF_PROCESSORS", "helium.version", "env.SYMSEE_VERSION", "diamonds.build.id"};

    // Memory bean 
    private MemoryMXBean mbean;
    
    public Listener() {
        log = Logger.getLogger(Listener.class);
        mbean = ManagementFactory.getMemoryMXBean();
    }
    
    /**
     * Method to call to trigger the data sending.
     */
    public void sendData(String smtpServer, BuildEvent event) {
        if (buildNode != null) {
            Document database = null;        
            //TreeDumper dumper = new TreeDumper(buildNode);
            //dumper.dump();
            try {
                log.debug("Creating the XML log.");
                XMLRenderer writer = new XMLRenderer(buildNode, database, this.extractProperties(), event);
                EmailDataSender sender = new EmailDataSender();
                // Setting the server address.
                sender.setSMTPServer(smtpServer);
                log.debug("Sending the data.");
                String xml = writer.toString();
                log.debug(xml);
                sender.sendData(xml);
            } catch (Exception e) {
                // We are Ignoring the errors as no need to fail the build.
                log.debug("Error: error generating the InterData database XML.", e);
            }
        }
    }

    
    
    /**
     * Extracting properties from the build.
     * @return a hashtable containing relevant properties and their value.
     */
    @SuppressWarnings("unchecked")
    private Hashtable<String, String> extractProperties() {
        Hashtable<String, String> properties = new Hashtable<String, String>();
        if (buildNode != null) {
            Project project = (Project)buildNode.getReference();
            Hashtable<String, String> projProps = project.getProperties();
            for (int i = 0; i < propList.length; i++) {
                if (projProps.containsKey(propList[i])) {
                    properties.put(propList[i], projProps.get(propList[i]));
                }
            }
        }
        return properties;
    }
    
    //-------------------------------------------------------------
    //
    // Implementing BuildListener and SubBuildListener interface
    //
    //-------------------------------------------------------------
    public synchronized void buildFinished(BuildEvent event) {
        log.debug("buildFinished");
        if (buildNode != null) {
            BuildNode node = (BuildNode)buildNode.find(event.getProject());
            if (node != null) {
                node.setEndTime(new Date());
                node.setSuccessful(event.getException() == null);
            }
        }
        String smtpServer = event.getProject().getProperty("email.smtp.server");
        this.sendData(smtpServer, event);
    }

    public synchronized void buildStarted(BuildEvent event) {
        if (buildNode == null) {
            // Create data node for a build
            buildNode = new BuildNode(null, event.getProject());
            // Garbage collector for execution. 
            buildEventStack.setDefaultElement(buildNode);
        }
    }

    public synchronized void subBuildFinished(BuildEvent event) {
        if (buildNode != null) {
            BuildNode node = (BuildNode)buildNode.find(event.getProject());
            if (node != null) {
                node.setEndTime(new Date());
                node.setReference(null);
                node.setSuccessful(event.getException() == null);
            } else {
                log.debug("subBuildFinished - could not find subbuild.");
            }
            buildEventStack.pop();
        }
    }

    public synchronized void subBuildStarted(BuildEvent event) {
        DataNode parentNode = buildEventStack.peek();
        if (parentNode != null) {
            BuildNode node = new BuildNode(parentNode, event.getProject());
            buildEventStack.push(node);
        }
    }

    public void messageLogged(BuildEvent event) {
        // Ignoring message logging.
    }

    public synchronized void targetFinished(BuildEvent event) {
        if (buildNode != null) {
            DataNode node = buildNode.find(event.getTarget());
            if (node != null) {
                node.setEndTime(new Date());
                MemoryUsage mem = mbean.getHeapMemoryUsage();
                TargetNode tnode = (TargetNode)node;
                tnode.setEndUsedHeap(mem.getUsed());
                tnode.setEndCommittedHeap(mem.getCommitted());
                node.setReference(null);
            } else {
                log.debug("targetFinished - could not find target.");
            }
            buildEventStack.pop();
        }
    }

    public synchronized void targetStarted(BuildEvent event) {
        DataNode parentNode = buildEventStack.peek();
        if (parentNode != null) {
            TargetNode node = new TargetNode(parentNode, event.getTarget());
            MemoryUsage mem = mbean.getHeapMemoryUsage();
            node.setStartUsedHeap(mem.getUsed());
            node.setStartCommittedHeap(mem.getCommitted());
            buildEventStack.push(node);
        } else {
            log.debug("targetStarted - could not find parent.");
        }
    }

    public synchronized void taskFinished(BuildEvent event) {
        // Ignoring task information
    }

    public synchronized void taskStarted(BuildEvent event) {
        // Ignoring task information
    }
    
    public void addAssertTask(HlmAssertMessage assertTask) { 
        if (buildNode != null) {
            DataNode parentNode = buildNode.find(assertTask.getOwningTarget());
            if (parentNode != null) {
                new AssertNode(parentNode, assertTask);
            } else {
                new AssertNode(buildEventStack.peek(), assertTask);
            }
        }
        
    }
}