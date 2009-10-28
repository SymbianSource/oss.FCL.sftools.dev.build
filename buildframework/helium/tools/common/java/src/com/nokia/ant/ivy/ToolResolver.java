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
 
package com.nokia.ivy;

import java.io.*;
import java.util.Date;

import org.apache.ivy.core.module.descriptor.Artifact;
import org.apache.ivy.core.module.id.ModuleRevisionId;
import org.apache.ivy.plugins.repository.BasicResource;
import org.apache.ivy.plugins.repository.Resource;
import org.apache.ivy.plugins.resolver.AbstractResourceResolver;
import org.apache.ivy.plugins.resolver.util.ResolvedResource;
import org.apache.ivy.plugins.resolver.util.ResourceMDParser;
import org.apache.ivy.util.Message;


/**
 * Ivy plugin to read tool versions
 */
public class ToolResolver extends AbstractResourceResolver
{


//    private List ivyPatterns = new ArrayList(); // List (String pattern)
//
//    private List artifactPatterns = new ArrayList(); // List (String pattern)
//
//    public void addConfiguredIvy(IvyPattern p)
//    {
//        ivyPatterns.add(p.getPattern());
//    }
//
//    public void addConfiguredArtifact(IvyPattern p)
//    {
//        artifactPatterns.add(p.getPattern());
//    }

//    public DownloadReport download(Artifact[] artifacts, DownloadOptions options)
//    {
//        // TODO Auto-generated method stub
//        Message.verbose("ToolResolver.download() start");
//        return null;
//    }

//    public ResolvedResource findIvyFileRef(DependencyDescriptor dd, ResolveData data)
//    {
//        // TODO Auto-generated method stub
//        Message.verbose("ToolResolver.findIvyFileRef() start");
//        return null;
//    }

//    public ResolvedModuleRevision getDependency(DependencyDescriptor depDescriptor, ResolveData data)
//            throws ParseException
//    {
//        // TODO Auto-generated method stub
//        Message.verbose("ToolResolver.getDependency() start: " + depDescriptor.getDependencyId().getName());
//        
//        Map attributes = depDescriptor.getAttributes();
//        Iterator entriesIter = attributes.entrySet().iterator();
//        for (; entriesIter.hasNext();)
//        {
//            Map.Entry entry = (Map.Entry) entriesIter.next();
//            System.out.println(entry.getKey() + ", " + entry.getValue());
//        }
//        
//        return null;
//    }

    public void publish(Artifact artifact, File src, boolean overwrite) throws IOException
    {
        // TODO Auto-generated method stub
        Message.verbose("ToolResolver.publish() start");

    }
    
    @Override
    protected ResolvedResource findResourceUsingPattern(ModuleRevisionId mrid, String pattern,
            Artifact artifact, ResourceMDParser rmdparser, Date date)
    {
        Message.verbose("ToolResolver.findResourceUsingPattern() start");
        
        Message.verbose(artifact.getName());
        Message.verbose(mrid.getRevision());
        Message.verbose(artifact.getAttribute("versionArgs"));

        String toolVersion = mrid.getRevision();
        ResolvedResource resolvedResource = null;
        try
        {
            String versionText = getToolVersion(artifact);
            Message.verbose(versionText);
            
            if (versionText.contains(toolVersion) || versionText.matches(artifact.getAttribute("versionExp")))
            {
                BasicResource resource = new BasicResource(artifact.getName(), true, 0, 0, true);
                resolvedResource = new ResolvedResource(resource, toolVersion);
            }
        }
        catch (IOException e)
        {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        return resolvedResource;
    }

    @Override
    protected long get(Resource resource, File dest) throws IOException
    {
        Message.verbose("ToolResolver.get() start");
        return 0;
    }
    
    private String getToolVersion(Artifact artifact) throws IOException
    {
        String toolName = artifact.getName();
        String toolType = artifact.getType();
        String versionArgs = artifact.getAttribute("versionArgs");
        Runtime runtime = Runtime.getRuntime();
        Message.verbose("'" + toolName + " " + versionArgs + "'");
        //Process toolProcess = runtime.exec(toolName+ "." + toolType + " " + versionArgs);
        Process toolProcess = runtime.exec(toolName + " " + versionArgs);
        InputStream in = toolProcess.getInputStream();
        InputStream err = toolProcess.getErrorStream();
        String outText = toString(in).trim();
        String errText = toString(err).trim();
        Message.verbose("err: " + errText);
        return outText + errText;
    }
    
    private String toString(InputStream inputStream) throws IOException
    {
        byte[] buffer = new byte[4096];
        OutputStream outputStream = new ByteArrayOutputStream();
         
        while (true) {
            int read = inputStream.read(buffer);
         
            if (read == -1) {
                break;
            }
         
            outputStream.write(buffer, 0, read);
        }
         
        outputStream.close();
        inputStream.close();
         
        return outputStream.toString();
    }

}


