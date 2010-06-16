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

package com.nokia.helium.metadata.tests;

import java.io.File;
import java.util.Iterator;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.FileSet;
import org.junit.Test;

import com.nokia.helium.jpa.entity.metadata.Metadata;
import com.nokia.helium.metadata.ant.types.IMakerLogMetaDataInput;

/**
 * Tests the iMaker log metadata input parser.
 */
public class TestIMakerLogMetaDataInput {

    /** The number of images in the sample log file that has errors. */
    public static final int IMAGES_WITH_ERRORS_TOTAL = 5;
    
    /**
     * Read a sample log file and verify that the right number of images (components) is identified.
     */
    @Test
    public void testParseIMakerLogfile() {
        IMakerLogMetaDataInput imakerInput = new IMakerLogMetaDataInput();
        imakerInput.setProject(new Project());
        FileSet fileset = new FileSet();
        fileset.setDir(new File("."));
        fileset.setFile(new File("../sf/java/metadata/tests/data/build_roms_sample.log"));
        imakerInput.add(fileset);
        
        // Iterate through the entries
        Iterator<Metadata.LogEntry> inputIterator = imakerInput.iterator();
        int componentTotal = 0;
        while (inputIterator.hasNext()) {
            Metadata.LogEntry logEntry = inputIterator.next();
            System.out.println("logentry: " + logEntry.toString());
            componentTotal++;
        }
        assert (componentTotal == IMAGES_WITH_ERRORS_TOTAL);
    }
}



