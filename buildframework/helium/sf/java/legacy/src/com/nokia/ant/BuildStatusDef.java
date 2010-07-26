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
 
package com.nokia.ant;


import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.dom4j.Comment;
import org.dom4j.Document;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.Visitor;
import org.dom4j.VisitorSupport;
import org.dom4j.io.SAXReader;
import org.dom4j.DocumentException;

import com.nokia.helium.core.ant.types.HlmPostDefImpl;

import com.nokia.helium.ant.data.PropertyMeta;


/**
 * Class to store the status of the signal of a particular target.
 */
public class BuildStatusDef extends HlmPostDefImpl
{
    private HashSet<String> output = new HashSet<String>();
        
    
    public void execute(Project prj, String module, String[] targetNames)
    {
        //Run after targets execute so dynamic target names are resolved
        for (int i = 0; i < targetNames.length; i++)
        {
            String[] array = { targetNames[i] };
            Target target = findTarget(targetNames[i], getProject(), array);
            targetCallsHeliumTarget(target, getProject());
        }
        checkTargetsProperties(getProject());
        
        if (!output.isEmpty())
        {
            log("*** Configuration report ***", Project.MSG_INFO);
            for (String outputStr : output)
                log(outputStr, Project.MSG_INFO);
        }
    }
    
        /**
     * @param desiredTarget
     *            Target name to search
     * @param project
     *            Object of the project
     * @param targetNames
     *            Array of target names
     * 
     */
    @SuppressWarnings("unchecked")
    public Target findTarget(String desiredTarget, Project project, String[] targetNames)
    {
        Hashtable<String, Target> targets;
        Vector<Target> sorted;

        // get all targets of the current project
        targets = project.getTargets();

        // sort all targets of the current project
        sorted = project.topoSort(targetNames[0], targets);

        // Find the desiredTarget Target object
        for (Target target : sorted)
        {
            if (target.getName().equals(desiredTarget))
            {
                return target;
            }
        }
        throw new BuildException("Could not find target matching " + desiredTarget + "\n");
    }
    
     /**
     * If a target defined outside helium are calling a private Helium target then print warning
     * 
     */
    @SuppressWarnings("unchecked")
    public void targetCallsHeliumTarget(Target target, Project project)
    {        
        String location = target.getLocation().getFileName();
        
        try {
            String heliumpath = new File(project.getProperty("helium.dir")).getCanonicalPath();
            String targetpath = new File(location).getCanonicalPath();
            
            if (!targetpath.contains(heliumpath))
            {   
                ArrayList<String> antcallTargets = new ArrayList<String>();
                Visitor visitorTarget = new AntTargetVisitor(antcallTargets, project);
                
                Element element = findTargetElement(target, project);
                if (element != null)
                    element.accept(visitorTarget);
                for (String depTargetString : antcallTargets)
                {
                    String[] array = { depTargetString };
                    try {
                    Target depTarget = findTarget(depTargetString, project, array);
                    targetCallsHeliumTarget(depTarget, project);
                    } catch (BuildException x) { 
                        // We are Ignoring the errors as no need to fail the build.
                        log("Exception occured while target defined outside helium are calling a private Helium target " + x.toString(), Project.MSG_DEBUG);
                        x = null;
                        }
                }
                
              
                for (Enumeration<String> depsEnum = target.getDependencies(); depsEnum.hasMoreElements();)
                {
                    String depTargetString = depsEnum.nextElement();
                    String[] array = { depTargetString };
                    try {
                    Target depTarget = findTarget(depTargetString, project, array);
                    targetCallsHeliumTarget(depTarget, project);
                    } catch (BuildException x) {
                        //We are Ignoring the errors as no need to fail the build.
                        log("Exception occured while target defined outside helium are calling a private Helium target " + x.toString(), Project.MSG_DEBUG);
                        x = null;
                        }
                }
            }
            else
            {
                checkIfTargetPrivate(target, project);
            }

        } catch (IOException e) {
            //We are Ignoring the errors as no need to fail the build.
            log("IOException occured while target defined outside helium are calling a private Helium target " + e.getMessage(), Project.MSG_DEBUG);
            e.printStackTrace();
        }
    }

    private class AntTargetVisitor extends VisitorSupport
    {
        private List<String> targetList;
        private Project project;

        public AntTargetVisitor(List<String> targetList, Project project)
        {
            this.targetList = targetList;
            this.project = project;
        }

        public void visit(Element node)
        {
            String name = node.getName();
            if (name.equals("antcall") || name.equals("runtarget"))
            {
                String text = node.attributeValue("target");
                extractTarget(text);
            }
        }

