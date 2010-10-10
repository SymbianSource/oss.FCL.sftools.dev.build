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
package com.nokia.helium.antlint.ant.types;

import java.util.List;

import org.apache.tools.ant.Target;

import com.nokia.helium.ant.data.ProjectMeta;
import com.nokia.helium.ant.data.RootAntObjectMeta;
import com.nokia.helium.ant.data.TargetMeta;

/**
 * <code>AbstractTargetCheck</code> is an abstract check class used to run
 * against target level.
 * 
 */
public abstract class AbstractTargetCheck extends AbstractProjectCheck {

    /**
     * {@inheritDoc}
     */
    protected void run(RootAntObjectMeta root) {
        if (root instanceof ProjectMeta) {
            ProjectMeta projectMeta = (ProjectMeta) root;
            List<TargetMeta> targets = projectMeta.getTargets();
            for (TargetMeta targetMeta : targets) {
                run(targetMeta);
            }
        }
    }

    /**
     * Check the availability of dependent targets for the given target.
     * 
     * @param targetName is the target for which dependent targets to be looked
     *            up.
     * @return true, if the dependant targets are available; otherwise false
     */
    protected boolean checkTargetDependency(String targetName) {
        Target targetDependency = (Target) getProject().getTargets().get(targetName);
        return targetDependency != null && targetDependency.getDependencies().hasMoreElements();
    }

    /**
     * Method to run the check against the input {@link TargetMeta}.
     * 
     * @param targetMeta is the {@link TargetMeta} against whom the check is
     *            run.
     */
    protected abstract void run(TargetMeta targetMeta);

}
