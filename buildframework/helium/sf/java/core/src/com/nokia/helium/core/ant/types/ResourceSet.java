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

import org.apache.tools.ant.types.ResourceCollection;

/**
 * A set of resource type.
 * 
 * &lt;hlm:resourceSet&gt;
 *     &lt;fileset dir=&quot;/tmp/dir1&quot; &gt;
 *     &lt;fileset dir=&quot;/tmp/dir2&quot; &gt;
 * &/lt;hlm:resourceSet&gt;
 * 
 * @ant.type name="resourceSet" category="Core"
 */
public class ResourceSet extends TypeSet<ResourceCollection> {
}
