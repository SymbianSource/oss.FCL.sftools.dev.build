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
 
package com.nokia.helium.core.ant;

import org.apache.tools.ant.types.DataType;
import com.nokia.helium.core.ant.types.Variable;
import java.util.Collection;

/**
 * Interface to get the list of variables of type VariableSet
 */
public class VariableIFImpl extends DataType 
{

    
    /**
     * Get the name of the variable.
     * @return name.
     */
    public Collection<Variable> getVariables() {
        //Implemented by sub class
        return null;
    }

}