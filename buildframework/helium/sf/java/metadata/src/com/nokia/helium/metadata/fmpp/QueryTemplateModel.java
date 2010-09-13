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

import javax.persistence.EntityManager;

import freemarker.template.TemplateHashModel;
import freemarker.template.TemplateModel;

/**
 * Internal class to handle the sql query and returns the data in either
 * hash or sequence or containers.
 */
class QueryTemplateModel implements TemplateHashModel {

    private EntityManager entityManager;
    
    private String queryMode;
    
    private String returnType;
    
    private TemplateModel resultObject;
    
    public QueryTemplateModel(EntityManager entityManager, String mode, String retType) {
        this.entityManager = entityManager;
        queryMode = mode;
        returnType = retType;
    }

    public TemplateModel get(String query) {
        if (queryMode.equals("jpasingle")) {
            resultObject = new ORMSequenceModel(entityManager, query);
        } else {
            resultObject = new ORMQueryModel(entityManager, query, queryMode, returnType); 
        }
        return resultObject;
    }
    
    public boolean isEmpty() {
        return false;
    }
}
