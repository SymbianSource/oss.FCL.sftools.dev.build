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
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;
import java.util.Map;

import org.apache.ivy.core.IvyPatternHelper;
import org.apache.ivy.core.module.descriptor.Artifact;
import org.apache.ivy.core.module.descriptor.DefaultArtifact;
import org.apache.ivy.core.module.descriptor.DependencyDescriptor;
import org.apache.ivy.core.module.descriptor.ModuleDescriptor;
import org.apache.ivy.core.module.id.ModuleRevisionId;
import org.apache.ivy.core.resolve.ResolveData;
import org.apache.ivy.core.settings.IvyPattern;
import org.apache.ivy.plugins.latest.LatestStrategy;
import org.apache.ivy.plugins.repository.BasicResource;
import org.apache.ivy.plugins.repository.Resource;
import org.apache.ivy.plugins.resolver.BasicResolver;
import org.apache.ivy.plugins.resolver.util.MDResolvedResource;
import org.apache.ivy.plugins.resolver.util.ResolvedResource;
import org.apache.ivy.plugins.resolver.util.ResourceMDParser;
import org.apache.ivy.plugins.version.VersionMatcher;
import org.apache.ivy.util.Message;


/**
 * Ivy plugin to read tool versions
 */
public class ToolResolver extends BasicResolver
{

    private static final Map<String, String> IVY_ARTIFACT_ATTRIBUTES = new HashMap<String, String>();
    static {
        IVY_ARTIFACT_ATTRIBUTES.put(IvyPatternHelper.ARTIFACT_KEY, "ivy");
        IVY_ARTIFACT_ATTRIBUTES.put(IvyPatternHelper.TYPE_KEY, "ivy");
        IVY_ARTIFACT_ATTRIBUTES.put(IvyPatternHelper.EXT_KEY, "xml");
    }
    
    private List<String> ivyPatterns = new ArrayList<String>(); // List (String pattern)
    private List<String> artifactPatterns = new ArrayList<String>();  // List (String pattern)
    private boolean m2compatible;

    
    public ResolvedResource findIvyFileRef(DependencyDescriptor dd, ResolveData data) {
        ModuleRevisionId mrid = dd.getDependencyRevisionId();
        if (isM2compatible()) {
            mrid = convertM2IdForResourceSearch(mrid);
        }
        return findResourceUsingPatterns(mrid, ivyPatterns, DefaultArtifact.newIvyArtifact(mrid, data.getDate()), getRMDParser(dd, data), data.getDate());
    }

    protected ResolvedResource findArtifactRef(Artifact artifact, Date date) {
        ModuleRevisionId mrid = artifact.getModuleRevisionId();
        if (isM2compatible()) {
            mrid = convertM2IdForResourceSearch(mrid);
        }
        return findResourceUsingPatterns(mrid, artifactPatterns, artifact, getDefaultRMDParser(artifact.getModuleRevisionId().getModuleId()), date);
    }

    @SuppressWarnings("unchecked")
    protected ResolvedResource findResourceUsingPatterns(ModuleRevisionId moduleRevision, List patternList, Artifact artifact, ResourceMDParser rmdparser, Date date) {
        ResolvedResource rres = null;
        
        List<ResolvedResource> resolvedResources = new ArrayList<ResolvedResource>();
        boolean dynamic = getSettings().getVersionMatcher().isDynamic(moduleRevision);
        boolean stop = false;
        for (Iterator iter = patternList.iterator(); iter.hasNext() && !stop;) {
            String pattern = (String)iter.next();
            rres = findResourceUsingPattern(moduleRevision, pattern, artifact, rmdparser, date);
            if (rres != null) {
                resolvedResources.add(rres);
                stop = !dynamic; // stop iterating if we are not searching a dynamic revision
            }
        }
        
        if (resolvedResources.size() > 1) {
            ResolvedResource[] rress = (ResolvedResource[]) resolvedResources.toArray(new ResolvedResource[resolvedResources.size()]);
            rres = findResource(rress, getName(), getLatestStrategy(), getSettings().getVersionMatcher(), rmdparser, moduleRevision, date);
        }
        
        return rres;
    }
    
