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

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.dom4j.Element;
import org.dom4j.Node;

/**
 * Meta object representing an Ant task.
 *
 */
public class TaskMeta extends AntObjectMeta {

    public TaskMeta(AntObjectMeta parent, Node node) {
        super(parent, node);
    }
    
    @SuppressWarnings("unchecked")
    public Map<String, String> getParams() {
        Map<String, String> params = new HashMap<String, String>();
        
        if (getNode().getNodeType() == Node.ELEMENT_NODE) {
            Element element = (Element)getNode();
            List<Element> paramNodes = element.elements("param");
            for (Element paramNode : paramNodes) {
                params.put(paramNode.attributeValue("name"), paramNode.attributeValue("value"));
            }
        }
        return params; 
    }
}
