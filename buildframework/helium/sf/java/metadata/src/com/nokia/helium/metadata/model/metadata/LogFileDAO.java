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

import java.io.File;
import java.util.List;

import javax.persistence.NoResultException;

import com.nokia.helium.metadata.JpaDAO;

/**
 * Implements DAO for the LogFile.
 * Contains all helpers related to LogFile manipulation.
 *
 */
public class LogFileDAO extends JpaDAO<LogFile> {
    
    /**
     * Get a logfile instance by file name.
     * @param logfile
     * @return
     */
    public LogFile findByLogName(File logfile) {
        LogFile result = null;
        try {
            List<LogFile> resultList = this.getEntityManager().createQuery("select l from LogFile l where l.path='" +
                logfile.getAbsolutePath().replace('\\', '/') + "'", LogFile.class).getResultList();
            if (resultList.size() > 0) {
                result = resultList.get(0);
            }
        } catch (NoResultException ex) {
            result = null;
        }
        return result;
    }
    
}
