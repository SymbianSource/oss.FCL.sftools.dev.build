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

import java.io.File;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Pattern;

import org.apache.tools.ant.types.Resource;
import org.apache.tools.ant.types.ResourceCollection;

/**
 * This utility class provides a set of functions to manipulate Ant
 * ResourceCollection.
 *
 */
public final class ResourceCollectionUtils {

    /**
     * Private constructor to make sure the class is never 
     * Instantiated.
     */
    private ResourceCollectionUtils() { }
    
    /**
     * Extract the first file form the resource collection matching the pattern.
     * Returns null if not found.
     * @param resourceCollection
     * @param pattern a regular expression as a string
     * @return the first resource matching, or null if not found
     */
    public static File getFile(ResourceCollection resourceCollection, String pattern) {
        return getFile(resourceCollection, Pattern.compile(pattern));
    }
    
    /**
     * Extract the first file form the resource collection matching the pattern.
     * Returns null if not found.
     * @param resourceCollection
     * @param pattern a regular expression as a compile pattern
     * @return the first resource matching, or null if not found
     */
    @SuppressWarnings("unchecked")
    public static File getFile(ResourceCollection resourceCollection, Pattern pattern) {
        Iterator<Resource> ri = (Iterator<Resource>)resourceCollection.iterator();
        while (ri.hasNext()) {
            Resource resource = ri.next();
            if (pattern.matcher(resource.toString()).matches()) {
                return new File(resource.toString());
            }
        }
        return null;
    }
    
    /**
     * Get the ResourceCollection as a list of files.
     * Returns null if not found.
     * @param resourceCollection
     * @return a list of files.
     */
    @SuppressWarnings("unchecked")
    public static List<File> getFiles(ResourceCollection resourceCollection) {
        List<File> files = new ArrayList<File>(); 
        Iterator<Resource> ri = (Iterator<Resource>)resourceCollection.iterator();
        while (ri.hasNext()) {
            files.add(new File(ri.next().toString()));
        }
        return files;
    }
    
}
