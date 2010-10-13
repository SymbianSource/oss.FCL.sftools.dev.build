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
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;

import org.apache.tools.ant.Project;

import com.nokia.helium.metadata.MetadataException;
import com.nokia.helium.metadata.model.metadata.Component;
import com.nokia.helium.metadata.model.metadata.LogFile;
import com.nokia.helium.metadata.model.metadata.MetadataEntry;
import com.nokia.helium.metadata.model.metadata.Severity;
import com.nokia.helium.metadata.model.metadata.SeverityDAO;


/**
 * This Type is to specify and use the abld logparser type to parse and store
 * the data.
 * 
 * <pre>
 * &lt;hlm:metadatafilterset id="abld.metadata.filter"&gt;
 *    &lt;metadatafilterset filterfile="common.csv" /&gt;
 * &lt;/hlm:metadatafilterset&gt;
 * 
 * &lt;hlm:imakermetadatainput&gt;
 *    &lt;fileset dir="${project.dir}/../data/"&gt;
 *        &lt;include name="*_compile*.log"/&gt;
 *    &lt;/fileset&gt;
 *    &lt;metadatafilterset refid="abld.metadata.filter" /&gt;
 * &lt;/hlm:imakermetadatainput&gt;
 * </pre>
 * 
 * @ant.task name="imakermetadatainput" category="Metadata"
 */
public class IMakerLogMetaDataInput extends AbstractComponentBaseMetadataInput {
    public static final String DEFAULT_COMPONENT_NAME = "General";
    private Pattern iMakerFpsxPattern = Pattern.compile("/([^/]*?\\.(?:fpsx|bin))");
    private EntityManager entityManager;

    /**
     * {@inheritDoc}
     */
    @Override
    public void extract(EntityManagerFactory factory, File file)
        throws MetadataException {
        entityManager = factory.createEntityManager();
        List<MetadataEntry> entries = new ArrayList<MetadataEntry>();
        String currentComponent = null;
        try {
            // Creating the filename
            LogFile logFile = getLogFile(entityManager, file);

            // Loading the available priorities
            SeverityDAO severityDao = new SeverityDAO();
            severityDao.setEntityManager(entityManager);
            Map<String, Severity> priorities = severityDao.getSeverities();
            
            // Parsing the log file
            BufferedReader reader = new BufferedReader(new FileReader(file));
            String line = null;
            int lineNumber = 0;
            while ((line = reader.readLine()) != null) {
                lineNumber++;
                Matcher matcher = iMakerFpsxPattern.matcher(line);
                if (matcher.find()) {
                    currentComponent = matcher.group(1);
                    log("Matched component: " + currentComponent, Project.MSG_DEBUG);
                }
                if (line.startsWith("++ Started at")) {
                    currentComponent = null;
                } else if (line.startsWith("++ Finished at")) {
                    if (currentComponent == null) {
                        currentComponent = DEFAULT_COMPONENT_NAME;
                    }
                    Component component = getComponent(currentComponent, logFile);
                    entityManager.getTransaction().begin();
                    for (MetadataEntry entry : entries) {
                        entry.setComponent(component);
                        entityManager.persist(entry);
                    }
                    entityManager.getTransaction().commit();
                    entityManager.clear();
                    entries.clear();
                } else {
                    SeverityEnum.Severity severity = getSeverity(line);
                    if (severity != SeverityEnum.Severity.NONE) {
                        MetadataEntry entry = new MetadataEntry();
                        entry.setLogFile(logFile);
                        entry.setLineNumber(lineNumber);
                        entry.setSeverity(priorities.get(severity.toString()));
                        entry.setText(line);
                        entries.add(entry);
                    }
                }
            }
            reader.close();
        } catch (FileNotFoundException ex) {
            throw new MetadataException(ex.getMessage(), ex);
        } catch (IOException ex) {
            throw new MetadataException(ex.getMessage(), ex);
        } finally {
            if (entityManager != null) {
                entityManager.close();
            }
            clear();
        }
        
    }

    /**
     * {@inheritDoc}
     */
    @Override
    protected EntityManager getEntityManager() {
        return entityManager;
    }

}
