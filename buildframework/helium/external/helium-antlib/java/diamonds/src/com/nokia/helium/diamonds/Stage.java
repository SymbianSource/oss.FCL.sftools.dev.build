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
 * Helper class for Stage configuration of Diamonds.
 * 
 */
public class Stage {
    private String stageName;
    private String startTargetName;
    private String endTargetName;
    private String source;

    /**
     * Constructor
     * 
     * @param stName
     *            - name of the stage
     * @param startTgName
     *            - Name of the start target
     * @param endTgName
     *            - Name of the ending target of the stage
     */
    public Stage(String stName, String startTgName, String endTgName,
            String sourceFiles) {
        String emptyString = "";
        if (!stName.equals(emptyString)) {
            stageName = stName;
        }
        if (!startTgName.equals(emptyString)) {
            startTargetName = startTgName;
        }
        if (!endTgName.equals(emptyString)) {
            endTargetName = endTgName;
        }
        if (!sourceFiles.equals(emptyString)) {
            source = sourceFiles;
        }
    }

    /**
     * Get the stage Name of the stage.
     * 
     * @return - name of the stage
     */
    public String getStageName() {
        return stageName;
    }

    /**
     * Get the stage Name of the stage.
     * 
     * @return - name of the stage
     */
    public String getSourceFile() {
        return source;
    }

    /**
     * gets the start target of the stage
     * 
     * @return - start target of the stage
     */
    public String getStartTargetName() {
        return startTargetName;
    }

    /**
     * gets the end target name of the stage.
     * 
     * @return - end target name of the stage
     */
    public String getEndTargetName() {
        return endTargetName;
    }
}