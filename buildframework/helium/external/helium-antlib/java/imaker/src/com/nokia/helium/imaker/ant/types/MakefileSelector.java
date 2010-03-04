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
package com.nokia.helium.imaker.ant.types;

import java.util.List;

/**
 * Interface used to extend the Makefile introspection of the
 *  iMaker configuration.
 *
 */
public interface MakefileSelector {

    /**
     * Select the configurations to be built based on the object settings.
     * @param configuration
     * @return a list of selected configuration from the input list.
     */
    List<String> selectMakefile(List<String> configurations);
}
