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
import com.nokia.helium.metadata.model.metadata.Component;
import com.nokia.helium.metadata.model.metadata.LogFile;
import com.nokia.helium.metadata.model.metadata.MetadataEntry;
import com.nokia.helium.metadata.model.metadata.Severity;
import com.nokia.helium.metadata.model.metadata.SeverityDAO;

/**
 * This Type is to specify and use the ant logparser type to parse and store the data.
 *
 * <pre>
 * &lt;hlm:metadatafilterset id="ant.metadata.filter"&gt;
 *    &lt;metadatafilterset filterfile="${project.dir}/../data/common.csv" /&gt;
 * &lt;/hlm:metadatafilterset&gt;
 * 
 * &lt;hlm:antmetadatainput&gt;
 *    &lt;fileset dir="${project.dir}/../data/"&gt;
 *        &lt;include name="*zip*.log"/&gt;
 *    &lt;/fileset&gt;
 *    &lt;metadatafilterset refid="ant.metadata.filter" /&gt;
 * &lt;/hlm:antmetadatainput&gt;
 * </pre>
 * 
 * @ant.task name="antmetadatainput" category="Metadata"
 */
public class AntLogMetaDataInput extends AbstractComponentBaseMetadataInput {

    public static final String DEFAULT_COMPONENT = "Ant";
    private Pattern antTargetPattern = Pattern.compile("^([^\\s=\\[\\]]+):$");
    private EntityManager entityManager;
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void extract(EntityManagerFactory factory, File file)
        throws MetadataException {
        Component currentComponent = null;
        entityManager = factory.createEntityManager();
        AutoCommitEntityManager autoCommitEM = new AutoCommitEntityManager(factory);
        try {
            // Loading the available priorities
            SeverityDAO severityDao = new SeverityDAO();
            severityDao.setEntityManager(entityManager);
            Map<String, Severity> priorities = severityDao.getSeverities();

            // Creating the filename
            LogFile logFile = getLogFile(entityManager, file);

            // Parsing the log file
            BufferedReader reader = new BufferedReader(new FileReader(file));
            String logText = null;
            int lineNumber = 0;
            while ((logText = reader.readLine()) != null) {
                lineNumber++;
                String line = logText.replaceFirst("^[ ]*\\[.+?\\][ ]*", "");
                
                Matcher matcher = antTargetPattern.matcher(line);
                if (matcher.matches()) {
                    currentComponent = getComponent(matcher.group(1), logFile);
                } else {
                    if (currentComponent == null) {
                        currentComponent = getDefaultComponent(logFile);
                    }
                    SeverityEnum.Severity severity = getSeverity(line);
                    if (severity != SeverityEnum.Severity.NONE) {
                        MetadataEntry entry = new MetadataEntry();
                        entry.setLogFile(logFile);
                        entry.setLineNumber(lineNumber);
                        entry.setSeverity(autoCommitEM.merge(priorities.get(severity.toString())));
                        entry.setText(line);
                        entry.setComponent(autoCommitEM.merge(currentComponent));
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