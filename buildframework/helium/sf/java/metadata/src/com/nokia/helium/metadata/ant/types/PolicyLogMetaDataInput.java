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
import java.util.Map;
import java.util.regex.Pattern;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.Locator;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import com.nokia.helium.metadata.AutoCommitEntityManager;
import com.nokia.helium.metadata.MetadataException;
import com.nokia.helium.metadata.model.metadata.LogFile;
import com.nokia.helium.metadata.model.metadata.MetadataEntry;
import com.nokia.helium.metadata.model.metadata.Severity;
import com.nokia.helium.metadata.model.metadata.SeverityDAO;


/**
 * This Type is to specify and use the policy logparsertype to 
 * parse and store the data based on xmlstreamreader.
 * <pre>
 * &lt;hlm:metadatafilterset id="policy.metadata.filter"&gt;
 *    &lt;metadatafilterset filterfile="common.csv" /&gt;
 * &lt;/hlm:metadatafilterset&gt;
 * 
 * &lt;hlm:policymetadatainput&gt;
 *    &lt;fileset dir="${project.dir}/../data/"&gt;
 *        &lt;include name="*validate*policy*.log"/&gt;
 *    &lt;/fileset&gt;
 *    &lt;metadatafilterset refid="policy.metadata.filter" /&gt;
 * &lt;/hlm:policymetadatainput&gt;
 * </pre>
 * @ant.task name="policymetadatainput" category="Metadata"
 */
public class PolicyLogMetaDataInput extends LogMetaDataInput {
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void extract(EntityManagerFactory factory, File file)
        throws MetadataException {
        SAXParserFactory saxFactory = SAXParserFactory.newInstance();
        EntityManager em = factory.createEntityManager();
        AutoCommitEntityManager autoCommitEM = new AutoCommitEntityManager(factory);
        try {
            // get the severities
            SeverityDAO pdao = new SeverityDAO();
            pdao.setEntityManager(em);
            Map<String, Severity> severities = pdao.getSeverities();

            // Get the log file
            LogFile logFile = getLogFile(em, file);

            SAXParser parser = saxFactory.newSAXParser();
            parser.parse(file, new PolicyFileParser(
                    severities.get(SeverityEnum.Severity.ERROR.toString()),
                    autoCommitEM, logFile));
        } catch (SAXException e) {
            throw new MetadataException(e.getMessage(), e);
        } catch (IOException e) {
            throw new MetadataException(e.getMessage(), e);
        } catch (ParserConfigurationException e) {
            throw new MetadataException(e.getMessage(), e);
        } finally {
            em.close();
            autoCommitEM.close();
        }
    }
    
    /**
     * SAX handler for Policy XML file format.
     *
     */
    class PolicyFileParser extends DefaultHandler {
        private LogFile logFile;
        private Severity severity;
        private AutoCommitEntityManager autoCommitEM;
        private Locator locator;
        
        /**
         * Create a new PolicyFileParser.
         * @param severity
         * @param autoCommitEM
         * @param logFile
         */
        public PolicyFileParser(Severity severity, AutoCommitEntityManager autoCommitEM, 
                LogFile logFile) {
            this.autoCommitEM = autoCommitEM;
            this.logFile = logFile;
            this.severity = severity;
        }

        /**
         * Implement the handling of error nodes.
         */
        @Override
        public void startElement(String uri, String localName, String qName,
                Attributes attributes) throws SAXException {
            if (qName.equalsIgnoreCase("error")) {
                String errorType = attributes.getValue("", "type");
                MetadataEntry me = new MetadataEntry();
                me.setLogFile(autoCommitEM.merge(logFile));
                me.setLineNumber(locator.getLineNumber());
                me.setSeverity(severity);
                if (errorType.equals("unknownstatus")) {
                    me.setText(attributes.getValue("", "message") + attributes.getValue("", "value"));
                } else if (errorType.equals("A") || errorType.equals("B") 
                        || errorType.equals("C") || errorType.equals("D")) {
                    int flags = Pattern.CASE_INSENSITIVE | Pattern.DOTALL ;
                    Pattern pattern = Pattern.compile("([\\\\/][^\\\\/]+?)$", flags);
                    me.setText(pattern.matcher(errorType + "Found incorrect value for " 
                            + attributes.getValue("", "message")).replaceAll(""));
                } else if (errorType.equals("missing")) {
                    me.setText(attributes.getValue("", "message"));
                } else if (errorType.equals("invalidencoding")) {
                    me.setText(attributes.getValue("", "message"));
                }
                autoCommitEM.persist(me);
            }
        }
        
        /**
         * {@inheritDoc}
         */
        @Override
        public void setDocumentLocator(Locator locator) {
            this.locator = locator;
            super.setDocumentLocator(locator);
        }
    }
    
}