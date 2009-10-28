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


package com.nokia.helium.core;

/**
 * Implements the source name handling.
 */
public abstract class AbstractTemplateInputSource implements
        TemplateInputSource {

    private String sourceName;
    /**
     * Get template source name.
     * @return
     *      template source name.
     */
    public String getSourceName() {
        return sourceName;
    }
    /**
     * Add template source name
     * @param String 
     *          template source name     
     */
    public void setSourceName(String souceName) {
        this.sourceName = souceName;
    }

}
