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
package com.nokia.helium.metadata.model.metadata;

import java.util.Hashtable;
import java.util.Map;

import com.nokia.helium.metadata.JpaDAO;

/**
 * Implements DAO for the Severity.
 * Contains all helpers related to Severity manipulation.
 *
 */
public class SeverityDAO extends JpaDAO<Severity> {

    public Map<String, Severity> getSeverities() {
        Map<String, Severity> result = new Hashtable<String, Severity>();
        for (Severity severity : this.getEntityManager().createQuery("SELECT s from Severity s", Severity.class).getResultList()) {
            result.put(severity.getSeverity(), severity);
        }
        return result;
    }
    
}
