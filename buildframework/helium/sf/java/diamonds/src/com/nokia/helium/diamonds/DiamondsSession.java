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
 * Description: To update the build status to Diamonds with signals in case of build exceptions.
 *
 */
package com.nokia.helium.diamonds;

import com.nokia.helium.core.ant.Message;

/**
 * Defines the interface needed to communicated with Diamonds. 
 *
 */
public interface DiamondsSession {

    /**
     * Open the session, using custom message.
     * @param message
     * @throws DiamondsException if the opening failed.
     */
    void open(Message message) throws DiamondsException;
    
    /**
     * Close the session using a custom message. 
     * @param message
     * @throws DiamondsException if the session is not opened
     */
    void close(Message message) throws DiamondsException;
    
    /**
     * Sending a custom message.
     * 
     * @param message
     * @throws DiamondsException if the session is not opened
     */
    void send(Message message) throws DiamondsException;
    
    /**
     * Returns true if the session to diamonds has been opened successfully. 
     * @return 
     */
    boolean isOpen();
  
    /**
     * Returns the build id as a string, or null if session is not yet
     * open, or opening failed.  
     * @return the build id.
     */
    String getBuildId();
}
