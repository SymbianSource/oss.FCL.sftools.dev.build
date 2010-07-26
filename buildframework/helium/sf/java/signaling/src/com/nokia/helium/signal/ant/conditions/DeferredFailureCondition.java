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


package com.nokia.helium.signal.ant.conditions;

import org.apache.tools.ant.taskdefs.condition.Condition;
import com.nokia.helium.signal.SignalStatus;
import com.nokia.helium.signal.SignalStatusList;

import org.apache.tools.ant.ProjectComponent;

/**
 * The hasDeferredFailure condition allows you to know if any diferred failure are pending,
 * or simply if a specific kind of failure has been deferred.
 *
 * Check for any pending failure, e.g: 
 * <pre>
 * &lt;condition property="pending.failure"&gt;
 *     &lt;hlm:hasDeferredFailure/&gt;
 * &lt;/condition&gt;
 * </pre>

 * Check for a particular pending failure e.g:
 * <pre>
 * &lt;condition property="pending.compile.failure"&gt;
 *     &lt;hlm:hasDeferredFailure name="compileSignal"/&gt;
 * &lt;/condition&gt;
 * </pre>
 * @ant.type name="hasDeferredFailure" category="Signaling"
 * 
 */
public class DeferredFailureCondition extends ProjectComponent implements
        Condition {

    private String name;

    /**
     * Set the signal name.
     * @ant.not-required Ignored by default
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Evaluate to true if name is not defined and has any pending failure. Or
     * if name is defined and has any pending failure with that particular
     * signal name.
     */
    public boolean eval() {
        if (name != null) {
            getProject().log("Has deferred " + name + " failure?");
            for (SignalStatus signal : SignalStatusList.getDeferredSignalList().getSignalStatusList()) {
                if (signal.getName().equals(name)) {
                    getProject().log("Failure " + name + " found.");
                    return true;
                }
            }
        } else {
            getProject().log(
                    "Deferred failure: "
                            + ((SignalStatusList.getDeferredSignalList().hasSignalInList()) ? "Yes"
                                    : "No"));
            return SignalStatusList.getDeferredSignalList().hasSignalInList();
        }
        return false;
    }

}
