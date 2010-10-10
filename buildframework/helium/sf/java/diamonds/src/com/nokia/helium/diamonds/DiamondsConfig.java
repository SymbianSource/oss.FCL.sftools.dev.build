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

import org.apache.tools.ant.Project;

/**
 * Loads the configuration information from Ant project.
 * 
 */
public final class DiamondsConfig {
    
    private static final String DIAMONDS_HOST_PROPERTY = "diamonds.host";
    private static final String DIAMONDS_PORT_PROPERTY = "diamonds.port";
    private static final String DIAMONDS_PATH_PROPERTY = "diamonds.path";
    private static final String DIAMONDS_TSTAMP_PROPERTY = "diamonds.tstamp.format";
    private static final String DIAMONDS_MAIL_PROPERTY = "diamonds.mail";
    private static final String DIAMONDS_LDAP_PROPERTY = "diamonds.ldap.server";
    private static final String DIAMONDS_SMTP_PROPERTY = "diamonds.smtp.server";
    private static final String DIAMONDS_INITIALIZER_TARGET_PROPERTY = "diamonds.initializer.targetname";
    private static final String DIAMONDS_CATEGORY_PROPERTY = "diamonds.category";
    private static final String DIAMONDS_BUILD_ID_PROPERTY = "diamonds.build.id";
    private static final String[] PROPERTY_NAMES = {DIAMONDS_HOST_PROPERTY, DIAMONDS_PORT_PROPERTY, DIAMONDS_PATH_PROPERTY,
        DIAMONDS_TSTAMP_PROPERTY, DIAMONDS_MAIL_PROPERTY,
        DIAMONDS_LDAP_PROPERTY, DIAMONDS_SMTP_PROPERTY,
        DIAMONDS_INITIALIZER_TARGET_PROPERTY, DIAMONDS_CATEGORY_PROPERTY};
    
    private Project project;
    private Boolean enabled;
    
    public DiamondsConfig(Project project) throws DiamondsException {
        this.project = project;
        if (this.isDiamondsEnabled()) {
            initialize();
        }
    }
    
    private void initialize() throws DiamondsException {
        for (String property : PROPERTY_NAMES) {
            String propertyValue = project.getProperty(property);
            if (propertyValue == null) {
                throw new DiamondsException("required property: " + property + " not defined");
            }
        }
        try {
            Integer.parseInt(project.getProperty(DIAMONDS_PORT_PROPERTY));
        } catch (NumberFormatException e) {
            throw new DiamondsException("Invalid port number for property " +
                    DIAMONDS_PORT_PROPERTY + ": " + project.getProperty(DIAMONDS_PORT_PROPERTY));
        }
    }

    public String getHost() {
        return project.getProperty(DIAMONDS_HOST_PROPERTY);
    }

    public String getPort() {
        return project.getProperty(DIAMONDS_PORT_PROPERTY);
    }

    public String getPath() {
        return project.getProperty(DIAMONDS_PATH_PROPERTY);
    }

    public String getTimeFormat() {
        return project.getProperty(DIAMONDS_TSTAMP_PROPERTY);
    }

    public String getMailInfo() {
        return project.getProperty(DIAMONDS_MAIL_PROPERTY);
    }

    public String getLDAPServer() {
        return project.getProperty(DIAMONDS_LDAP_PROPERTY);
    }

    public String getSMTPServer() {
        return project.getProperty(DIAMONDS_SMTP_PROPERTY);
    }

    public String getBuildIdProperty() {
        return DIAMONDS_BUILD_ID_PROPERTY;
    }

    public  String getBuildId() {
        return project.getProperty(DIAMONDS_BUILD_ID_PROPERTY);
    }

    /**
     * Gets the initialiserTargetName
     * 
     * @return the initialiserTargetName
     */
    public String getInitializerTargetName() {
        String targetName = project.getProperty(DIAMONDS_INITIALIZER_TARGET_PROPERTY);
        if (targetName != null) {
            if (project.getTargets().containsKey(targetName)) {
                return targetName;
            } else {
                project.log("'" + DIAMONDS_INITIALIZER_TARGET_PROPERTY + "' property reference and unexisting target: " + targetName);
            }
        }
        return null;
    }

    public String getCategory() {
        return project.getProperty(DIAMONDS_CATEGORY_PROPERTY);
    }
    
    public boolean isDiamondsEnabled() {
        if (enabled == null) {
            String diamondsEnabled = project.getProperty("diamonds.enabled");
            if (diamondsEnabled != null) {
                enabled = new Boolean(Project.toBoolean(diamondsEnabled));
            } else {
                enabled = Boolean.TRUE;
            }
        }
        return enabled.booleanValue();
    }

}