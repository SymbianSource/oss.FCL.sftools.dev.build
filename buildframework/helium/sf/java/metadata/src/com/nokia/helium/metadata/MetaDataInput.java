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

package com.nokia.helium.metadata;

import java.util.Iterator;
import com.nokia.helium.jpa.entity.metadata.Metadata;



/**
 * Interface to add any plugins to write the database. Two ways to get
 * the data, either the entire data could written by calling getEntries() method
 * or using Iterator for large amount of entries to be written to the database. 
 */
public interface MetaDataInput {
    
    /**
     * 
     *  @param fileSet fileset to be added
     * 
     */
    Iterator<Metadata.LogEntry> iterator();
    
}