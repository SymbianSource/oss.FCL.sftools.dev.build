
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

package com.nokia.helium.jpa;

import org.apache.log4j.Logger;
import javax.persistence.EntityManager;

/**
 * This class is used to keep track of number of objects
 * remaining to be commited to the database.
 */
public class ORMCommitCount {

    private static Logger log = Logger.getLogger(ORMCommitCount.class);

    private static final int PERSISTANCE_COUNT_LIMIT = 1000;

    private static EntityManager entityManager;

    private int count;

    /** Constructor.
     */
    public ORMCommitCount() {
        count = PERSISTANCE_COUNT_LIMIT;
    }

    /**
     * Reduce the commit count value by one.
     */
    public void decreaseCount() {
        count --;
    }

    /**
     * Reset to maximum limit
     */
    public void reset() {
        count = PERSISTANCE_COUNT_LIMIT;
    }

    /**
     * Returns whether the commit is required or not.
     * @return if commit required returns true otherwise false.
     */
    public boolean isCommitRequired() {
        return count == 0;
    }

    /**
     * Returns whether if there are any data to commit
     * @return true if any data there to commit, otherwise false.
     */
    public boolean isDatatoCommit() {
        //log.debug("isDatatoCommit: " + (count < PERSISTANCE_COUNT_LIMIT));
        return count < PERSISTANCE_COUNT_LIMIT;
    }
}