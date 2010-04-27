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

import org.apache.tools.ant.Target;
/**
 * Object to keep trace for memory usage, based on start heap and end heap of a target.
 *
 */
public class TargetNode extends DataNode {

    private String name;

    // location
    private String filename;
    private int line = -1;
    
    // Memory usage
    private long startUsedHeap;
    private long startCommittedHeap;
    private long endUsedHeap;
    private long endCommittedHeap;
    
    public TargetNode(DataNode parent, Target target) {
        super(parent, target);
        this.setFilename(target.getLocation().getFileName());
        this.setLine(target.getLocation().getLineNumber());        
        name = target.getName();
    }

    public String getName() {
        return name;
    } 

    public String getFilename() {
        return filename;
    }

    public void setFilename(String filename) {
        this.filename = filename;
    }

    public int getLine() {
        return line;
    }

    public void setLine(int line) {
        this.line = line;
    }

    public long getStartUsedHeap() {
        return startUsedHeap;
    }

    public void setStartUsedHeap(long startUsedHeap) {
        this.startUsedHeap = startUsedHeap;
    }

    public long getStartCommittedHeap() {
        return startCommittedHeap;
    }

    public void setStartCommittedHeap(long startCommittedHeap) {
        this.startCommittedHeap = startCommittedHeap;
    }

    public long getEndUsedHeap() {
        return endUsedHeap;
    }

    public void setEndUsedHeap(long endUsedHeap) {
        this.endUsedHeap = endUsedHeap;
    }

    public long getEndCommittedHeap() {
        return endCommittedHeap;
    }

    public void setEndCommittedHeap(long endCommittedHeap) {
        this.endCommittedHeap = endCommittedHeap;
    }
    
}
