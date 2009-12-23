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
 
package com.nokia.ant.taskdefs;

import java.io.*;
import java.util.*;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.FileSet;
import org.apache.tools.ant.DirectoryScanner;

import java.util.jar.*;
import java.util.zip.ZipEntry;
import java.net.*;
import org.dom4j.io.SAXReader;
import org.dom4j.Document;
import org.dom4j.Element;

/**
 * Outputs a directed graph of Ant library dependencies, reads information from dependency jars
 */
public class AntDependencyTask extends Task
{
    private ArrayList antFileSetList = new ArrayList();
    private String outputFile;
    
    public AntDependencyTask()
    {
        setTaskName("AntDependencyTask");
    }
    
    /**
     * Add a set of files to copy.
     * @param set a set of files to AntDependencyTask.
     * @ant.required
     */
    public void addFileset(FileSet set) {
        antFileSetList.add(set);
    }
    
    /**
     * Location of graph file to output to
     * @ant.required
     */
    public void setOutputFile(String path)
    {
        outputFile = path;
    }
    
    public String classToJar(Class aclass)
    {
        String name = aclass.getName().replace(".", "/") + ".class";
      
        for (Iterator iterator = antFileSetList.iterator(); iterator.hasNext();)
        {
            FileSet fs = (FileSet) iterator.next();
            DirectoryScanner ds = fs.getDirectoryScanner(project);
            String[] srcFiles = ds.getIncludedFiles();
            String basedir = ds.getBasedir().getPath();
            //log(basedir);
            
            for (int i = 0; i < srcFiles.length; i++)
            {
                String fileName = basedir + File.separator + srcFiles[i];
                //log(fileName);
                try {
                    JarFile jar = new JarFile(fileName);
                    
                    //for (Enumeration e = jar.entries(); e.hasMoreElements() ;) {log(e.nextElement().toString()); }
                    
                    if (jar.getJarEntry(name) != null)
                        return fileName;
                }
                catch (IOException e) { 
                    // We are Ignoring the errors as no need to fail the build.
                    log(e.getMessage(), Project.MSG_DEBUG);
                }
            }
        }
        log(name + " not found", Project.MSG_DEBUG);
        return null;
    }
    
    public String getJarAttr(JarFile jar, String nameOfAttr)
    {
        try {
            String attr = jar.getManifest().getMainAttributes().getValue(nameOfAttr);
            if (attr != null)
                return attr;
        
            Manifest manifest = jar.getManifest();
            Map map = manifest.getEntries();
        
            for (Iterator it = map.keySet().iterator(); it.hasNext(); ) {
                String entryName = (String)it.next();
                Attributes attrs = (Attributes)map.get(entryName);
        
                for (Iterator it2 = attrs.keySet().iterator(); it2.hasNext(); )
                {
                    Attributes.Name attrName = (Attributes.Name)it2.next();
                        if (attrName.toString() == nameOfAttr)
                            return attrs.getValue(attrName).replace("\"", "");
                }
            }
        } catch (IOException e) {
            // We are Ignoring the errors as no need to fail the build.
            log("Not able to get the JAR file attribute information. " + e.getMessage(), Project.MSG_DEBUG);
        }
        return null;
    }
    
    public HashSet<String> getJarInfo()
    {
        HashSet<String> classlist = new HashSet<String>();
        
        for (Iterator iterator = antFileSetList.iterator(); iterator.hasNext();)
        {
            FileSet fs = (FileSet) iterator.next();
            DirectoryScanner ds = fs.getDirectoryScanner(project);
            String[] srcFiles = ds.getIncludedFiles();
            String basedir = ds.getBasedir().getPath();
            //log(basedir);
            
            for (int i = 0; i < srcFiles.length; i++)
            {
                String fileName = basedir + File.separator + srcFiles[i];
                //log(fileName);
                try {
                    JarFile jar = new JarFile(fileName);
                    
                    String vendor = getJarAttr(jar, "Implementation-Vendor");
                    String version = getJarAttr(jar, "Implementation-Version");
                    if (version == null)
                        version = getJarAttr(jar, "Specification-Version");
                    String name = convertJarName(fileName);
                    
                    //findLicense(srcFiles[i], jar);
                    
                    String nameandversion = name;
                    
                    if (version != null)
                    {
                        version = version.replace("$", "");
                        if (!digitInString(name))
                            nameandversion = name + " " + version;
                    }
                    if (vendor == null)
                        vendor = "";
                    classlist.add(name + " [style=filled,shape=record,label=\"" + nameandversion + "|" + vendor + "\"];");
                }
                catch (IOException e) { 
                    // We are Ignoring the errors as no need to fail the build.
                    e.printStackTrace(); 
                }
            }
        }

        return classlist;
    }
    
