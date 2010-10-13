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

import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.Path;

/**
 * This Ant type allows you to provide a list of files, for
 * example logs to a notifier. The usage of this type is 
 * deprecated, please consider using any kind of Ant 
 * ResourceCollection like paths or filesets.
 * 
 * @ant.type name="NotifierInput" category="Signaling"
 */
public class NotifierInput extends Path {

    public NotifierInput(Project project) {
        super(project);
    }

    /**
     * Helper function called by ant to set the input file.
     * @param inputFile input file for notifier
     * @ant.not-required
     */
    public void setFile(File file) {
        this.createPathElement().setLocation(file);
    }
}