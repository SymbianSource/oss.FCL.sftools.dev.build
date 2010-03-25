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

import org.dom4j.Element;

/**
 * An Ant type such as a fileset, resource collection, mapper, etc.
 */
public class TypeMeta extends AntObjectMeta {

    public TypeMeta(AntObjectMeta parent, Element node) throws IOException {
        super(parent, node);
    }

    public String getId() {
        return getAttr("id");
    }
}
