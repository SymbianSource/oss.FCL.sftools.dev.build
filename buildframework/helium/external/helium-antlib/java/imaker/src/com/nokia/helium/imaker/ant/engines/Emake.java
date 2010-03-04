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
package com.nokia.helium.imaker.ant.engines;

import java.io.File;

import com.nokia.helium.core.plexus.CommandBase;
import com.nokia.helium.imaker.IMakerException;

/**
 * Simple emake wrapper based on the CommandBase class.
 *
 */
public class Emake extends CommandBase<IMakerException> {

    private File workingDir = new File(".");
    
    /**
     * @return emake.
     */
    @Override
    protected String getExecutable() {
        return "emake";
    }

    /**
     * {@inheritDoc}
     */
    @Override
    protected void throwException(String message, Throwable t) throws IMakerException {
        throw new IMakerException(message, t);
    }

    /**
     * Set the working directory where emake should be called.
     * @param workingDir the working directory.
     */
    public void setWorkingDir(File workingDir) {
        this.workingDir = workingDir;
    }

    /**
     * Get the workingDir defined by the user.
     * @return the working dir.
     */
    @Override
    public File getWorkingDir() {
        return workingDir;
    }

}
