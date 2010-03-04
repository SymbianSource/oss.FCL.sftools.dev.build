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

package com.nokia.helium.core;

import freemarker.template.Template;
import freemarker.template.Configuration;

import java.io.FileWriter;
import java.io.File;
import java.util.List;
import java.util.HashMap;
import java.util.Map;
import org.apache.log4j.Logger;

/**
 * Template processor.
 * 
 */
public class TemplateProcessor {

    private Logger log = Logger.getLogger(TemplateProcessor.class);

    /**
     * Create a Map of FreeMarker compatible data from the list of input source.
     * 
     * @param inputSources
     * @return
     * @throws TemplateProcessorException
     */
    private HashMap<String, Object> getTemplateMap(
            List<TemplateInputSource> inputSources) {
        HashMap<String, Object> templateMap = new HashMap<String, Object>();
        try {
            for (TemplateInputSource source : inputSources) {
                if (source instanceof XMLTemplateSource) {
                    XMLTemplateSource xmlSource = (XMLTemplateSource) source;
                    File inputFile = xmlSource.getSourceLocation();
                    if (inputFile.exists()) {
                        templateMap.put(xmlSource.getSourceName(),
                                freemarker.ext.dom.NodeModel.parse(inputFile));
                    } else {
                        log.debug("TemplateProcessor: input file " + inputFile
                                + " for the template does not exists");
                    }
                } else if (source instanceof PropertiesSource) {
                    PropertiesSource propSource = (PropertiesSource) source;
                    templateMap.put(propSource.getSourceName(), propSource
                            .getProperties());
                } else if (source instanceof PPInputSource) {
                    PPInputSource ppSource = (PPInputSource) source;
                    templateMap.put(ppSource.getSourceName(), ppSource
                            .getPPHash());
                }
            }
        } catch (java.io.IOException e) {
            throw new TemplateProcessorException(
                    "I/O Error during template conversion: " + e.getMessage());
        } catch (org.xml.sax.SAXException e1) {
            throw new TemplateProcessorException("XML parser error: "
                    + e1.getMessage());
        } catch (javax.xml.parsers.ParserConfigurationException e3) {
            throw new TemplateProcessorException("Parser error: "
                    + e3.getMessage());
        }
        return templateMap;
    }

    /**
     * Convert a template.
     * 
     * @param templateFile
     * @param outputFile
     * @param sourceList
     * @throws TemplateProcessorException
     */
    public void convertTemplate(String templateFile, String outputFile,
            List<TemplateInputSource> sourceList) {
        convertTemplate(new File(templateFile), new File(outputFile),
                sourceList);
    }

    /**
     * Convert a template.
     * 
     * @param templateFile
     * @param outputFile
     * @param sourceList
     * @throws TemplateProcessorException
     */
    public void convertTemplate(File templateFile, File outputFile,
            List<TemplateInputSource> sourceList) {
        if (templateFile != null) {
            convertTemplate(templateFile.getParent(), templateFile.getName(),
                    outputFile.toString(), sourceList);
        } else {
            throw new TemplateProcessorException("Template file not defined.");
        }
    }

    /**
     * Converts the template to generate xml file to be sent to the server.
     * 
     * @param templateFile
     *            - template file to be converted
     * @param input
     *            - input source file.
     * @param outputFile
     *            - location to store the converted file
     * @param antProperties
     *            - used as one of the input for conversion.
     * @param inputSourceType
     *            - source input type (xml / properties from file). Currently
     *            xml input source is the only one supported.
     * @return - location of the input source.
     * @throws TemplateProcessorException
     */
    public void convertTemplate(String templateDir, String templateFile,
            String outputFile, List<TemplateInputSource> sourceList) {

        Configuration cfg = new Configuration();
        File templateDirFile = new File(templateDir);
        if (templateDir != null && templateDirFile.exists()) {
            try {
                cfg.setDirectoryForTemplateLoading(templateDirFile);
                log
                        .debug("diamonds:TemplateProcessor:adding template directory loader: "
                                + templateDir);
            } catch (java.io.IOException ie) {
                throw new TemplateProcessorException(
                        "Template directory configuring error: " + ie);
            }
        } else {
            throw new TemplateProcessorException(
                    "Template directory does not exist: "
                            + templateDirFile.getAbsolutePath());
        }
        try {
            Template template = cfg.getTemplate(templateFile);
            Map<String, Object> templateMap = getTemplateMap(sourceList);
            template.process(templateMap, new FileWriter(outputFile));
        } catch (freemarker.core.InvalidReferenceException ivx) {
            throw new TemplateProcessorException(
                    "Invalid reference in config: " + ivx);
        } catch (freemarker.template.TemplateException e2) {
            throw new TemplateProcessorException("TemplateException: " + e2);
        } catch (java.io.IOException e) {
            throw new TemplateProcessorException(
                    "I/O Error during template conversion: " + e);
        }
    }
}
