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
 * <code>Handler</code> is an interface which is used to handle the build events
 * which are of importance for ant logging and build stage summary display.
 * 
 *
 */
public interface TargetEventHandler {

   /**
     * Method to handle Target started Event
     * 
     * @param event
     */
    
    void handleTargetStarted( BuildEvent event );
  
   /**
    * Method to handle target finish events.
    * 
    * @param event is the build event to be handled. 
    */
    void handleTargetFinished( BuildEvent event );
   
}
