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
package com.nokia.helium.blocks;

import java.io.File;

import com.nokia.helium.core.plexus.CommandBase;

/**
 * Wrapper class for the bundle application. The bundle application will help to do simple
 * operations on bundles, like creating repository index or sign a bundle.
 * 
 */
public class Bundle extends CommandBase<BundleException> {

    /**
     * {@inheritDoc}
     */
    @Override
    protected String getExecutable() {
        return "bundle";
    }

    /**
     * {@inheritDoc}
     */
    @Override
    protected void throwException(String message, Throwable t) throws BundleException {
        throw new BundleException(message, t);
    }

    /**
     * Create a repository index base on a directory.
     * 
     * @param path the directory which contains the debs packages.
     * @throws BundleException in case of error.
     */
    public void createRepositoryIndex(File path) throws BundleException {
        createRepositoryIndex(path, false);
    }

    /**
     * Create a signed repository index base on a directory.
     * 
     * @param path the directory which contains the debs packages.
     * @param sign defines if the repository should be signed.
     * @throws BundleException in case of error.
     */
    public void createRepositoryIndex(File path, boolean sign) throws BundleException {
        if (path == null) {
            throw new BundleException("Impossible to create the index, no directory specified.");
        }
        if (!path.isDirectory()) {
            throw new BundleException("Invalid directory: " + path.getAbsolutePath());
        }
        String[] args = null;
        if (sign) {
            args = new String[3];
            args[0] = "create-repo";
            args[1] = "--sign";
            args[2] = path.getAbsolutePath();
        }
        else {
            args = new String[2];
            args[0] = "create-repo";
            args[1] = path.getAbsolutePath();
        }
        this.execute(args);
    }
}
