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
package com.nokia.helium.imaker.ant;

import java.util.List;

import com.nokia.helium.imaker.IMakerException;
import com.nokia.helium.imaker.ant.taskdefs.IMakerTask;

/**
 * Engine interface. Methods needed by the IMaker task to
 * build the roms. 
 *
 */
public interface Engine {
    
    /**
     * Set the current IMakerTask.
     * @param task the task instance.
     */
    void setTask(IMakerTask task);

    /**
     * Build the Commands.
     * The sublist will be build in a serialize way,
     * the content of each sublist will be built in parallel.
     * @param cmdSet
     * @throws IMakerException
     */
    void build(List<List<Command>> cmdSet) throws IMakerException;
}
