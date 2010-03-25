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
 
package com.nokia.ant.types.ccm;

import org.apache.tools.ant.types.DataType;
import java.util.Vector;

/**
 * This class implement an Ant Datatype that represents a set of
 * synergy sessions.
 * @ant.type name="sessionset" category="SCM"
 */
public class SessionSet extends DataType {
    private Vector sessions = new Vector();
    
    /**
     * Create and register a Session object. 
     * @return a Session object.
     */
    public Session createSession() {
        Session session = new Session();
        sessions.add(session);
        return session;
    }
    
    /**
     * Returns an array of Session object.
     * @returns an array of Session object
     */
    public Session[] getSessions() {
        Session[] result = new Session[sessions.size()];
        sessions.copyInto(result);
        return result; 
    }
}

