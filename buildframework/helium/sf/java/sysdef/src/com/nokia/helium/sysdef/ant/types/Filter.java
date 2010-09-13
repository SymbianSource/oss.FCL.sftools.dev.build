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
package com.nokia.helium.sysdef.ant.types;

import java.io.File;

import com.nokia.helium.sysdef.ant.taskdefs.FilterTask;

/**
 * This interface defines filter applied by the sysdefFilter task.
 *
 */
public interface Filter {

    /**
     * Validate the object parameters.
     * This method will be called before the filter method.
     */
    void validate();
    
    /**
     * Apply filtering on the src file and save the outcome into
     * the dest file.
     * @param task the calling task.
     * @param src the source file
     * @param dest the dest file.
     */
    void filter(FilterTask task, File src, File dest);
    
}