    @SuppressWarnings("unchecked")
    public ResolvedResource findResource(
            ResolvedResource[] rress, 
            String name,
            LatestStrategy strategy, 
            VersionMatcher versionMatcher, 
            ResourceMDParser rmdparser,
            ModuleRevisionId mrid, 
            Date date) {
        ResolvedResource found = null;
        List sorted = strategy.sort(rress);
        List rejected = new ArrayList();
        for (ListIterator iter = sorted.listIterator(sorted.size()); iter.hasPrevious();) {
            ResolvedResource rres = (ResolvedResource) iter.previous();
            if (date != null && rres.getLastModified() > date.getTime()) {
                Message.verbose("\t" + name + ": too young: " + rres);
                rejected.add(rres.getRevision() + " (" + rres.getLastModified() + ")");
                continue;
            }
            ModuleRevisionId foundMrid = ModuleRevisionId.newInstance(mrid, rres.getRevision());
            if (!versionMatcher.accept(mrid, foundMrid)) {
                Message.debug("\t" + name + ": rejected by version matcher: " + rres);
                rejected.add(rres.getRevision());
                continue;
            }
            if (versionMatcher.needModuleDescriptor(mrid, foundMrid)) {
                ResolvedResource resolvedResource = rmdparser.parse(rres.getResource(), rres.getRevision());
                ModuleDescriptor md = ((MDResolvedResource)resolvedResource).getResolvedModuleRevision().getDescriptor();
                if (md.isDefault()) {
                    Message.debug("\t" + name + ": default md rejected by version matcher requiring module descriptor: " + rres);
                    rejected.add(rres.getRevision() + " (MD)");
                    continue;
                } else if (!versionMatcher.accept(mrid, md)) {
                    Message.debug("\t" + name + ": md rejected by version matcher: " + rres);
                    rejected.add(rres.getRevision() + " (MD)");
                    continue;
                } else {
                    found = resolvedResource;
                }
            } else {
                found = rres;
            }
            
            if (found != null) {
                if (!found.getResource().exists()) {
                    Message.debug("\t" + name + ": resource not reachable for " + mrid + ": res=" + found.getResource());
                    logAttempt(found.getResource().toString());
                    continue; 
                }
                break;
            }
        }
        if (found == null && !rejected.isEmpty()) {
            logAttempt(rejected.toString());
        }
        
        return found;
    }

    @SuppressWarnings("unchecked")
    protected Collection findNames(Map tokenValues, String token) {
        Collection names = new HashSet();
        names.addAll(findIvyNames(tokenValues, token));
        if (isAllownomd()) {
            names.addAll(findArtifactNames(tokenValues, token));
        }
        return names;
    }

    protected Collection<String> findIvyNames(Map<String, String> tokenValues, String token) {
        Collection<String> names = new HashSet<String>();
        tokenValues = new HashMap<String, String>(tokenValues);
        tokenValues.put(IvyPatternHelper.ARTIFACT_KEY, "ivy");
        tokenValues.put(IvyPatternHelper.TYPE_KEY, "ivy");
        tokenValues.put(IvyPatternHelper.EXT_KEY, "xml");
        findTokenValues(names, getIvyPatterns(), tokenValues, token);
        getSettings().filterIgnore(names);
        return names;
    }
    
    protected Collection<String> findArtifactNames(Map<String, String> tokenValues, String token) {
        Collection<String> names = new HashSet<String>();
        tokenValues = new HashMap<String, String>(tokenValues);
        tokenValues.put(IvyPatternHelper.ARTIFACT_KEY, tokenValues.get(IvyPatternHelper.MODULE_KEY));
        tokenValues.put(IvyPatternHelper.TYPE_KEY, "jar");
        tokenValues.put(IvyPatternHelper.EXT_KEY, "jar");
        findTokenValues(names, getArtifactPatterns(), tokenValues, token);
        getSettings().filterIgnore(names);
        return names;
    }

