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
package com.nokia.helium.metadata.fmpp;

import java.io.File;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;

import org.apache.log4j.Logger;


import com.nokia.helium.metadata.FactoryManager;
import com.nokia.helium.metadata.MetadataException;

import fmpp.Engine;
import fmpp.ProgressListener;
import freemarker.template.TemplateHashModel;

/**
 * QueryModel (which supports hash, sequence, containers)
 * arg0: database location
 *  
 */
public class ORMQueryModeModel implements TemplateHashModel, ProgressListener {

    private static Logger log = Logger.getLogger(ORMQueryModeModel.class);
    private EntityManagerFactory factory;
    private EntityManager entityManager;

    public ORMQueryModeModel(File file) throws MetadataException {
        this.factory = FactoryManager.getFactoryManager().getEntityManagerFactory(file);
        this.entityManager = factory.createEntityManager();
    }
    
    /**
     * Gets the template model for the corresponding query
     * @param query for which the model is returned.
     * @return returns the template model for the query 
     */
    public TemplateHashModel get(String mode) {
        String retType = null;
        String actualMode = mode;
        if (mode.startsWith("native")) {
            String [] splitString = mode.split(":");
            if (splitString.length == 2 ) {
                actualMode = splitString[0]; 
                retType = splitString[1];
            }
        }
        
        return new QueryTemplateModel(entityManager, actualMode, retType);
    }
    
    /**
     * {@inheritDoc}
     */
    public boolean isEmpty() {
        return false;
    }

    /**
     * {@inheritDoc}
     */
    public void notifyProgressEvent(Engine engine, int event, File src,
            int pMode, Throwable error, Object param) throws Exception {
        log.debug("notifyProgressEvent - event: " + event);
        if (event == ProgressListener.EVENT_END_PROCESSING_SESSION) {
            log.debug("notifyProgressEvent - closing the factory.");
            this.entityManager.close();
            this.factory.close();
        }  
    }
}
