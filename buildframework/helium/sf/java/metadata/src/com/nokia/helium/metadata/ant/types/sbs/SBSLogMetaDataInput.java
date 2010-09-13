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

package com.nokia.helium.metadata.ant.types.sbs;

import java.io.File;
import java.io.IOException;
import java.util.Hashtable;
import java.util.Map;
import java.util.Map.Entry;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.SAXException;

import com.nokia.helium.metadata.AutoCommitEntityManager;
import com.nokia.helium.metadata.MetadataException;
import com.nokia.helium.metadata.ant.types.AbstractComponentBaseMetadataInput;
import com.nokia.helium.metadata.ant.types.SeverityEnum;
import com.nokia.helium.metadata.model.metadata.Component;
import com.nokia.helium.metadata.model.metadata.ComponentTime;
import com.nokia.helium.metadata.model.metadata.ExecutionTime;
import com.nokia.helium.metadata.model.metadata.LogFile;
import com.nokia.helium.metadata.model.metadata.MetadataEntry;
import com.nokia.helium.metadata.model.metadata.Severity;
import com.nokia.helium.metadata.model.metadata.SeverityDAO;
import com.nokia.helium.metadata.model.metadata.SysdefUnitDAO;
import com.nokia.helium.metadata.model.metadata.WhatLogEntry;


/**
 * This metadata input will parse SBSv2 log and collect
 * data into the database.
 * <pre>
 * 
 * &lt;hlm:sbsmetadatainput &gt
 *    &lt;fileset dir="${project.dir}/../data/"&gt;
 *        &lt;include name="*_compile.log"/&gt;
 *    &lt;/fileset&gt;
 *    &lt;hlm:metadatafilterset id="sbs.metadata.filter"&gt;
 *       &lt;metadatafilterset filterfile="common.csv" /&gt;
 *    &lt;/hlm:metadatafilterset&gt;
 * &lt;/hlm:sbsmetadatainput&gt;
 * </pre>
 * 
 * @ant.task name="sbsmetadatainput" category="Metadata"
 */
public class SBSLogMetaDataInput extends AbstractComponentBaseMetadataInput implements SBSLogEvents {
    private static final String  DEFAULT_COMPONENT_NAME = "general";
    private EntityManager entityManager;
    private AutoCommitEntityManager autoCommitEM;
    private LogFile logFile;
    private File epocroot;
    private SysdefUnitDAO unitDAO;
    private boolean checkMissing = true;

    private Map<String, Severity> priorities;
    private Pattern buildTimeMatcher = Pattern.compile("^Run time\\s+(\\d+)\\s+seconds$");
    private boolean failOnInvalidXml = true;
    private Map<String, ComponentTime> componentTimes = new Hashtable<String, ComponentTime>(); 

