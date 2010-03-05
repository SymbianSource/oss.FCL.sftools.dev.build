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

/**
 * Helper class for the target in diamonds config.
 * 
 */
public class Target {
    private String targetName;
    private String source;
    private boolean reqAntProperties;
    private boolean defer;
    private String templatefile;

    /**
     * Constructor
     * 
     * @param target
     *            - name of the target
     * @param src
     *            - input source location.
     */
    public Target(String target, String src) {
        this(target, null, src, "false", "false");
    }

    /**
     * Constructor
     * 
     * @param target
     *            - name of the target
     * @param src
     *            - input source location.
     * @param antProps
     *            - boolean to pass ant properties while conversion.
     */
    public Target(String target, String tplfile, String src, String antProps,
            String deferSend) {
        String emptyString = "";
        if (!target.equals(emptyString)) {
            targetName = target;
        }
        if (!src.equals(emptyString)) {
            source = src;
        }
        if (!tplfile.equals(emptyString)) {
            templatefile = tplfile;
        }
        if (antProps != null && antProps.equals("true")) {
            reqAntProperties = true;
        }
        if (deferSend != null && deferSend.equals("true")) {
            defer = true;
        }
    }

    /**
     * Get the target name of the target to send data
     * 
     * @return - target name of the target to send data
     */
    public String getTargetName() {
        return targetName;
    }

    /**
     * Get the input source used for template conversion.
     * 
     * @return - location of the input source.
     */
    public String getSource() {
        return source;
    }

    public boolean isDefer() {
        return defer;
    }

    public String getTemplateFile() {
        return templatefile;
    }

    /**
     * returns true if ant properties required for conversion, obtained from
     * configuration.
     * 
     * @return - name of the stage
     */
    public boolean isAntPropertiesRequired() {
        return reqAntProperties;
    }
}