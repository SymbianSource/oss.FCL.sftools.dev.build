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
package com.nokia.helium.core.ant.tests;

import static org.junit.Assert.assertTrue;

import java.io.File;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.apache.tools.ant.types.Resource;
import org.apache.tools.ant.types.ResourceCollection;
import org.junit.Test;

import com.nokia.helium.core.ant.ResourceCollectionUtils;

/**
 * Testing the ResourceCollectionUtils utility class
 *
 */
public class TestResourceCollectionUtils {
    
    /**
     * Simplistic ResourceCollection used by unittests.
     */
    class ResourceCollectionImpl implements ResourceCollection {
        
        private List<Resource> resources = new ArrayList<Resource>(); 
        
        private ResourceCollectionImpl(File[] files) {
            for (File file : files) {
                Resource res = new Resource();
                res.setName(file.getAbsolutePath());
                resources.add(res);
            }
        }
        
        public boolean isFilesystemOnly() {
            return true;
        }

        public Iterator<Resource> iterator() {
            return resources.iterator();
        }

        public int size() {
            // TODO Auto-generated method stub
            return resources.size();
        }
        
    }
    
    @Test
    public void getFile() {
        File[] files = new File[3];
        files[0] = new File("foo.xml");
        files[1] = new File("foo.html");
        files[2] = new File("foo.dat");
        File file = ResourceCollectionUtils.getFile(new ResourceCollectionImpl(files), ".*.xml");
        assertTrue("must find one file", file != null);
        assertTrue("must find one file (name check)", file.getName().equals(files[0].getName()));        
    }

    @Test
    public void getFileReturnsNull() {
        File[] files = new File[3];
        files[0] = new File("foo.xml");
        files[1] = new File("foo.html");
        files[2] = new File("foo.dat");
        File file = ResourceCollectionUtils.getFile(new ResourceCollectionImpl(files), ".*\\.ini$");
        assertTrue("must not find a file", file == null);
    }

    @Test
    public void getFiles() {
        File[] files = new File[3];
        files[0] = new File("foo.xml");
        files[1] = new File("foo.html");
        files[2] = new File("foo.dat");
        List<File> outFiles = ResourceCollectionUtils.getFiles(new ResourceCollectionImpl(files));
        assertTrue("must not return null", outFiles != null);
        assertTrue("size must be 3", outFiles.size() == 3);
    }
}
