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



package com.nokia.helium.diamonds;

import org.apache.tools.ant.BuildException;

import java.util.*;
import org.dom4j.io.SAXReader;
import org.dom4j.Document;
import org.dom4j.Element;
import org.dom4j.Node;
import org.apache.log4j.Logger;

/**
 * Loads the configuration information from the xml file.
 * 
 */
public final class DiamondsConfig {
    private static DiamondsProperties diamondsProperties;

    private static List<Stage> stages;

    private static Logger log;

    private static Map<String, Target> targets;

    private static String outputDir;

    private static String templateDir;
    
    private static String initialiserTargetName;

    private DiamondsConfig() {
    }
    
    /**
     * Method accessed by loggers to load the diamonds specific configuration.
     * 
     * @param configFile
     *            - configuration to load
     * 
     */
    public static void parseConfiguration(String configFile)
            throws DiamondsException {
        if (log == null) {
            log = Logger.getLogger(DiamondsConfig.class);
        }
        SAXReader saxReader = new SAXReader();
        Document document = null;
        try {
            log.debug("Reading diamonds configuration.");
            document = saxReader.read(configFile);
        } catch (Exception e) {
            // No need to fail the build due to internal Helium configuration errors.
            log.debug("Diamonds configuration parsing error: "
                    + e.getMessage());
        }
        parseConfig(document);
        diamondsProperties = parseDiamondsProperties(document);
        stages = parseStages(document);
        targets = parseTargets(document);
    }

    /**
     * Parses the general configuration info.
     * 
     * @param document
     *            - XML config in DOM4J document
     */
    private static void parseConfig(Document document) {
        log.debug("diamonds:DiamondsConfig:parsing general configuration.");
        Node node = document.selectSingleNode("//output-dir");
        outputDir = node.valueOf("@path");
        node = document.selectSingleNode("//template-dir");
        templateDir = node.valueOf("@path");
    }

    /**
     * Parses the server info.
     * 
     * @param document
     *            - XML config in DOM4J document
     */
    private static DiamondsProperties parseDiamondsProperties(Document document) {
        log.debug("diamonds:DiamondsConfig:parsing diamonds properties.");
        
        Map<String, String> propertiesMap = new HashMap<String, String>();
        
        loadProperty(document, propertiesMap, "host");
        loadProperty(document, propertiesMap, "port");
        loadProperty(document, propertiesMap, "path");
        loadProperty(document, propertiesMap, "tstampformat");
        loadProperty(document, propertiesMap, "mail");
        loadProperty(document, propertiesMap, "ldapserver");
        loadProperty(document, propertiesMap, "smtpserver");
        loadProperty(document, propertiesMap, "initialiser-target-name");
        loadProperty(document, propertiesMap, "category-property");
        loadProperty(document, propertiesMap, "buildid-property");
        return new DiamondsProperties(propertiesMap);
    }

    /**
     * Parses the Targets data from config.
     * 
     * @param document
     *            - XML config in DOM4J document
     * @return list of targets available in the config
     */
    @SuppressWarnings("unchecked")
    private static Map<String, Target> parseTargets(Document document) {
        log.debug("diamonds:DiamondsConfig:parsing for targets");
        Map<String, Target> targets = new HashMap<String, Target>();
        List<Element> stageNodes = document.selectNodes("//target");
       
        // Set initialiserTargetName according to target name defined Diamonds config file
        initialiserTargetName = diamondsProperties.getProperty("initialiser-target-name");
        targets.put(initialiserTargetName, new Target(initialiserTargetName,"","","",""));
        for (Element stageNode : stageNodes) {
            targets.put(stageNode.valueOf("@name"), new Target(stageNode
                    .valueOf("@name"), stageNode.valueOf("@template-file"),
                    stageNode.valueOf("@logfile"), stageNode
                            .valueOf("@ant-properties"), stageNode
                            .valueOf("@defer")));
        }
        return targets;
    }

    /**
     * Parses the stages info.
     * 
     * @param document
     *            - XML config in DOM4J document
     * @return list of stages in config
     */
    @SuppressWarnings("unchecked")
    private static List<Stage> parseStages(Document document) {
        List<Stage> stages = new ArrayList<Stage>();
        List<Element> stageNodes = document.selectNodes("//stage");
        log.debug("diamonds:DiamondsConfig:parsing for stages");
        for (Element stage : stageNodes) {
            stages.add(new Stage(stage.valueOf("@name"), stage
                    .valueOf("@start"), stage.valueOf("@end"), stage
                    .valueOf("@logfile")));
        }
        return stages;
    }

    /**
     * Helper function to get the stages
     * 
     * @return the stages from config in memory
     */
    static List<Stage> getStages() {
        return stages;
    }

    /**
     * Helper function to get the targets
     * 
     * @return the targets from config in memory
     */
    static Map<String, Target> getTargets() {
        return targets;
    }

    /**
     * Returns true if stages exists in config
     * 
     * @return the existance of stages in config
     */
    public static boolean isStagesInConfig() {
        return stages != null;
    }

    /**
     * Returns true if targets exists in config
     * 
     * @return the targets from config in memory
     */
    public static boolean isTargetsInConfig() {
        return targets != null;
    }

    /**
     * Gets the diamonds properties loaded from config
     * 
     * @return the targets from config in memory
     */
    public static DiamondsProperties getDiamondsProperties() {
        return diamondsProperties;
    }

    /**
     * Gets the output directory
     * 
     * @return the output directory, loaded from config
     */
    static String getOutputDir() {
        return outputDir;
    }

    /**
     * Gets the output directory
     * 
     * @return the output directory, loaded from config
     */
    static String getTemplateDir() {
        return templateDir;
    }
    
    /**
     * Gets the initialiserTargetName
     * 
     * @return the initialiserTargetName, loaded from config
     */
    public static String getInitialiserTargetName() {
        return initialiserTargetName;
    }
    
    /**
     * Load diamonds property into hashmap.
     * @param doc
     * @param hash
     * @param name
     * @return
     */
    public static void loadProperty(Document document, Map<String, String> hash, String name) {
        Node node = document.selectSingleNode("//property[@name='" + name + "']");
        if (node == null) {
            throw new BuildException("diamonds: DiamondsConfig:'" + name + "' property definition is missing.");
        }
        hash.put(name, node.valueOf("@value"));
    }

}