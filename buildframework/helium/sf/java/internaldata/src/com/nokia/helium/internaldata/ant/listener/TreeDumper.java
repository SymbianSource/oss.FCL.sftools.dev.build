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
/**
 * Helper class to fix indentation of the xml.
 *
 */
public class TreeDumper {
    
    private DataNode rootNode;
    
    public TreeDumper(DataNode root) {
        this.rootNode = root;
    }
    
    public void dump() {
        dump(rootNode, "");
    }

    public void dump(DataNode root, String indent) {
        System.out.println(indent + " + " + root);
        for (Iterator<DataNode> i = root.iterator(); i.hasNext() ;) {
            DataNode node = i.next();
            dump(node, indent + "   ");
        }
    }

}
