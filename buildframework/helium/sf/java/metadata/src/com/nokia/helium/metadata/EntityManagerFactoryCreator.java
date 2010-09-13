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

import javax.persistence.EntityManagerFactory;

/**
 * This interface describe the methods used to creates
 * EntityManagerFactory for a particular database type (e.g.: Derby).
 *
 */
public interface EntityManagerFactoryCreator {

    /**
     * This method will be called once in the lifecycle of the EntityManagerFactoryCreator
     * object.
     * This method is a kind of entry point to load a driver for example.
     * @throws MetadataException this exception is thrown in case of error.
     */
    void initialize() throws MetadataException ;

    /**
     * Create a new EntityManagerFactory for a particular database.
     * @param database the database to create the EntityManagerFactory for.
     * @return a new EntityManagerFactory.
     * @throws MetadataException this exception is raised in case of error. (e.g database could not be created.)
     */
    EntityManagerFactory create(File database) throws MetadataException;
    
    /**
     * This method is called to unload a database, this is called usually when
     * all created EntityManagerFactory are freed.
     * @param database the database to unload.
     * @throws MetadataException
     */
    void unload(File database) throws MetadataException ;
}
