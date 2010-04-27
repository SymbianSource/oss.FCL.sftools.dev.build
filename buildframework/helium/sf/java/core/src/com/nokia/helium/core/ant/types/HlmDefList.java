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

/**
 * 
 */
public class HlmDefList extends DataType {

    private Vector<HlmPreDefImpl> preDefList = new Vector<HlmPreDefImpl>();
    private Vector<HlmPostDefImpl> postDefList = new Vector<HlmPostDefImpl>();
    private Vector<HlmExceptionHandler> exceptionHandlerList = new Vector<HlmExceptionHandler>();

    /**
     * Creates an empty hlm post-action definition and adds it to the list.
     */
    public HlmPreDefImpl createHlmPreDefImpl() {
        HlmPreDefImpl def = new HlmPreDefImpl();
        add(def);
        return (HlmPreDefImpl) def;
    }

    /**
     * Creates an empty hlm post-action definition and adds it to the list.
     */
    public HlmPostDefImpl createHlmPostDefImpl() {
        HlmPostDefImpl def = new HlmPostDefImpl();
        add(def);
        return (HlmPostDefImpl) def;
    }

    /**
     * Add a given variable to the list
     * 
     * @param var
     *            variable to add
     */
    public void add(HlmPreDefImpl definition) {
        if (definition != null) {
            preDefList.add(definition);
        }
    }

    /**
     * Add a post-action to the list.
     */
    public void add(HlmPostDefImpl definition) {
        if (definition != null) {
            postDefList.add(definition);
        }
    }
    
    /**
     * Add a exception handler to the list.
     */
    public void add(HlmExceptionHandler exceptionHandler) {
        if (exceptionHandler != null) {
            exceptionHandlerList.add(exceptionHandler);
        }
    }

    /**
     * Get the pre-action list.
     * 
     * @return a vector containing all the pre-actions
     */
    public Vector<HlmPreDefImpl> getPreDefList() {
        return preDefList;
    }

    /**
     * Get the post-action list.
     * 
     * @return a vector containing all the post-actions
     */
    public Vector<HlmPostDefImpl> getPostDefList() {
        return postDefList;
    }
    
    /**
     * Get the exception handler list.
     * 
     * @return a vector containing all the exception handlers
     */
    public Vector<HlmExceptionHandler> getExceptionHandlerList() {
        return exceptionHandlerList;
    }
}