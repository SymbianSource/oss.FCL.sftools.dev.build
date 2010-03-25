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

/**
 * This type is a container for variable configuration.
 * A set of command will be generated for each group
 * present in the imakerconfiguration.
 * 
 * <pre>
 * &lt;variablegroup&gt;
 *     &lt;variable name="TYPE" value="rnd" /&gt;
 * &lt;/variablegroup&gt;
 * </pre>
 * 
 * @ant.type name=variablegroup category="imaker"
 */
public class VariableGroup extends VariableSet {

}
