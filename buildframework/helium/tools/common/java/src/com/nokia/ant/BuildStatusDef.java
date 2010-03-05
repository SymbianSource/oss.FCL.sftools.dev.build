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


import org.apache.tools.ant.Target;
import org.apache.tools.ant.Project;
import com.nokia.helium.core.ant.types.*;
import org.apache.tools.ant.BuildException;

import org.apache.log4j.Logger;

import java.util.Iterator;
import java.util.Hashtable;
import java.util.Vector;
import java.util.Enumeration;
import java.util.List;
import java.io.File;
import java.util.ArrayList;
import java.util.HashSet;

import org.dom4j.Document;
import org.dom4j.Node;
import org.dom4j.Comment;
import org.dom4j.Element;
import org.dom4j.io.SAXReader;
import org.dom4j.Visitor;
import org.dom4j.VisitorSupport;

/**
 * Class to store the status of the signal of a particular target.
 */
public class BuildStatusDef extends HlmPostDefImpl
{
    private Logger log;
    private HashSet<String> output = new HashSet<String>();
    
    public BuildStatusDef() {
        log = Logger.getLogger(BuildStatusDef.class);    
    }
    
    public void execute(Project prj, String module, String[] targetNames)
    {
        //Run after targets execute so dynamic target names are resolved
        for (int i = 0; i < targetNames.length; i++)
        {
            String[] array = { targetNames[i] };
            Target target = findTarget(targetNames[i], project, array);
            targetCallsHeliumTarget(target, project);
        }
        checkTargetsProperties(project);
        
        if (!output.isEmpty())
        {
            log("*** Configuration report ***", Project.MSG_INFO);
            for (String x : output)
                log(x, Project.MSG_INFO);
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
    public Target findTarget(String desiredTarget, Project project, String[] targetNames)
    {
        Hashtable targets;
        Vector sorted;
        Target t = new Target();
        boolean matchFound = false;

        // get all targets of the current project
        targets = project.getTargets();

        // sort all targets of the current project
        sorted = project.topoSort(targetNames[0], targets);

        // Find the desiredTarget Target object
        for (int i = 0; i < sorted.size(); i++)
        {
            t = (Target) sorted.get(i);
            if (t.getName().equals(desiredTarget))
            {
                matchFound = true;
                break;
            }
        }
        if (matchFound)
        {
            return t;
        }
        else
        {
            throw new BuildException("Could not find target matching " + desiredTarget + "\n");
        }
    }
    
     /**
     * If a target defined outside helium are calling a private Helium target then print warning
     * 
     */
    public void targetCallsHeliumTarget(Target target, Project project)
    {        
        String location = target.getLocation().getFileName();
        
        try {
        String heliumpath = new File(project.getProperty("helium.dir")).getCanonicalPath();
        String targetpath = new File(location).getCanonicalPath();
        
        if (!targetpath.contains(heliumpath))
        {   
            ArrayList antcallTargets = new ArrayList();
            Visitor visitorTarget = new AntTargetVisitor(antcallTargets, project);
            
            Element element = findTargetElement(target, project);
            if (element != null)
                element.accept(visitorTarget);
            for (Iterator iterator = antcallTargets.iterator(); iterator.hasNext();)
            {
                String depTargetString = (String) iterator.next();
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
            
          
            for (Enumeration e = target.getDependencies(); e.hasMoreElements();)
            {
                String depTargetString = (String) e.nextElement();
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

        } catch (Exception e) {
            //We are Ignoring the errors as no need to fail the build.
            log("Exception occured while target defined outside helium are calling a private Helium target " + e.getMessage(), Project.MSG_DEBUG);
            e.printStackTrace();
        }
    }

    private class AntTargetVisitor extends VisitorSupport
    {
        private List targetList;
        private Project project;

        public AntTargetVisitor(List targetList, Project project)
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
    public Element findTargetElement(Target target, Project project)
    {
        SAXReader xmlReader = new SAXReader();
        
        Document antDoc = null;
        
        String location = target.getLocation().getFileName();
        
        try {
        File file = new File(location);
        antDoc = xmlReader.read(file);
        } catch (Exception e) {
            // We are Ignoring the errors as no need to fail the build.
            log("Not able read the XML file. " + e.getMessage(), Project.MSG_WARN);
        }
          
        String projectName = antDoc.valueOf("/project/@name");
        for (Iterator iterator = antDoc.selectNodes("//target").iterator(); iterator.hasNext();)
        {
            Element e = (Element) iterator.next();

            String targetName = e.attributeValue("name");
            if (targetName.equals(target.getName()) || (projectName + "." + targetName).equals(target.getName()))
                return e;
        }
        return null;
    }
    
        /**
     * If target has comment that says it is private them print warning
     * 
     */
    public void checkIfTargetPrivate(Target target, Project project)
    { 
        Element targetElement = findTargetElement(target, project);
        if (targetElement != null)
        {
            List children = targetElement.selectNodes("preceding-sibling::node()");
            if (children.size() > 0)
            {
                // Scan past the text nodes, which are most likely whitespace
                int index = children.size() - 1;
                Node child = (Node) children.get(index);
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
    
    public void checkTargetsProperties(Project project)
    {
        if (project.getProperty("data.model.file") != null)
        {
            SAXReader xmlReader = new SAXReader();
            Document antDoc = null;
            
            ArrayList customerProps = getCustomerProperties(project);
            
            try {
            File model = new File(project.getProperty("data.model.file"));
            antDoc = xmlReader.read(model);
            } catch (Exception e) {
                // We are Ignoring the errors as no need to fail the build.
                log("Not able read the data model file. " + e.getMessage(), Project.MSG_WARN);
            }
            
            List<Node> statements = antDoc.selectNodes("//property");
            
            for (Node statement : statements)
            {
                if (statement.valueOf("editStatus").equals("never"))
                {
                    if (customerProps.contains(statement.valueOf("name")))
                    {
                        output.add("Warning: " + statement.valueOf("name") + " property has been overridden");
                    }
                }
            }
        }
    }
    
    public ArrayList getCustomerProperties(Project project)
    {
        ArrayList props = new ArrayList();
        Database db = new Database(null, null, null);
        try {
        String heliumpath = new File(project.getProperty("helium.dir")).getCanonicalPath();
        
        for (Object o : db.getAntFiles(project))
        {
            String antFile = (String)o;
            antFile = new File(antFile).getCanonicalPath();
            
            if (!antFile.contains(heliumpath))
            {
                SAXReader xmlReader = new SAXReader();
                Document antDoc = xmlReader.read(new File(antFile));
                
                List propertyNodes = antDoc.selectNodes("//property | //param");
                for (Iterator iterator = propertyNodes.iterator(); iterator.hasNext();)
                {
                    Element propertyNode = (Element) iterator.next();
                    String propertyName = propertyNode.attributeValue("name");
                    props.add(propertyName);
                }
            }
        }
        } catch (Exception e) {
            // We are Ignoring the errors as no need to fail the build.
            log("Not able read the Customer Properties " + e.getMessage(), Project.MSG_WARN);
        }
          
        return props;
    }
    
}