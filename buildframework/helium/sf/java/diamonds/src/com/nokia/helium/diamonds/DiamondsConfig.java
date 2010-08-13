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

import java.util.HashMap;
import java.util.Map;
import com.nokia.helium.core.ant.types.Stage;
import com.nokia.helium.core.ant.types.TargetMessageTrigger;
import org.apache.tools.ant.Project;
import java.util.Hashtable;
import org.apache.log4j.Logger;

/**
 * Loads the configuration information from the xml file.
 * 
 */
public final class DiamondsConfig {

    private static HashMap<String, Stage> stages = new HashMap<String, Stage>();

    private static Logger log = Logger.getLogger(DiamondsConfig.class);

    private static String initialiserTargetName;
    
    private static Project project;
    
    private static final String DIAMONDS_HOST_PROPERTY = "diamonds.host";
    private static final String DIAMONDS_PORT_PROPERTY = "diamonds.port";
    private static final String DIAMONDS_PATH_PROPERTY = "diamonds.path";
    private static final String DIAMONDS_TSTAMP_PROPERTY = "diamonds.tstamp.format";
    private static final String DIAMONDS_MAIL_PROPERTY = "diamonds.mail";
    private static final String DIAMONDS_LDAP_PROPERTY = "diamonds.ldap.server";
    private static final String DIAMONDS_SMTP_PROPERTY = "diamonds.smtp.server";
    private static final String DIAMONDS_INITIALIZER_TARGET_PROPERTY = "diamonds.initializer.targetname";
    private static final String DIAMONDS_CATEGORY_PROPERTY = "diamonds.category";
    
    
    private static final String[] PROPERTY_NAMES = {DIAMONDS_HOST_PROPERTY, DIAMONDS_PORT_PROPERTY, DIAMONDS_PATH_PROPERTY,
        DIAMONDS_TSTAMP_PROPERTY, DIAMONDS_MAIL_PROPERTY,
        DIAMONDS_LDAP_PROPERTY, DIAMONDS_SMTP_PROPERTY,
        DIAMONDS_INITIALIZER_TARGET_PROPERTY, DIAMONDS_CATEGORY_PROPERTY};

    private static HashMap<String, TargetMessageTrigger> targetMessageList = new HashMap<String, TargetMessageTrigger>();

    private DiamondsConfig() {
    }


    @SuppressWarnings("unchecked")
    private static void initializeMessage(Project prj) {
        Hashtable<String, Object> references = prj.getReferences();
        for (String key : references.keySet()) {
            Object object = references.get(key);
            log.debug("key: " + key);
            if (object instanceof TargetMessageTrigger) {
                log.debug("found message map:" + object);
                log.debug("found key: " + key);
                TargetMessageTrigger message = (TargetMessageTrigger)object;
                targetMessageList.put(message.getTargetName(), (TargetMessageTrigger)object);
            }
        }
    }
    
    @SuppressWarnings("unchecked")
    public static void initialize(Project prj) throws DiamondsException {
        project = prj;
        log.debug("Diamonds config initialization: project: " + project);
        initializeMessage(prj);
        for (String property : PROPERTY_NAMES ) {
            validateProperty(property);
        }
        Hashtable<String, Object> references = prj.getReferences();
        for (String key : references.keySet()) {
            Object object = references.get(key); 
            if (object instanceof Stage) {
                log.debug("stage found: " + key);
                Stage stageMap = (Stage)object;
                stageMap.setStageName(key);
                stages.put(key, (Stage)object);
            }
        }
    }

    private static void validateProperty(String propertyName) throws DiamondsException {
        String propertyValue = project.getProperty(propertyName);
        if (propertyValue == null) {
            throw new DiamondsException("required property: " + propertyName + " not defined");
        }
    }

    /**
     * Helper function to get the stages
     * 
     * @return the stages from config in memory
     */
    static Map<String, Stage> getStages() {
        return stages;
    }

    /**
     * Helper function to get the targets
     * 
     * @return the targets from config in memory
     */
    static HashMap<String, TargetMessageTrigger> getTargetsMap() {
        return targetMessageList;
    }

    /**
     * Returns true if stages exists in config
     * 
     * @return the existance of stages in config
     */
    public static boolean isStagesInConfig() {
        return !stages.isEmpty();
    }

    /**
     * Returns true if targets exists in config
     * 
     * @return the targets from config in memory
     */
    public static boolean isTargetsInConfig() {
        return !targetMessageList.isEmpty();
    }

    public static String getHost() {
        return project.getProperty(DIAMONDS_HOST_PROPERTY);
    }

    public static String getPort() {
        return project.getProperty(DIAMONDS_PORT_PROPERTY);
    }

    public static String getPath() {
        return project.getProperty(DIAMONDS_PATH_PROPERTY);
    }

    public static String getTimeFormat() {
        return project.getProperty(DIAMONDS_TSTAMP_PROPERTY);
    }

    public static String getMailInfo() {
        return project.getProperty(DIAMONDS_MAIL_PROPERTY);
    }

    public static String getLDAPServer() {
        return project.getProperty(DIAMONDS_LDAP_PROPERTY);
    }

    public static String getSMTPServer() {
        return project.getProperty(DIAMONDS_SMTP_PROPERTY);
    }

    public static String getBuildIdProperty() {
        return "diamonds.build.id";
    }

    public static String getBuildId() {
        return project.getProperty(getBuildIdProperty());
    }

    /**
     * Gets the initialiserTargetName
     * 
     * @return the initialiserTargetName
     */
    public static String getInitializerTargetProperty() {
        return DIAMONDS_INITIALIZER_TARGET_PROPERTY;
    }

    public static String getCategory() {
        return project.getProperty(DIAMONDS_CATEGORY_PROPERTY);
    }

}