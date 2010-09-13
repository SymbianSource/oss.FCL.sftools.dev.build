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

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;

import com.nokia.helium.metadata.AutoCommitEntityManager;
import com.nokia.helium.metadata.MetadataException;
import com.nokia.helium.metadata.model.metadata.LogFile;
import com.nokia.helium.metadata.model.metadata.MetadataEntry;
import com.nokia.helium.metadata.model.metadata.Severity;
import com.nokia.helium.metadata.model.metadata.SeverityDAO;

/**
 * This Type is to specify and use the text logparser type to parse and store the data.
 *
 * <pre>
 * &lt;hlm:metadatafilterset id="text_log_metadata_input"&gt;
 *    &lt;metadatafilterset filterfile="${project.dir}/../data/common.csv" /&gt;
 * &lt;/hlm:metadatafilterset&gt;
 * 
 * &lt;hlm:textmetadatainput&gt;
 *    &lt;fileset dir="${project.dir}/../data/"&gt;
 *        &lt;include name="*_fixslashes*.log"/&gt;
 *    &lt;/fileset&gt;
 *    &lt;metadatafilterset refid="text_log_metadata_input" /&gt;
 * &lt;/hlm:textmetadatainput&gt;
 * </pre>
 * 
 * @ant.task name="textmetadatainput" category="Metadata"
 */
public class TextLogMetaDataInput extends LogMetaDataInput {

    /**
     * {@inheritDoc}
     */
    @Override
    public void extract(EntityManagerFactory factory, File file) throws MetadataException {
        EntityManager em = factory.createEntityManager();
        AutoCommitEntityManager autoCommitEM = new AutoCommitEntityManager(factory);
        try {
            // Get the severities
            SeverityDAO severityDao = new SeverityDAO();
            severityDao.setEntityManager(em);
            Map<String, Severity> priorities = severityDao.getSeverities();
            
            // Add a logfile entry into the database.
            LogFile logFile = getLogFile(em, file);

            // Start parsing
            BufferedReader reader = new BufferedReader(new FileReader(file));
            String logText = null;
            int lineNumber = 0;
            while ((logText = reader.readLine()) != null) {
                lineNumber++;                    
                String line = logText.replaceFirst("^\\s*\\[.+?\\]\\s*", "");
                SeverityEnum.Severity severity = getSeverity(line);
                if (severity != SeverityEnum.Severity.NONE) {
                    MetadataEntry entry = new MetadataEntry();
                    entry.setLogFile(autoCommitEM.merge(logFile));
                    entry.setLineNumber(lineNumber);
                    entry.setSeverity(autoCommitEM.merge(priorities.get(severity.toString())));
                    entry.setText(line);
                    autoCommitEM.persist(entry);
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
            if (em != null) {
                em.close();
            }
        }
    }

}