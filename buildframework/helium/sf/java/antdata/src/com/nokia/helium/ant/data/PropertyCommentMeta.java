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

import org.dom4j.Comment;

/**
 * Meta object for a property that is defined entirely by a comment.
 */
public class PropertyCommentMeta extends CommentMeta {

    /**
     * Constructor.
     * 
     * @param parent The parent meta object.
     * @param propertyNode XML node representing the comment.
     * @throws IOException
     */
    public PropertyCommentMeta(AntObjectMeta parent, Comment comment) throws IOException {
        super(parent, comment);
    }

    /**
     * Returns the property name as it is defined at the top of the comment
     * block for that property.
     */
    public String getName() {
        return getComment().getObjectName();
    }

    /**
     * There is no default value for properties defined only by comments.
     */
    public String getDefaultValue() {
        return "";
    }

    public String getType() {
        return getComment().getTagValue("type", PropertyMeta.DEFAULT_TYPE);
    }

    public String getEditable() {
        return getComment().getTagValue("editable", PropertyMeta.DEFAULT_EDITABLE);
    }
}
