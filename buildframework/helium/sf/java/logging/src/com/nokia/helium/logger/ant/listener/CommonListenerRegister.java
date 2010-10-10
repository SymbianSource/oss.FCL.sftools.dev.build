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

/**
 * This interface defines an Ant type to be 
 * able automatically registered by the CommonListener. 
 *
 */
public interface CommonListenerRegister {
 
    /**
     * This method is call by the CommonListener while discovering
     * reference implementing this interface.
     * 
     * @param commonListener the commonListener to register to.
     */
    void register(CommonListener commonListener);    
}
