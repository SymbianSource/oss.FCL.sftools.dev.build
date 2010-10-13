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

package com.nokia.helium.signal.ant.types;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.PostBuildAction;
import com.nokia.helium.signal.ant.Signals;

/**
 * Class to store the status of the signal of a particular target.
 */
public class SignalStatusDef extends DataType implements PostBuildAction {
    
    /**
     * This post action will fail the build if any pending failure exists.
     * 
     * @throws BuildException
     */
    public void executeOnPostBuild(Project project, String[] targetNames) {
        if (!Signals.getSignals().getDeferredSignalList().isEmpty()) {
            throw new BuildException(Signals.getSignals().getDeferredSignalList().toString());
        }
    }
}