    // should be overridden by subclasses wanting to have listing features
    protected void findTokenValues(Collection<String> names, List<String> patterns, Map<String, String> tokenValues, String token) {
    }
    /**
     * example of pattern : ~/Workspace/[module]/[module].ivy.xml
     * @param pattern
     */
    public void addIvyPattern(String pattern) {
        ivyPatterns.add(pattern);
    }

    public void addArtifactPattern(String pattern) {
        artifactPatterns.add(pattern);
    }
    
    public List<String> getIvyPatterns() {
        return Collections.unmodifiableList(ivyPatterns);
    }

    public List<String> getArtifactPatterns() {
        return Collections.unmodifiableList(artifactPatterns);
    }
    protected void setIvyPatterns(List<String> ivyPatterns) {
        this.ivyPatterns = ivyPatterns;
    }
    protected void setArtifactPatterns(List<String> artifactPatterns) {
        this.artifactPatterns = artifactPatterns;
    }

    /*
     * Methods respecting ivy conf method specifications
     */
    public void addConfiguredIvy(IvyPattern p) {
        ivyPatterns.add(p.getPattern());
    }

    public void addConfiguredArtifact(IvyPattern p) {
        artifactPatterns.add(p.getPattern());
    }
    
    public void dumpSettings() {
        super.dumpSettings();
        Message.debug("\t\tm2compatible: " + isM2compatible());
        Message.debug("\t\tivy patterns:");
        for (ListIterator iter = getIvyPatterns().listIterator(); iter.hasNext();) {
            String pattern = (String)iter.next();
            Message.debug("\t\t\t" + pattern);
        }
        Message.debug("\t\tartifact patterns:");
        for (ListIterator iter = getArtifactPatterns().listIterator(); iter.hasNext();) {
            String pattern = (String)iter.next();
            Message.debug("\t\t\t" + pattern);
        }
    }

    public boolean isM2compatible() {
        return m2compatible;
    }

    public void setM2compatible(boolean m2compatible) {
        this.m2compatible = m2compatible;
    }

    protected ModuleRevisionId convertM2IdForResourceSearch(ModuleRevisionId mrid) {
        if (mrid.getOrganisation().indexOf('.') == -1) {
            return mrid;
        }
        return ModuleRevisionId.newInstance(mrid.getOrganisation().replace('.', '/'), mrid.getName(), mrid.getBranch(), mrid.getRevision(), mrid.getExtraAttributes());
    }

        

    public void publish(Artifact artifact, File src, boolean overwrite) throws IOException
    {
        Message.verbose("ToolResolver.publish() start");
    }
    
    private static File findExecutableOnPath(String executableName) {
        String systemPath = System.getenv("PATH");
        String[] pathDirs = systemPath.split(File.pathSeparator);
        String[] extensions = {""};
        
        // Using PATHEXT to get the supported extenstions on windows platform
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
                Message.verbose("Testing: " + file.getAbsolutePath());
                if (file.isFile()) {
                    return file;
                }
            }
            for (String pathDir : pathDirs) {
                file = new File(pathDir, checkName);
                Message.verbose("Testing: " + file.getAbsolutePath());
                if (file.isFile()) {
                    return file;
                }
            }
        }
        return null;
    }
    
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
            File executable = findExecutableOnPath(artifact.getName());
            if (executable == null) {
                return null;
            }
            Message.verbose("executable: " + executable.getAbsolutePath());
            String versionText = getToolVersion(executable, artifact.getAttribute("versionArgs"));
            Message.verbose(versionText);
            
            if (versionText.contains(toolVersion) || versionText.matches(artifact.getAttribute("versionExp")))
            {
                BasicResource resource = new BasicResource(executable.getAbsolutePath(), true, 0, 0, true);
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
    
    private String getToolVersion(File executable, String versionArgs) throws IOException
    {
        Runtime runtime = Runtime.getRuntime();
        Message.verbose("'" + executable.getAbsolutePath() + " " + versionArgs + "'");
        //Process toolProcess = runtime.exec(toolName+ "." + toolType + " " + versionArgs);
        Process toolProcess = runtime.exec(executable.getAbsolutePath() + " " + versionArgs);
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

    @Override
    protected Resource getResource(String arg0) throws IOException {
        // TODO Auto-generated method stub
        return null;
    }

}


