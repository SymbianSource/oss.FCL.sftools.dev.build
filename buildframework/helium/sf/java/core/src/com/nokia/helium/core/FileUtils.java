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
package com.nokia.helium.core;

import java.io.File;

/**
 * This tool class provides file or system functionalities:
 *   - Find executable location
 *
 */
public final class FileUtils {
    
    private FileUtils() {
    }
    
    /**
     * Find an executable based on given name from the PATH. PATHEXT will be used on windows plaform
     * to search by extension.
     * @param executableName the executable name
     * @return the executable as a File, or null if not found.
     */
    public static File findExecutableOnPath(String executableName) {
        String systemPath = System.getenv("PATH");
        String[] pathDirs = systemPath.split(File.pathSeparator);
        return findExecutableOnPath(executableName, pathDirs); 
    }

    /**
     * Find an executable based on given name from the PATH. PATHEXT will be used on windows plaform
     * to search by extension.
     * @param executableName the executable name.
     * @param pathDirs array of directory to look for
     * @return the executable as a File, or null if not found.
     */
    public static File findExecutableOnPath(String executableName, String[] pathDirs) {
        String[] extensions = {""};
        
        // Using PATHEXT to get the supported extensions on windows platform
        if (System.getProperty("os.name").toLowerCase().startsWith("win")) {
            extensions = System.getenv("PATHEXT").split(File.pathSeparator);
        }
        
        for (String extension : extensions) {
            String checkName = executableName;
            if (System.getProperty("os.name").toLowerCase().startsWith("win") && !executableName.toLowerCase().endsWith(extension.toLowerCase())) {
                checkName = executableName + extension;
            }

            File file = new File(checkName);
            if (file.isAbsolute()) {
                if (file.isFile()) {
                    return file;
                }
            }
            for (String pathDir : pathDirs) {
                file = new File(pathDir, checkName);
                if (file.isFile()) {
                    return file;
                }
            }
        }
        return null;
    }

    
}
