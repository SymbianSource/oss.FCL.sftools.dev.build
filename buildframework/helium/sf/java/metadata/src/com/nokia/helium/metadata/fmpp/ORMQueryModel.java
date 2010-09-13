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

import freemarker.template.TemplateCollectionModel;
import freemarker.template.TemplateModelIterator;

class ORMQueryModel implements TemplateCollectionModel {

    private String queryType;
    private String queryString;
    private String returnType;
    private EntityManager entityManager;

    public ORMQueryModel(EntityManager entityManager, String queryString,
            String type, String retType) {
        this.entityManager = entityManager;
        queryType = type;
        this.queryString = queryString;
        returnType = retType;
    }

    /*
     * Provides data via collection interface.
     * 
     * @return the iterator model from which the data is accessed.
     */
    public TemplateModelIterator iterator() {
        return new ORMTemplateModelIterator(entityManager, queryString,
                queryType, returnType);
    }

}
