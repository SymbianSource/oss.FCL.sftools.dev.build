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
package com.nokia.helium.metadata.tests;


import java.io.File;
import java.io.IOException;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;

import org.apache.commons.io.FileUtils;
import org.apache.log4j.Logger;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import com.nokia.helium.metadata.FactoryManager;
import com.nokia.helium.metadata.MetadataException;
import com.nokia.helium.metadata.fmpp.ORMQueryModeModel;
import com.nokia.helium.metadata.model.metadata.LogFile;

import fmpp.ProgressListener;
import freemarker.ext.beans.BeanModel;
import freemarker.template.SimpleScalar;
import freemarker.template.TemplateCollectionModel;
import freemarker.template.TemplateHashModel;
import freemarker.template.TemplateModel;
import freemarker.template.TemplateModelIterator;
import freemarker.template.TemplateSequenceModel;

/**
 * Testing the ORMFMPPLoader loader. 
 * 
 */
public class TestORMFMPPLoader {
    private File database;
    private static Logger log = Logger.getLogger(TestORMFMPPLoader.class);
    
    /**
     * Populates the LogFile table with basic data.
     * @throws MetadataException
     * @throws IOException
     */
    @Before
    public void populateDatabase() throws MetadataException, IOException {
        File tempdir = new File(System.getProperty("test.temp.dir"));
        tempdir.mkdirs();
        database = new File(tempdir, "test_db");
        if (database.exists()) {
            FileUtils.forceDelete(database);
        }
        EntityManagerFactory factory = FactoryManager.getFactoryManager().getEntityManagerFactory(database);
        EntityManager em = factory.createEntityManager();
        try {
            em.getTransaction().begin();
            for (int i = 0 ; i < 2000 ; i++) {
                LogFile lf = new LogFile();
                lf.setPath("log" + String.format("%04d", i));
                em.persist(lf);
            }
        } finally {
            if (em.getTransaction().isActive()) {
                em.getTransaction().commit();
            }
            em.close();
            factory.close();
        }
    }

    /**
     * Delete the database after test completion.
     * @throws IOException
     */
    @After
    public void cleanupDatabase() throws IOException {
        FileUtils.forceDelete(database);
    }
    
    /**
     * Run a JPA query.
     * @throws Exception
     */
    @Test
    public void testJpaSingleQuery() throws Exception {
        ORMQueryModeModel modeModel = new ORMQueryModeModel(database);
        try {
            TemplateHashModel model = modeModel.get("jpasingle");
            TemplateModel data = model.get("select l from LogFile l order by l.path");
            Assert.assertTrue(data instanceof TemplateSequenceModel);
            TemplateSequenceModel seq = (TemplateSequenceModel)data;
            Assert.assertTrue(seq.size() == 2000);

            // Let's make sure we get null if out of bounds
            Assert.assertNotNull(seq.get(0));
            Assert.assertNotNull(seq.get(750));
            Assert.assertNotNull(seq.get(749));
            Assert.assertNotNull(seq.get(1999));
            Assert.assertNotNull(seq.get(0));
            Assert.assertNull(seq.get(2000));
            Assert.assertNull(seq.get(2001));
            Assert.assertNull(seq.get(2000));
        
            // Check index 0
            LogFile lf = (LogFile)((BeanModel)seq.get(0)).getWrappedObject();
            log.info("seq.get(0): " + lf.getPath());
            Assert.assertTrue("log0000".equals(lf.getPath()));
        
            // Check index 999
            lf = (LogFile)((BeanModel)seq.get(999)).getWrappedObject();
            log.info("seq.get(999): " + lf.getPath());
            Assert.assertTrue("log0999".equals(lf.getPath()));

            // Check index 1999
            lf = (LogFile)((BeanModel)seq.get(1999)).getWrappedObject();
            log.info("seq.get(1999): " + lf.getPath());
            Assert.assertTrue("log1999".equals(lf.getPath()));
        } finally {
            modeModel.notifyProgressEvent(null, ProgressListener.EVENT_END_PROCESSING_SESSION, null, 0, null, null);
        }
    }

    /**
     * Run a native query.
     * @throws Exception
     */
    @Test
    public void testNativeStringQuery() throws Exception {
        ORMQueryModeModel modeModel = new ORMQueryModeModel(database);
        try {
            TemplateHashModel model = modeModel.get("native:java.lang.String");
            TemplateModel data = model.get("select l.path from LogFile l order by l.path");
            Assert.assertTrue(data instanceof TemplateCollectionModel);
            TemplateCollectionModel collection = (TemplateCollectionModel)data;
            TemplateModelIterator iterator = collection.iterator();
            
            int i = 0;
            while (iterator.hasNext()) {
                TemplateModel next = iterator.next();
                SimpleScalar scalar = (SimpleScalar)next;
                Assert.assertTrue(scalar.getAsString().equals("log" + String.format("%04d", i++)));
            }
            Assert.assertFalse(iterator.hasNext());
            Assert.assertNull(iterator.next());
        } finally {
            modeModel.notifyProgressEvent(null, ProgressListener.EVENT_END_PROCESSING_SESSION, null, 0, null, null);
        }
    }
}
