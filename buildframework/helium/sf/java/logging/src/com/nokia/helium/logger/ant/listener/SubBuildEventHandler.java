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
 * <code>SubBuildEventHandler</code> is an interface which is used to handle
 * the sub-build events which are of importance for ant logging and build
 * stage summary display.
 *
 */
public interface SubBuildEventHandler {

    /**
     * Method to handle SubBuild Started  events.
     * @param event
     */
    void handleSubBuildStarted( BuildEvent event );
    
    /**
     * Method to handle SubBuild Finished  events.
     * @param event
     */
    void handleSubBuildFinished( BuildEvent event );
    
}
