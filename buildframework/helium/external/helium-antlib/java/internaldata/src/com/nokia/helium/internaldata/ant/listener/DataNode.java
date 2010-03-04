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
import java.util.Date;

/**
 * Data node object to iterate, keep timing, name, maintain parallel tasks for the node. 
 *
 */
public abstract class DataNode {

    // Job number management
    private static long commonJobId;
    private long jobId = commonJobId++;
    // Parent node
    private DataNode parent;
    
    // children nodes.
    private Vector<DataNode> children = new Vector<DataNode>();
    
    
    
    // Statistics about the time.
    private Date startTime;
    private Date endTime;

    // Get the thread id. this is important for parallel tasks.
    private long threadId = Thread.currentThread().getId();
    
    // reference for the data.
    private Object reference; 
    
    public DataNode(DataNode parent, Object reference) {
        this.parent = parent;
        if (parent != null) {
            parent.add(this);
        }
        this.setStartTime(new Date());
        this.setReference(reference);
    }
    
    /**
     * Method used to register a child to it's parent.
     * @param child, the child to register.
     */
    public void add(DataNode child) {
        children.add(child);
    }

    /**
     * Return an iterator on this node children
     * @return the iterator
     */
    public Iterator<DataNode> iterator() {
        return children.iterator();
    }

    /**
     * Method used to remove a node from it's parent
     * @param child, the child to remove.
     */
    public void remove(DataNode child) {
        children.remove(child);
    }

    /**
     * Is the node containing any children.
     * @return true is the node is empty
     */
    public boolean isEmpty() {
        return children.isEmpty();
    }
    
    /**
     * Returns the parent node, or null if the root.
     * @return a DataNode.
     */
    public DataNode getParent() {
        return parent;
    }

    public Date getStartTime() {
        return startTime;
    }

    public void setStartTime(Date startTime) {
        this.startTime = startTime;
    }

    /**
     * Make is reliable: if end time doesn't exists let's use the start time.
     */
    public Date getEndTime() {
        if (endTime != null)
            return endTime;
        else
            return this.getStartTime();
    }

    public void setEndTime(Date endTime) {
        this.endTime = endTime;
    }
    
    /**
     * Return the thread where the class has been created under.
     * @return thread id as a long.
     */
    public long getThreadId() {
        return this.threadId;
    }

    public Object getReference() {
        return reference;
    }

    public void setReference(Object reference) {
        this.reference = reference;
    }
    
    public long getJobId() {
        return jobId;
    }

    /**
     * Find a node using its reference.
     * @param reference object
     * @return
     */
    public DataNode find(Object reference) {
        if (this.reference == reference)
            return this;        
        for (Iterator<DataNode> i = children.iterator() ; i.hasNext() ; ) {
            DataNode node = i.next();
            DataNode result = node.find(reference);
            if (result != null)
                return result;
        }
        return null;
    }
    

    /**
     * Name of the node. 
     * @return name of the node (e.g target name for targets)
     */
    public abstract String getName();
    
    /**
     * Default string representation.
     */
    public String toString() {
        return getName();
    }
}
