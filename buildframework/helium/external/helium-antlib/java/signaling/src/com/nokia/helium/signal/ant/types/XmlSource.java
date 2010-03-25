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

 
package com.nokia.helium.signal.ant.types;


import java.io.File;

import com.nokia.helium.core.LogSource;

/**
 * This type define an input source that will be communicated to the notifiers.
 *
 * @ant.type name="xmlsource" category="Signaling"
 * 
 */
public class XmlSource extends LogSource {
    private File fileName;

    public File getFilename() {
        if (fileName.exists()) {
            return fileName;
        } else {
            return null;
        }
    }

    /**
     * The filename of the input source.
     * 
     * @ant.required
     */
    public void setFilename(File filename) {
        this.fileName = filename;
    }
}