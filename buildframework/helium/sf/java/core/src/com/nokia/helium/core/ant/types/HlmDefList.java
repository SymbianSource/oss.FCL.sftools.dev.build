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

package com.nokia.helium.core.ant.types;

import java.util.Vector;

import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.HlmExceptionHandler;
import com.nokia.helium.core.ant.PostBuildAction;
import com.nokia.helium.core.ant.PreBuildAction;

/**
 * HlmDefList is a class used to store the pre/post build events and the
 * exception handlers.
 * 
 * @ant.type name="deflist" category="Core"
 */
public class HlmDefList extends DataType {

    private Vector<PreBuildAction> preBuildActions = new Vector<PreBuildAction>();
    private Vector<PostBuildAction> postBuildActions = new Vector<PostBuildAction>();
    private Vector<HlmExceptionHandler> exceptionHandlers = new Vector<HlmExceptionHandler>();

    /**
     * Method to add a pre/post build action or an exception handler.
     * 
     * @param type
     *            is the datatype representing a pre/post build action or an
     *            exception handler.
     */
    public void add(DataType type) {
        if (type instanceof PreBuildAction) {
            preBuildActions.add((PreBuildAction) type);
        }
        if (type instanceof PostBuildAction) {
            postBuildActions.add((PostBuildAction) type);
        }
        if (type instanceof HlmExceptionHandler) {
            exceptionHandlers.add((HlmExceptionHandler) type);
        }
    }

    /**
     * Get the list of pre build actions.
     * 
     * @return the list of pre build actions.
     */
    public Vector<PreBuildAction> getPreBuildActions() {
        return preBuildActions;
    }

    /**
     * Get the list of post build actions.
     * 
     * @return the list of post build actions.
     */
    public Vector<PostBuildAction> getPostBuildActions() {
        return postBuildActions;
    }

    /**
     * Get the list of exception handlers.
     * 
     * @return the list of exception handlers
     */
    public Vector<HlmExceptionHandler> getExceptionHandlers() {
        return exceptionHandlers;
    }
}