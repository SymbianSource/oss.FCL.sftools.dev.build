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
package com.nokia.helium.logger.ant.listener;

import org.apache.tools.ant.BuildEvent;

/**
 * This interface defines the methods called
 * while Ant message are logged.
 *
 */
public interface MessageEventHandler {
    
    /**
     * Method to handle SubBuild Started  events.
     * @param event
     */
    void handleMessageLogged( BuildEvent event );

}
