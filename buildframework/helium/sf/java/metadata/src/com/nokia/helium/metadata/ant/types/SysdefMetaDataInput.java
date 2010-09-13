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
package com.nokia.helium.metadata.ant.types;

import java.io.File;
import java.io.IOException;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.DataType;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import com.nokia.helium.metadata.MetaDataInput;
import com.nokia.helium.metadata.MetadataException;
import com.nokia.helium.metadata.model.metadata.SysdefCollection;
import com.nokia.helium.metadata.model.metadata.SysdefCollectionDAO;
import com.nokia.helium.metadata.model.metadata.SysdefComponent;
import com.nokia.helium.metadata.model.metadata.SysdefComponentDAO;
import com.nokia.helium.metadata.model.metadata.SysdefPackage;
import com.nokia.helium.metadata.model.metadata.SysdefPackageDAO;
import com.nokia.helium.metadata.model.metadata.SysdefUnit;
import com.nokia.helium.metadata.model.metadata.SysdefUnitDAO;

/**
 * The sysdefMetadataInput allows you to record a the current build
 * model in the database. Packages, collection, component and units
 * will be saved.
 *
 * @ant.type name="sysdefmetadatainput" category="Metadata"
 */
public class SysdefMetaDataInput extends DataType implements MetaDataInput {
    private File file;
    private File epocroot;
    
    @Override
    public void extract(Task task, EntityManagerFactory factory)
        throws MetadataException {
        if (file == null) {
            throw new MetadataException("file attribute is not defined.");
        }
        getEpocroot();
        SAXParserFactory saxFactory = SAXParserFactory.newInstance();
        SAXParser parser;
        EntityManager entityManager = factory.createEntityManager();
        try {
            task.log("Extracting data from " + file);
            parser = saxFactory.newSAXParser();
            parser.parse(file, new SysdefParserHandler(entityManager));
        } catch (ParserConfigurationException e) {
            throw new MetadataException(e.getMessage(), e);
        } catch (SAXException e) {
            throw new MetadataException(e.getMessage(), e);
        } catch (IOException e) {
            throw new MetadataException(e.getMessage(), e);
        } finally {
            entityManager.close();
        }
    }

    /**
     * Defines epocroot. 
     * @param epocroot
     * @ant.not=required Default to EPOCROOT.
     */
    public void setEpocroot(File epocroot) {
        this.epocroot = epocroot;
    }
    
    /**
     * Get epocroot.
     * @return a File object representing epocroot, or throw a BuildException
     *         if epocroot attribute and EPOCROOT environment variable
     *         are not defined.
     */
    protected File getEpocroot() {
        if (epocroot != null) {
            return epocroot;
        } else if (System.getenv("EPOCROOT") != null) {
            return (new File(System.getenv("EPOCROOT") )).getAbsoluteFile();
        }
        throw new BuildException("EPOCROOT environment variable or epocroot attribute is not defined.");
    }
    
    /**
     * Define the location of the system definition file.
     * @param file
     * @ant.required
     */
    public void setFile(File file) {
        this.file = file;
    }
    
    /**
     * Internal Handler to parse the sysdef file 
     * using the SAX interface. 
     *
     */
    class SysdefParserHandler extends DefaultHandler {

        private static final String PACKAGE_TAG = "package";
        private static final String COLLECTION_TAG = "collection";
        private static final String COMPONENT_TAG = "component";
        private static final String UNIT_TAG = "unit";
        private static final String ID_ATTR = "id";
        private static final String NAME_ATTR = "name";
        private static final String BLDFILE_ATTR = "bldFile";
        private SysdefPackage currentPackage;
        private SysdefCollection currentCollection;
        private SysdefComponent currentComponent;
        private EntityManager entityManager;
        private SysdefPackageDAO packageDAO;
        private SysdefCollectionDAO collectionDAO;
        private SysdefComponentDAO componentDAO;
        private SysdefUnitDAO unitDAO;
        
        public SysdefParserHandler(EntityManager entityManager) {
            this.entityManager = entityManager;
            packageDAO = new SysdefPackageDAO();
            packageDAO.setEntityManager(entityManager);
            collectionDAO = new SysdefCollectionDAO();
            collectionDAO.setEntityManager(entityManager);
            componentDAO = new SysdefComponentDAO();
            componentDAO.setEntityManager(entityManager);
            unitDAO = new SysdefUnitDAO();
            unitDAO.setEntityManager(entityManager);
        }

        /**
         * {@inheritDoc}
         */
        @Override
        public void startElement(String uri, String localName, String qName,
                Attributes attributes) throws SAXException {
            if (PACKAGE_TAG.equals(qName)) {
                currentPackage = packageDAO.getPackageById(attributes.getValue(ID_ATTR));
                if (currentPackage == null) {
                    entityManager.getTransaction().begin();
                    currentPackage = new SysdefPackage();
                    currentPackage.setPackageId(attributes.getValue(ID_ATTR));
                    currentPackage.setName(attributes.getValue(NAME_ATTR));
                    entityManager.persist(currentPackage);
                    entityManager.getTransaction().commit();
                }
            } else if (currentPackage != null && COLLECTION_TAG.equals(qName)) {
                currentCollection = collectionDAO.getCollectionById(attributes.getValue(ID_ATTR));
                if (currentCollection == null) {
                    entityManager.getTransaction().begin();
                    currentCollection = new SysdefCollection();
                    currentCollection.setCollectionId(attributes.getValue(ID_ATTR));
                    currentCollection.setName(attributes.getValue(NAME_ATTR));
                    currentCollection.setSysdefPackage(currentPackage);
                    entityManager.persist(currentCollection);
                    entityManager.getTransaction().commit();
                }
            } else if (currentCollection != null && COMPONENT_TAG.equals(qName)) {
                currentComponent = componentDAO.getComponentById(attributes.getValue(ID_ATTR));
                if (currentComponent == null) {
                    entityManager.getTransaction().begin();
                    currentComponent = new SysdefComponent();
                    currentComponent.setComponentId(attributes.getValue(ID_ATTR));
                    currentComponent.setName(attributes.getValue(NAME_ATTR));
                    currentComponent.setSysdefCollection(currentCollection);
                    entityManager.persist(currentComponent);
                    entityManager.getTransaction().commit();
                }
            } else if (currentComponent != null && UNIT_TAG.equals(qName) && attributes.getValue(BLDFILE_ATTR) != null) {
                SysdefUnit unit = unitDAO.getUnitByLocation(getEpocroot(), new File(attributes.getValue(BLDFILE_ATTR)));
                if (unit == null) {
                    entityManager.getTransaction().begin();
                    unit = new SysdefUnit();
                    // Location will be relative to epocroot.
                    unit.setLocation(getEpocroot().toURI().relativize((new File(attributes.getValue(BLDFILE_ATTR))).getAbsoluteFile().toURI()).getPath());
                    unit.setSysdefComponent(currentComponent);
                    entityManager.persist(unit);
                    entityManager.getTransaction().commit();
                }
            }
        }

        /**
         * {@inheritDoc}
         */
        @Override
        public void endElement(String uri, String localName, String qName)
            throws SAXException {
            super.endElement(uri, localName, qName);
            if (PACKAGE_TAG.equals(qName)) {
                currentPackage = null;
            } else if (COLLECTION_TAG.equals(qName)) {
                currentCollection = null;
            } else if (COMPONENT_TAG.equals(qName)) {
                currentComponent = null;
            }
        }
        
    }

}
