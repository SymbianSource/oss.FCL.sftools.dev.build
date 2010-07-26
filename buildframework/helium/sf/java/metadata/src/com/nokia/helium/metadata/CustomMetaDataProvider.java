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

import com.nokia.helium.metadata.db.ORMMetadataDB;

/**
 * This interface is meant for a MetadataInput
 * to provides custom information other than
 * LogEntry to the database.
 */
public interface CustomMetaDataProvider {

    /**
     * This method is the entry point which allows
     * to push additional metadata via the ORMMetadataDB
     * instance. 
     */
    void provide(ORMMetadataDB db, String logPath);
    
}
