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

import javax.persistence.EntityManagerFactory;

import org.apache.tools.ant.Task;

/**
 * Interface used by the MetadataRecordTask to extract information and
 * get them injected into the databased. 
 *
 */
public interface MetaDataInput {

    /**
     * This methods is run for each MetadataInput nested into the MetadataRecordTask
     * to extract data from log file for example. The factory is the entry point to
     * the database.
     * @param task an ant task running the plugging, mainly used to implement logging.
     * @param factory the factory representing the access to the database.
     * @throws MetadataException
     */
    void extract(Task task, EntityManagerFactory factory) throws MetadataException;
}
