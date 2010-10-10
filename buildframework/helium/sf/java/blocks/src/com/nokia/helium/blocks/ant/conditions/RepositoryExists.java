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
package com.nokia.helium.blocks.ant.conditions;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.taskdefs.condition.Condition;

import com.nokia.helium.blocks.Blocks;
import com.nokia.helium.blocks.BlocksException;
import com.nokia.helium.blocks.Repository;
import com.nokia.helium.blocks.ant.AbstractBlocksTask;

/**
 * The blocksRepositoryExists condition help you to check the existence of a repository definition under
 * a specific workspace.  
 * 
 * This example will set the 'exists' property if a 'my_repository_name' repository is defined in the wsid workspace:
 * <pre>
 * &lt;condition property=&quot;exists&quot; &gt;
 *     &lt;hlm:blocksRepositoryExists  name=&quot;my_repository_name&quot; /&gt;
 * &lt;/condition&gt;
 * </pre>

 * This example will set the 'exists' property if any repository are defined in the wsid workspace:
 * <pre>
 * &lt;condition property=&quot;exists&quot; &gt;
 *     &lt;hlm:blocksRepositoryExists /&gt;
 * &lt;/condition&gt;
 * </pre>
 * 
 * @ant.type name="blocksRepositoryExists" category="Blocks"
 */

public class RepositoryExists extends AbstractBlocksTask implements Condition {
    private String name;
    
    /**
     * The name of the repository to check the existence.
     * @param name
     * @ant.not-required
     */
    public void setName(String name) {
        this.name = name;
    }
    /**
     * {@inheritDoc}
     */
    @Override
    public boolean eval() {        
        Blocks blocks = getBlocks();
        try {
            for (Repository repository : blocks.listRepository(getWsid())) {
                if (name != null && name.equals(repository.getName())) {
                    return true;
                } else if (name == null) {
                    return true;
                }

            }
        } catch (BlocksException e) {
            throw new BuildException(e);
        }
        return false;
    }
}
