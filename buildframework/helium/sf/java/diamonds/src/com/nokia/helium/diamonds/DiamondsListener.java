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

package com.nokia.helium.diamonds;

import org.apache.tools.ant.BuildEvent;

import com.nokia.helium.diamonds.ant.Listener;

/**
 * Diamonds specific Listener interface.
 * 
 */
public interface DiamondsListener {
    
    void configure(Listener listener) throws DiamondsException;
    
    /**
     * Function to process logging info during beginning of target execution
     * 
     * @param event
     *            of target execution.
     */
    void targetStarted(BuildEvent buildEvent) throws DiamondsException;

    /**
     * Function to process logging info during end of target execution
     * 
     * @param event
     *            of target execution.
     */
    void targetFinished(BuildEvent buildEvent) throws DiamondsException;

    /**
     * Function to process logging info during beginning of build
     * 
     * @param event
     *            of target execution.
     */
    void buildStarted(BuildEvent buildEvent) throws DiamondsException;

    /**
     * Function to process logging info during end of build
     * 
     * @param event
     *            of target execution.
     */
    void buildFinished(BuildEvent buildEvent) throws DiamondsException;
}