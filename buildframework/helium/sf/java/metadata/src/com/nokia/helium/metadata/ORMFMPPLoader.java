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
package com.nokia.helium.metadata;

import java.io.File;
import java.util.List;

import com.nokia.helium.metadata.fmpp.ORMQueryModeModel;

import fmpp.Engine;
import fmpp.tdd.DataLoader;


/**
 * Utility class to access the data from the database and used by FMPP templates.
 */
public class ORMFMPPLoader implements DataLoader {
    //private ResultSet rs;

    /**
     * Return a object abstracting the access to a database.
     * @see fmpp.tdd.DataLoader#load(fmpp.Engine, java.util.List)
     */
    @SuppressWarnings("unchecked")
    public Object load(Engine engine, List args) throws Exception {
        //log.debug("args.size:" + args.size());
        if (args.size() < 1) {
            throw new MetadataException("The database path should be provided to load into FMPP.");
        }
        ORMQueryModeModel model = new ORMQueryModeModel(new File((String)args.get(0)));
        engine.setAttribute(this.getClass().toString(), model);
        return model;
    }
}