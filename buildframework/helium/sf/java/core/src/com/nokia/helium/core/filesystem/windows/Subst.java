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
package com.nokia.helium.core.filesystem.windows;

import java.io.File;
import java.io.IOException;
import java.util.Map;

import com.nokia.helium.core.plexus.CommandBase;

/**
 * This class wrap up subst windows utility calls.
 *
 */
public class Subst extends CommandBase<IOException> {

    /**
     * Get the mapping between drive and the subst folder.
     * @return
     * @throws IOException
     */
    public Map<File, File> getSubstDrives() throws IOException {
        String[] args = new String[0];
        Subst subst = new Subst();
        SubstStreamConsumer consumer = new SubstStreamConsumer();
        subst.execute(args, consumer);
        return consumer.getSubstDrives();
    }

    /**
     * Tell if a path is under a subst drive.
     * @return
     * @throws IOException
     */
    public boolean isUnderSubstDrive(File filename) throws IOException {
        Map<File, File> substDrives = getSubstDrives();
        return substDrives.containsKey(new File(filename.getCanonicalPath().substring(0, 2)));
    }
    
    /**
     * Tell if a path is under a subst drive.
     * @return
     * @throws IOException
     */
    public File getRealPath(File filename) throws IOException {
        Map<File, File> substDrives = getSubstDrives();
        File drive = new File(filename.getAbsolutePath().substring(0, 2));
        if (substDrives.containsKey(drive)) {
            return new File(substDrives.get(drive), filename.getAbsolutePath().substring(3)).getAbsoluteFile();
        } else {
            return filename.getCanonicalFile();
        }
    }
    
    

    /**
     * {@inheritDoc}
     */
    @Override
    protected String getExecutable() {
        return "subst";
    }

    /**
     * {@inheritDoc}
     */
    @Override
    protected void throwException(String message, Throwable t) throws IOException {
        throw new IOException(message);
    }

}