    /**
     * Defines if XML format error should be fatal, or treated as build error. 
     * @param failOnXmlError
     */
    public void setFailOnInvalidXml(boolean failOnInvalidXml) {
        this.failOnInvalidXml = failOnInvalidXml;
    }

    
    /**
     * Defines epocroot. 
     * @param epocroot
     * @ant.not-required Default to EPOCROOT.
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
    public File getEpocroot() {
        return epocroot;
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void extract(EntityManagerFactory factory, File file)
        throws MetadataException {
        SAXParserFactory saxFactory = SAXParserFactory.newInstance();
        entityManager = factory.createEntityManager();
        autoCommitEM = new AutoCommitEntityManager(factory);
        unitDAO = new SysdefUnitDAO();
        unitDAO.setEntityManager(this.getEntityManager());
        try {
            logFile = getLogFile(entityManager, file);

            SeverityDAO pdao = new SeverityDAO();
            pdao.setEntityManager(entityManager);
            priorities = pdao.getSeverities();
            
            // always create the default component and associated time.
            this.getDefaultComponent(logFile);
            this.addElapsedTime(this.getDefaultComponentName(), 0.0);
            
            SAXParser parser = saxFactory.newSAXParser();
            parser.parse(file, new SBSLogHandler(this, file));
            
            // Pushing component times into the database.
            entityManager.getTransaction().begin();
            for (Entry<String, ComponentTime> entry : componentTimes.entrySet()) {
                ComponentTime ct = entry.getValue();
                ct.setComponent(entityManager.merge(getComponent(entry.getKey(), logFile)));
                entityManager.persist(ct);
            }
            entityManager.getTransaction().commit();
        } catch (SAXException e) {
            if (failOnInvalidXml) {
                throw new MetadataException(e.getMessage(), e);
            }
        } catch (IOException e) {
            throw new MetadataException(e.getMessage(), e);
        } catch (ParserConfigurationException e) {
            throw new MetadataException(e.getMessage(), e);
        } finally {
            logFile = null;
            autoCommitEM.close();
            autoCommitEM = null;
            entityManager.close();
            entityManager = null;
            unitDAO = null;
            priorities = null;
            clear();
            componentTimes.clear();
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    protected EntityManager getEntityManager() {
        return entityManager;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void add(SeverityEnum.Severity severity,
            String text, int lineNumber) {
        add(severity, this.getDefaultComponentName(), text, lineNumber);
        
        // Searching for build time. 
        Matcher matcher = buildTimeMatcher.matcher(text);
        if (matcher.matches()) {
            ExecutionTime entry = new ExecutionTime();
            entry.setLogFile(autoCommitEM.merge(logFile));
            entry.setTime(new Integer(matcher.group(1)).intValue());
            autoCommitEM.persist(entry);
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void add(SeverityEnum.Severity severity,
            String component, String text, int lineNumber) {
        if (severity != SeverityEnum.Severity.INFO) {
            MetadataEntry entry = new MetadataEntry();
            entry.setComponent(autoCommitEM.merge(getComponent(component, logFile)));
            entry.setLineNumber(lineNumber);
            entry.setText(text);
            entry.setLogFile(logFile);
            entry.setSeverity(priorities.get(severity.toString()));
            autoCommitEM.persist(entry);
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void addWhatEntry(String component, String location, int lineNumber) {
        boolean fileExists = (new File(location)).exists();
        WhatLogEntry entry = new WhatLogEntry();
        entry.setComponent(autoCommitEM.merge(getComponent(component, logFile)));
        entry.setMember(location);
        entry.setMissing(!fileExists);
        autoCommitEM.persist(entry);
        if (checkMissing && !fileExists) {
            MetadataEntry mentry = new MetadataEntry();
            mentry.setComponent(autoCommitEM.merge(getComponent(component, logFile)));
            mentry.setLineNumber(lineNumber);
            mentry.setText("Missing: " + location);
            mentry.setLogFile(logFile);
            mentry.setSeverity(priorities.get(SeverityEnum.Severity.ERROR.toString()));
            autoCommitEM.persist(mentry);            
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public SeverityEnum.Severity check(String text, int lineNumber) {
        check(getDefaultComponentName(), text, lineNumber);
        return null;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public SeverityEnum.Severity check(
            String component, String text, int lineNumber) {
        SeverityEnum.Severity severity = this.getSeverity(text);
        if (severity != SeverityEnum.Severity.NONE) {
            MetadataEntry entry = new MetadataEntry();
            entry.setComponent(autoCommitEM.merge(getComponent(component, logFile)));
            entry.setLineNumber(lineNumber);
            entry.setText(text);
            entry.setLogFile(logFile);
            entry.setSeverity(priorities.get(severity.toString()));
            autoCommitEM.persist(entry);
        }
        return severity;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void declareComponent(String component) {
        getComponent(component, logFile);
    }

    /**
     * Define if we need to treat add error entries
     * for missing files.
     * @param checkMissing
     */
    public void setCheckMissing(boolean checkMissing) {
        this.checkMissing = checkMissing;
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public String getDefaultComponentName() {
        return DEFAULT_COMPONENT_NAME;
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    protected Component createComponent(String name, LogFile logFile) {
        Component component = new Component();
        component.setComponent(name);
        component.setLogFile(logFile);
        component.setSysdefUnit(unitDAO.getUnitByLocation(name));
        getEntityManager().getTransaction().begin();
        getEntityManager().persist(component);
        getEntityManager().getTransaction().commit();
        return component;
    }


    @Override
    public void addElapsedTime(String name, double duration) {
        if (!componentTimes.containsKey(name)) {
            ComponentTime ct = new ComponentTime();
            componentTimes.put(name, ct);
        }
        ComponentTime ct = componentTimes.get(name);
        ct.setDuration(ct.getDuration() + duration);
    }

}
