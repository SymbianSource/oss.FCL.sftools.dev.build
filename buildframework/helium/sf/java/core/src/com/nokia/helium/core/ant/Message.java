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

 
package com.nokia.helium.core.ant;

import java.io.InputStream;
import com.nokia.helium.core.MessageCreationException;

/**
 * Interface describing the method a Message must implements.
 *
 */
public interface Message {

    /**
     * Get an InputStream on the serialize the message
     * @return an InputStream
     * @throws MessageCreationException happens in case of serialization error.
     */
    InputStream getInputStream() throws MessageCreationException;
}