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

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;

import com.nokia.helium.metadata.AutoCommitEntityManager;
import com.nokia.helium.metadata.MetadataException;
import com.nokia.helium.metadata.model.metadata.LogFile;
import com.nokia.helium.metadata.model.metadata.MetadataEntry;
import com.nokia.helium.metadata.model.metadata.Severity;
import com.nokia.helium.metadata.model.metadata.SeverityDAO;

/**
 * This Type is to specify and use the abld logparser type to parse and store
 * the data.
 * 
 * <pre>
 * &lt;hlm:metadatafilterset id=&quot;abld.metadata.filter&quot;&gt;
 *    &lt;metadatafilterset filterfile=&quot;common.csv&quot; /&gt;
 * &lt;/hlm:metadatafilterset&gt;
 * 
 * &lt;hlm:abldmetadatainput&gt;
 *    &lt;fileset dir=&quot;${project.dir}/../data/&quot;&gt;
 *        &lt;include name=&quot;*_compile*.log&quot;/&gt;
 *    &lt;/fileset&gt;
 *    &lt;metadatafilterset refid=&quot;abld.metadata.filter&quot; /&gt;
 * &lt;/hlm:antmetadatainput&gt;
 * </pre>
 * 
 * @ant.task name="abldmetadatainput" category="Metadata"
 */
public class AbldLogMetaDataInput extends AbstractComponentBaseMetadataInput {

    public static final String DEFAULT_COMPONENT = "General";
    private Pattern abldFinishedPattern = Pattern
            .compile("^===\\s+.+\\s+finished.*");
    private Pattern abldStartedPattern = Pattern
            .compile("^===\\s+(.+)\\s+started.*");
    private Pattern abldComponentPattern = Pattern
            .compile("^===\\s+(.+?)\\s+==\\s+(.+)");

    private String currentComponent = DEFAULT_COMPONENT;
    private EntityManager entityManager;
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void extract(EntityManagerFactory factory, File file)
        throws MetadataException {
        entityManager = factory.createEntityManager();
        AutoCommitEntityManager autoCommitEM = new AutoCommitEntityManager(factory);
        try {
            // Creating the filename
            LogFile logFile = getLogFile(entityManager, file);

            // Always defines the default component
            this.getDefaultComponent(logFile);

            // Loading the available priorities
            SeverityDAO severityDao = new SeverityDAO();
            severityDao.setEntityManager(entityManager);
            Map<String, Severity> priorities = severityDao.getSeverities();

            
            // Parsing the log file
            BufferedReader reader = new BufferedReader(new FileReader(file));
            String logText = null;
            int lineNumber = 0;
            while ((logText = reader.readLine()) != null) {
                lineNumber++;
                String line = logText.replaceFirst("^[ ]*\\[.+?\\][ ]*", "");

                if (line.startsWith("=== ")) {
                    Matcher matcher = abldComponentPattern.matcher(line);
                    if (matcher.matches()) {
                        currentComponent = matcher.group(2);
                        getComponent(currentComponent, logFile); // declare the component...
                    } else {
                        matcher = abldStartedPattern.matcher(line);
                        if (matcher.matches()) {
                            currentComponent = DEFAULT_COMPONENT;
                        } else {
                            matcher = abldFinishedPattern.matcher(line);
                            if (matcher.matches()) {
                                currentComponent = DEFAULT_COMPONENT;
                            }
                        }
                    }
                } else {
                    SeverityEnum.Severity severity = getSeverity(line);
                    if (severity != SeverityEnum.Severity.NONE) {
                        MetadataEntry entry = new MetadataEntry();
                        entry.setLogFile(autoCommitEM.merge(logFile));
                        entry.setLineNumber(lineNumber);
                        entry.setSeverity(autoCommitEM.merge(priorities.get(severity.toString())));
                        entry.setText(line);
                        entry.setComponent(autoCommitEM.merge(getComponent(currentComponent, logFile)));
                        autoCommitEM.persist(entry);
                    }
                }
            }
            reader.close();
        } catch (FileNotFoundException ex) {
            throw new MetadataException(ex.getMessage(), ex);
        } catch (IOException ex) {
            throw new MetadataException(ex.getMessage(), ex);
        } finally {
            if (autoCommitEM != null) {
                autoCommitEM.close();
            }
            if (entityManager != null) {
                if (entityManager.getTransaction().isActive()) {
                    entityManager.getTransaction().rollback();
                }
                entityManager.close();
                entityManager = null;
            }
        }
        clear();
    }

    @Override
    protected EntityManager getEntityManager() {
        return entityManager;
    }
    
    @Override
    protected String getDefaultComponentName() {
        return DEFAULT_COMPONENT;
    }

}