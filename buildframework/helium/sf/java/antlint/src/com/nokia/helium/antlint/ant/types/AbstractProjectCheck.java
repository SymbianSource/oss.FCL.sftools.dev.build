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
package com.nokia.helium.antlint.ant.types;

import com.nokia.helium.ant.data.RootAntObjectMeta;
import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>AbstractProjectCheck</code> is an abstract check class used to run
 * against a {@link ProjectMeta} or an {@link AntlibMeta}.
 * 
 */
public abstract class AbstractProjectCheck extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run() throws AntlintException {
        RootAntObjectMeta rootObjectMeta = getAntFile().getRootObjectMeta();
        run(rootObjectMeta);
        
    }

    /**
     * Method runs the check against the given {@link RootAntObjectMeta}.
     * 
     * @param root is the {@link RootAntObjectMeta} against which the check is
     *            run.
     */
    protected abstract void run(RootAntObjectMeta root);

}
