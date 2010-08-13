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

import java.util.Hashtable;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.HlmExceptionHandler;

/**
 * This HlmExceptionHandler will provide execution support for the
 * SignalExceptionConfig configurable elements. User can now reuse. existing
 * notifier to notify the user in case of build failure.
 * 
 */
public class SignalExceptionConfigHandler extends DataType implements
        HlmExceptionHandler {

    /**
     * Looks for all SignalExceptionConfig reference and notify them.
     */
    @SuppressWarnings("unchecked")
    public void handleException(Project project, Exception exception) {
        Hashtable<String, Object> references = project.getReferences();
        for (Object obj : references.values()) {
            if (obj instanceof SignalExceptionConfig) {
                SignalExceptionConfig config = (SignalExceptionConfig) obj;
                config.notify(project, exception);
            }
        }
    }
}
