/*
 * Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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

package com.nokia.helium.environment.ant.types;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.DirSet;

/**
 * Environmental data configuration for the <environment> task.
 * 
 * @ant.task name="envdata" category="Environment"
 */
public class EnvData extends DataType {

    private List<ExecutableInfo> executables = new ArrayList<ExecutableInfo>();
    private List<DirSet> dirsets = new ArrayList<DirSet>();

    public void add(ExecutableInfo executable) {
        if (isReference()) {
            throw noChildrenAllowed();
        }
        executables.add(executable);
    }

    public void add(DirSet dirset) {
        if (isReference()) {
            throw noChildrenAllowed();
        }
        dirsets.add(dirset);
    }

    public void getExecutableDefs(List<ExecutableInfo> executableDefs) throws IOException {
        if (isReference()) {
            EnvData envDataSource = (EnvData) getCheckedRef();
            envDataSource.getExecutableDefs(executableDefs);
        }
        else {
            for (Iterator<ExecutableInfo> iterator = this.executables.iterator(); iterator.hasNext();) {
                ExecutableInfo executableDef = (ExecutableInfo) iterator.next();
                if (!executableDefs.contains(executableDef)) {
                    executableDefs.add(executableDef);
                }

            }
        }
    }
    
    @SuppressWarnings("unchecked")
    public void getDirectories(List<File> directories) throws IOException {
        if (isReference()) {
            EnvData envDataSource = (EnvData) getCheckedRef();
            envDataSource.getDirectories(directories);
        }
        else {
            for (Iterator<DirSet> iterator = this.dirsets.iterator(); iterator.hasNext();) {
                DirSet dirset = (DirSet) iterator.next();
                Iterator dirsetIterator = dirset.iterator();
                while (dirsetIterator.hasNext()) {
                    File file = (File) dirsetIterator.next();
                    directories.add(file);
                }
            }
        }
    }
}



