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
 * Description: To print the message on the shell in case of build has errors
 * is user sets failbuild status to never in signal configuration file.
 *
 */

package com.nokia.helium.signal.ant;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.PostBuildAction;

/**
 * Class to check the signal is present in the never signal list. Print the
 * message on the shell "Build completed with errors and warnings".
 * 
 */
public class SignalNeverFailMessage extends DataType implements
        PostBuildAction {

    /**
     * Override execute method to print build completed message.
     * 
     * @param prj
     * @param module
     * @param targetNames
     */
    public void executeOnPostBuild(Project project, String[] targetNames) {
        if (!Signals.getSignals().getNeverSignalList().isEmpty()) {
            log("Build completed with errors and warnings.", Project.MSG_WARN);
        }
    }
}