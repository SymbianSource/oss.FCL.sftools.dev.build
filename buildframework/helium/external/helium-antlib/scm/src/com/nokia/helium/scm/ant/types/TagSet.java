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

public class TagSet extends DataType {

    private List<Tag> tags = new ArrayList<Tag>();
    
    public void add(Tag tag) {
        tags.add(tag);
    }
    
    public Tag createTag() {
        Tag tag = new Tag();
        tags.add(tag);
        return tag;
    }
    
    public List<Tag> getTags() {
        return new ArrayList<Tag>(tags);
    }
    
}
