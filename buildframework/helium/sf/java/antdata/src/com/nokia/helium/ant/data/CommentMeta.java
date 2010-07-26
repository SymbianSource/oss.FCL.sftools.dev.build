/*
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
 * Meta object for an XML comment that defines data about an Ant object.
 */
public class CommentMeta extends AntObjectMeta {

    public CommentMeta(AntObjectMeta parent, Comment comment) throws IOException {
        super(parent, comment);
    }

    public String getName() {
        return getComment().getObjectName();
    }
}
