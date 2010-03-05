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


package com.nokia.helium.scm.ant.types;

import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.types.DataType;

/**
 * This tagSet type is a container of tag elements.
 * 
 * Example:
 *  <pre>
 *  &lt;tagSet&gt;
 *      &lt;tag name="release_1.0" /&gt;
 *      &lt;tag name="release_1.0.1" /&gt;
 *  &lt;7tagSet&gt;
 *  </pre>
 *  
 * @ant.type name="tagSet" category="SCM"
 */
public class TagSet extends DataType {

    private List<Tag> tags = new ArrayList<Tag>();
    
    /**
     * Add a Tag element.
     * @param tag
     */
    public void add(Tag tag) {
        tags.add(tag);
    }
    
    /**
     * Create and add a Taf element.
     * @return the newly created Tag.
     */
    public Tag createTag() {
        Tag tag = new Tag();
        tags.add(tag);
        return tag;
    }

    /**
     * Get the list of tags.
     * @return the list of stored tag elements.
     */
    public List<Tag> getTags() {
        return new ArrayList<Tag>(tags);
    }
    
}
