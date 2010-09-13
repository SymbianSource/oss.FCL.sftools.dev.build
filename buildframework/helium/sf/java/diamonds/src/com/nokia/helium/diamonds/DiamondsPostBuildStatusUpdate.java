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
 * Description: To update the build status to Diamonds with signals in case of build exceptions.
 *
 */

package com.nokia.helium.diamonds;

import org.apache.log4j.Logger;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.Project;
import com.nokia.helium.core.ant.PostBuildAction;

/**
 * Class to store the builds status and send the generated XML file to diamonds client class to
 * update the build status into diamonds
 */
public class DiamondsPostBuildStatusUpdate extends DataType implements PostBuildAction {
    private Logger log;

    /* Initiate build status to failed as this method will be invoked in case of exceptions only */
    private String buildStatus = "succeeded";

    private String outputFile, templateFile;


    public DiamondsPostBuildStatusUpdate() {
        log = Logger.getLogger(DiamondsPostBuildStatusUpdate.class);
    }

    /**
     * Override execute method to update build status to diamonds.
     * 
     * @param prj
     * @param module
     * @param targetNames
     */
    @SuppressWarnings("unchecked")
    public void executeOnPostBuild(Project project, String[] targetNames) {
        try {
            if (DiamondsListenerImpl.isInitialized()) {
                Project prj = DiamondsListenerImpl.getProject(); 
                prj.setProperty("build.status", buildStatus);
                DiamondsListenerImpl.sendMessage("diamonds-status");
            }
        } catch (DiamondsException de) {
            log.error("Not able to merge into full results XML file " + de.getMessage(), de);
        }
    }

}