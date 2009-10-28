/* 
============================================================================ 
Name        : BaselineModificationCache.java 
Part of     : Helium 

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.
This component and the accompanying materials are made available
under the terms of the License "Eclipse Public License v1.0"
which accompanies this distribution, and is available
at the URL "http://www.eclipse.org/legal/epl-v10.html".

Initial Contributors:
Nokia Corporation - initial contribution.

Contributors:

Description:

============================================================================
 */
package com.nokia.cruisecontrol.sourcecontrol;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import net.sourceforge.cruisecontrol.Modification;

/**
 * This helper class is a cache to store baseline changes, 
 * which are not timed based operations.
 *
 */
public class ModificationCache
{
    private List<Modification> cache = new ArrayList<Modification>();
    
    /**
     * Add a modification to the cache.
     * @param m the modification.
     */
    public synchronized void add(Modification m) {
        cache.add(m);
    }
    
    /**
     * Get the modification between the interval.
     * @param lastBuild
     * @param now
     * @return
     */
    public synchronized List<Modification> getModifications(Date lastBuild, Date now) {
        List<Modification> result = new ArrayList<Modification>();
        for (Modification m : cache) {
            if (m.modifiedTime.after(lastBuild) && m.modifiedTime.before(now)) {
                result.add(m);
            }
        }
        return result;
    }
    
    /**
     * Remove cleanup the cache, removes all stuff older than last build.
     * @param lastBuild
     */
    public synchronized void cleanup(Date lastBuild) {
        List<Modification> result = new ArrayList<Modification>();
        for (Modification m : cache) {
            if (m.modifiedTime.after(lastBuild)) {
                result.add(m);
            }
        }
        cache = result;
    }
}
