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
package com.nokia.helium.metadata.ant.types.sbs;

import java.io.File;

import com.nokia.helium.metadata.ant.types.SeverityEnum;

/**
 * Basic interface that an object should implement to get
 * event from SBS log parsing. 
 *
 */
public interface SBSLogEvents {

    /**
     * Component is found.
     * @param component
     */
    void declareComponent(String component);
    
    /**
     * Analyzing text in component.
     * @param text
     */
    SeverityEnum.Severity check(String component, String text, int lineNumber);

    /**
     * Analyzing text in general section
     * @param text
     */
    SeverityEnum.Severity check(String text, int lineNumber);
    
    /**
     * Add a message with a known severity
     * @param severity
     * @param text
     * @param lineNumber
     */
    void add(SeverityEnum.Severity severity, String text, int lineNumber);
    
    /**
     * 
     * @param severity
     * @param component
     * @param text
     * @param lineNumber
     */
    void add(SeverityEnum.Severity severity, String component, String text, int lineNumber);
    
    /**
     * 
     * @param component
     * @param location
     * @param lineNumber
     */
    void addWhatEntry(String component, String location, int lineNumber);
    
    /**
     * Get the default component name, this is useful for global error. 
     * @return
     */
    String getDefaultComponentName();

    /**
     * Get epocroot. This is used to compute the component name.
     * @return epocroot.
     */
    File getEpocroot();

    /**
     * Update the elapsed time for a component. 
     * @param currentComponent
     * @param doubleValue
     */
    void addElapsedTime(String component, double duration);
}