        private void extractTarget(String text)
        {
            String iText = project.replaceProperties(text);
            targetList.add(iText);
        }

    }

    /**
     * Find the xml Element for the target
     * 
     */      
    @SuppressWarnings("unchecked")
    public Element findTargetElement(Target target, Project project)
    {
        SAXReader xmlReader = new SAXReader();
        
        Document antDoc = null;
        
        String location = target.getLocation().getFileName();
        
        try {
            File file = new File(location);
            antDoc = xmlReader.read(file);
        } catch (DocumentException e) {
            // We are Ignoring the errors as no need to fail the build.
            log("Not able read the XML file. " + e.getMessage(), Project.MSG_WARN);
        }
          
        String projectName = antDoc.valueOf("/project/@name");
        for (Iterator<Element> iterator = antDoc.selectNodes("//target").iterator(); iterator.hasNext();)
        {
            Element element = iterator.next();

            String targetName = element.attributeValue("name");
            if (targetName.equals(target.getName()) || (projectName + "." + targetName).equals(target.getName()))
                return element;
        }
        return null;
    }
    
        /**
     * If target has comment that says it is private them print warning
     * 
     */
    @SuppressWarnings("unchecked")
    public void checkIfTargetPrivate(Target target, Project project)
    { 
        Element targetElement = findTargetElement(target, project);
        if (targetElement != null)
        {
            List<Node> children = targetElement.selectNodes("preceding-sibling::node()");
            if (children.size() > 0)
            {
                // Scan past the text nodes, which are most likely whitespace
                int index = children.size() - 1;
                Node child = children.get(index);
                while (index > 0 && child.getNodeType() == Node.TEXT_NODE)
                {
                    index--;
                    child = (Node) children.get(index);
                }
    
                // Check if there is a comment node
                String commentText = null;
                if (child.getNodeType() == Node.COMMENT_NODE)
                {
                    Comment macroComment = (Comment) child;
                    commentText = macroComment.getStringValue().trim();
                    //log(macroName + " comment: " + commentText, Project.MSG_DEBUG);
                }
    
                if (commentText != null)
                {
                    if (commentText.contains("Private:"))
                    {
                        output.add("Warning: " + target.getName() + " is private and should only be called by helium");
                    }
                    if (commentText.contains("<deprecated>"))
                    {
                        output.add("Warning: " + target.getName() + "\n" + commentText);
                    }
                }
            }
        }
    }
    
    @SuppressWarnings("unchecked")
    public void checkTargetsProperties(Project project)
    {
        try {
            String heliumpath = new File(project.getProperty("helium.dir")).getCanonicalPath();
            com.nokia.helium.ant.data.Database db = new com.nokia.helium.ant.data.Database(project, "private");
            ArrayList<String> customerProps = getCustomerProperties(project);
                            
            for (PropertyMeta propertyMeta : db.getProperties())
            {
                if (propertyMeta.getLocation().contains(heliumpath) && propertyMeta.getScope().equals("private") && customerProps.contains(propertyMeta.getName()))
                {
                    output.add("Warning: " +  propertyMeta.getName() + " property has been overridden");
                }
            }
        } catch (IOException e) { e.printStackTrace(); }
    }
    
    @SuppressWarnings("unchecked")
    public ArrayList<String> getCustomerProperties(Project project)
    {
        ArrayList<String> props = new ArrayList<String>();
        Database db = new Database(null, null, null);
        try {
            String heliumpath = new File(project.getProperty("helium.dir")).getCanonicalPath();

            for (Object object : db.getAntFiles(project))
            {
                String antFile = (String)object;
                antFile = new File(antFile).getCanonicalPath();

                if (!antFile.contains(heliumpath))
                {
                    SAXReader xmlReader = new SAXReader();
                    Document antDoc = xmlReader.read(new File(antFile));
                    
                    List<Element> propertyNodes = antDoc.selectNodes("//property | //param");
                    for (Element propertyNode : propertyNodes)
                    {
                        props.add(propertyNode.attributeValue("name"));
                    }
                }
            }
        } catch (IOException e) {
            // We are Ignoring the errors as no need to fail the build.
            log("IOException: Not able read the Customer Properties " + e.getMessage(), Project.MSG_WARN);
        } catch (DocumentException e) {
            // We are Ignoring the errors as no need to fail the build.
            log("DocumentException: Not able read the Customer Properties " + e.getMessage(), Project.MSG_WARN);
        }
          
        return props;
    }
    
}