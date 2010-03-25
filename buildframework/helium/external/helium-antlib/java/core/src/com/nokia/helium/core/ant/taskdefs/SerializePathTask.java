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


package com.nokia.helium.core.ant.taskdefs;

import java.io.*;
import java.util.Vector;
import java.util.Iterator;

import org.apache.tools.ant.Task;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.Path;

/**
 * This class implements a Path de/serializer which can dumps the list of files
 * to a UTF-8 file or retrieve a list path from a file into a path datatype.
 *
 * Examples:
 * <pre>
 * &lt;target name=&quot;serialize&quot;&gt;
 *   &lt;hlm:path2file file=&quot;output.txt&quot;&gt;
 *     &lt;path&gt;
 *         &lt;pathelement path=&quot;/temp/filename.ext&quot;/&gt;
 *     &lt;/path&gt;
 *   &lt;/hlm:path2file&gt;
 * &lt;/target&gt;
 * </pre>
 * 
 * The execution of the <code>serialize</code> task will produce a file called output.txt that will contains
 * a line referencing the /temp/filename.ext.

 * <pre>
 * &lt;target name=&quot;deserialize&quot;&gt;
 *   &lt;hlm:path2file reference=&quot;output.ref&quot;&gt; file=&quot;output.txt&quot;/&gt;
 * &lt;/target&gt;
 * </pre>
 * 
 * The execution of the <code>deserialize</code> task will create a path datatype that will
 * contains a pathelement pointing on <code>/temp/filename.ext.</code>
 * 
 * @ant.task name="path2file" category="Core"
 */
public class SerializePathTask extends Task {

    private Vector<Path> paths = new Vector<Path>();
    private File filename;
    private String reference;

    /**
     * Add path datatype to the task.
     * 
     * @param path
     */
    public void add(Path path) {
        paths.add(path);
    }

    /**
     * Set reference attribute.
     * 
     * @param reference
     */
    public void setReference(String reference) {
        this.reference = reference;
    }

    /**
     * Set file attribute. It is a mandatory setting.
     * 
     * @param filename
     */
    public void setFile(File filename) {
        this.filename = filename;
    }

    /**
     * Excecute the task. If filename is defined and reference is not, it will
     * try to dump the paths content into a file. Else if a filename and a
     * reference is defined it will covert each line of the file into a
     * pathelement of a path datatype.
     */
    public void execute() {
        if (filename == null) {
            throw new BuildException("'file' attribute must be defined");
        }
        if (filename != null && reference == null) {
            this.log("Dumping paths into file " + filename);
            try {
                OutputStreamWriter os = new OutputStreamWriter(
                        new FileOutputStream(filename), "UTF8");
                for (Iterator<Path> ipath = paths.iterator(); ipath.hasNext();) {
                    Path path = ipath.next();
                    String[] plist = path.list();
                    for (int i = 0; i < plist.length; i++) {
                        os.write(plist[i] + "\n");
                    }
                }
                os.close();
            } catch (Exception exc) {
                throw new BuildException(exc);
            }
        } else if (filename != null && reference != null) {
            this.log("Converting " + filename + " content into path.");
            try {
                Path path = new Path(getProject());
                BufferedReader is = new BufferedReader(new InputStreamReader(
                        new FileInputStream(filename), "UTF-8"));
                String line = null;
                while ((line = is.readLine()) != null) {
                    path.createPathElement().setPath(line);
                }
                this.log("Creating reference " + reference + ".");
                getProject().addReference(reference, path);
            } catch (Exception exc) {
                throw new BuildException(exc);
            }
        } else {
            new BuildException("The task is not configured properly.");
        }

    }
}