    public void findLicense(String name, JarFile jar)
    {
        try {
            ZipEntry entry = jar.getEntry("META-INF/LICENSE");
            if (entry == null)
                entry = jar.getEntry("META-INF/LICENSE.txt");
            if (entry != null)
            {
              /**/
                log("File in " + name + " in jar file ", Project.MSG_DEBUG);
                byte[] data = new byte[1024];
                jar.getInputStream(entry).read(data);
                for (String line : new String(data).split("\n"))
                {
                    if (line.contains("License") || line.contains("LICENSE ") || line.contains("Copyright"))
                    {
                        log("Replace License information with * " + line.replace("*", "").trim(), Project.MSG_INFO);
                        break;
                    }
                }
            }
            else
            {   
                //http://mirrors.ibiblio.org/pub/mirrors/maven2/
                String mavenUrl = "http://repo2.maven.org/maven2/";
                Enumeration jarfiles = jar.entries();
                boolean found = false;
                while (!found && jarfiles.hasMoreElements ()) {
                    ZipEntry file = (ZipEntry) jarfiles.nextElement();
                    if (file.isDirectory())
                    {   
                        String filename = file.getName();
                        String[] split = file.getName().split("/");
                        String end = split[split.length - 1];
                        String specialfilename = filename + end;
                        
                        URL url = new URL(mavenUrl + filename + end + "/maven-metadata.xml");
                        if (!end.equals("apache"))
                        {
                            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                            if (connection.getResponseCode() != HttpURLConnection.HTTP_OK)
                            {
                                filename = filename.replace(end, name.replace(".jar", ""));
                                end = name.replace(".jar", "");
                                specialfilename = filename;
                                url = new URL(mavenUrl + filename + "maven-metadata.xml");
                                connection = (HttpURLConnection) url.openConnection();
                            }
                            if (connection.getResponseCode() == HttpURLConnection.HTTP_OK)
                            {   
                                
                                SAXReader xmlReader = new SAXReader();
                                Document antDoc = xmlReader.read(url.openStream());
                                List versions = antDoc.selectNodes("//versioning/versions/version");
                                //if (version.equals(""))
                                //{
                                //    version = antDoc.valueOf("/metadata/version");
                                //}
                                Collections.reverse(versions);
                                for (Object tmpversion : versions)
                                {
                                    String version = ((Element)tmpversion).getText();
                                    URL url2 = new URL(mavenUrl + specialfilename + "/" + version + "/" + end + "-" + version + ".pom");
                                    HttpURLConnection connection2 = (HttpURLConnection) url2.openConnection();
                                    if (connection2.getResponseCode() == HttpURLConnection.HTTP_OK)
                                    {
                                        DataInputStream din = new DataInputStream(url2.openStream());
                                        StringBuffer sb = new StringBuffer();
                                        String line = null;
                                        while ((line = din.readLine()) != null) {
                                            line = line.replace("xmlns=\"http://maven.apache.org/POM/4.0.0\"", "");
                                            sb.append(line + "\n");
                                        }
                                        xmlReader = new SAXReader();
                                        //
                                        Document antDoc2 = xmlReader.read(new ByteArrayInputStream(new String(sb).getBytes()));
                                        String license = antDoc2.valueOf("/project/licenses/license/name");
                                        if (!license.equals(""))
                                        {
                                            found = true;
                                            break;
                                        }
                                            
                                    }
                                }
                            }
                        }
                    }   
                    
                }
                if (!found)
                    log(name + " not found in " + jar, Project.MSG_INFO);
            }
        }
        catch (Exception e) {
            // We are Ignoring the errors as no need to fail the build.
            e.printStackTrace(); 
        }
    }
    
    public boolean digitInString(String s) {
        int j = s.length() - 1;
        while (j >= 0 && Character.isDigit(s.charAt(j))) {
            return true;
        }
        return false;
    }

    
    public String convertJarName(String jar)
    {
        return new File(jar).getName().replace(".jar", "").replace("-", "_").replace(".", "_");
    }
    
    public final void execute()
    {
        try {
            Project project = getProject();
            
            Hashtable taskdefs = project.getTaskDefinitions();
            
            HashSet<String> classlist = new HashSet<String>();
            
            Enumeration taskdefsenum = taskdefs.keys();
            while (taskdefsenum.hasMoreElements ()) {
                String key = (String) taskdefsenum.nextElement();
                Class value = (Class) taskdefs.get(key);
                if (!key.contains("nokia") && !value.toString().contains("org.apache.tools.ant"))
                {
                    String name = value.getPackage().getName();
                    String vendor = value.getPackage().getImplementationVendor();
                    
                    name = classToJar(value);
                    
                    if (name != null)
                    {
                        name = convertJarName(name);
                      
                        classlist.add("helium_ant -> \"" + name + "\";");
                        
                        if (vendor == null)
                            vendor = "";
                        
                        classlist.add(name + " [style=filled,shape=record,label=\"" + name + "|" + vendor + "\"];");
                    }
                }
            }
            
            classlist.add("helium_ant -> nokia_ant;");
            
            classlist.addAll(getJarInfo());
        
            Writer output = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputFile), "UTF8"));
            
            for (String value : classlist)
                output.write(value + "\n");
            
            output.close();
        } catch (Exception e) {
            // We are Ignoring the errors as no need to fail the build.
            log("Exception occured while getting the ANT task dependency information. " + e.getMessage(), Project.MSG_DEBUG);
        }
    }

}