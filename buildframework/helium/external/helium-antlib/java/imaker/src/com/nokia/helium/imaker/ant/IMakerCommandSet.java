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

import com.nokia.helium.imaker.IMaker;

/**
 * This interface describes the API a configuration object should define.   
 *
 */
public interface IMakerCommandSet {

    /**
     * Returns a list of command List.
     * The sublist will be build sequentially. Their content can be built
     * in parallel.
     * @return a list of Command list
     */
    List<List<Command>> getCommands(IMaker imaker);

}
