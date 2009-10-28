//========================================================================
//$Id: WebAppDeployer.java 2032 2007-07-26 06:11:24Z janb $
//Copyright 2006 Mort Bay Consulting Pty. Ltd.
//------------------------------------------------------------------------
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at 
//http://www.apache.org/licenses/LICENSE-2.0
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.
//========================================================================
/* 
 ============================================================================ 
 Name        : WebAppDeployer.java
 Part of     : Helium 

 Portion Copyright (c) 2007-2008 Nokia Corporation and/or its subsidiary(-ies). All rights reserved.

 ============================================================================
 */

package com.nokia.jetty.deployer;

import java.util.ArrayList;

import org.apache.log4j.Logger;
import org.mortbay.component.AbstractLifeCycle;
import org.mortbay.jetty.Handler;
import org.mortbay.jetty.HandlerContainer;
import org.mortbay.jetty.handler.ContextHandler;
import org.mortbay.jetty.handler.ContextHandlerCollection;
import org.mortbay.jetty.webapp.WebAppContext;
import org.mortbay.resource.Resource;
import org.mortbay.util.URIUtil;

/**
 * Web Application Deployer.
 * 
 * The class searches a directory for and deploys standard web application. At
 * startup, the directory specified by {@link #setWebAppDir(String)} is searched
 * for subdirectories (excluding hidden and CVS) or files ending with ".zip" or
 * "*.war". For each webapp discovered is passed to a new instance of
 * {@link WebAppContext} (or a subclass specified by {@link #getContexts()}.
 * {@link ContextHandlerCollection#getContextClass()}
 * 
 * This deployer does not do hot deployment or undeployment. Nor does it support
 * per webapplication configuration. For these features see
 * {@link ContextDeployer}.
 * 
 * @see {@link ContextDeployer}
 */
public class WebAppDeployer extends AbstractLifeCycle
{
    private Logger log = Logger.getLogger(this.getClass());

    private HandlerContainer contexts;

    private String webAppDir;

    private String defaultsDescriptor;

    private String[] configurationClasses;

    private boolean extract;

    private boolean parentLoaderPriority;

    private boolean allowDuplicates;

    private ArrayList<WebAppContext> deployed;

    private String extraClasspath;

    public String[] getConfigurationClasses()
    {
        return configurationClasses;
    }

    public void setConfigurationClasses(String[] configurationClasses)
    {
        this.configurationClasses = configurationClasses;
    }

    public HandlerContainer getContexts()
    {
        return contexts;
    }

    public void setContexts(HandlerContainer contexts)
    {
        this.contexts = contexts;
    }

    public String getDefaultsDescriptor()
    {
        return defaultsDescriptor;
    }

    public void setDefaultsDescriptor(String defaultsDescriptor)
    {
        this.defaultsDescriptor = defaultsDescriptor;
    }

    public boolean isExtract()
    {
        return extract;
    }

    public void setExtract(boolean extract)
    {
        this.extract = extract;
    }

    public boolean isParentLoaderPriority()
    {
        return parentLoaderPriority;
    }

    public void setParentLoaderPriority(boolean parentPriorityClassLoading)
    {
        parentLoaderPriority = parentPriorityClassLoading;
    }

    public String getWebAppDir()
    {
        return webAppDir;
    }

    public void setWebAppDir(String dir)
    {
        this.webAppDir = dir;
    }

    public boolean getAllowDuplicates()
    {
        return allowDuplicates;
    }

    public void setExtraClasspath(String extraClasspath)
    {
        this.extraClasspath = extraClasspath;
    }

    public String getExtraClasspath()
    {
        return extraClasspath;
    }

    /* ------------------------------------------------------------ */
    /**
     * @param allowDuplicates
     *            If false, do not deploy webapps that have already been
     *            deployed or duplicate context path
     */
    public void setAllowDuplicates(boolean allowDuplicates)
    {
        this.allowDuplicates = allowDuplicates;
    }

    /* ------------------------------------------------------------ */
    /**
     * @throws Exception
     */
    public void doStart() throws Exception
    {
        deployed = new ArrayList<WebAppContext>();

        scan();

    }

    /* ------------------------------------------------------------ */
    /**
     * Scan for webapplications.
     * 
     * @throws Exception
     */
    public void scan() throws Exception
    {
        if (contexts == null)
            throw new IllegalArgumentException("No HandlerContainer");

        Resource r = Resource.newResource(this.webAppDir);
        if (!r.exists())
            throw new IllegalArgumentException("No such webapps resource " + r);

        if (!r.isDirectory())
            throw new IllegalArgumentException("Not directory webapps resource " + r);

        String[] files = r.list();

        files: for (int f = 0; files != null && f < files.length; f++)
        {
            String context = files[f];

            if (context.equalsIgnoreCase("CVS/") || context.equalsIgnoreCase("CVS")
                    || context.startsWith("."))
                continue;

            Resource app = r.addPath(r.encode(context));

            if (context.toLowerCase().endsWith(".war") || context.toLowerCase().endsWith(".jar"))
            {
                context = context.substring(0, context.length() - 4);
                Resource unpacked = r.addPath(context);
                if (unpacked != null && unpacked.exists() && unpacked.isDirectory())
                    continue;
            }
            else if (!app.isDirectory())
                continue;

            if (context.equalsIgnoreCase("root") || context.equalsIgnoreCase("root/"))
                context = URIUtil.SLASH;
            else
                context = "/" + context;
            if (context.endsWith("/") && context.length() > 0)
                context = context.substring(0, context.length() - 1);

            // Check the context path has not already been added or the webapp
            // itself is not already deployed
            if (!allowDuplicates)
            {
                Handler[] installed = contexts.getChildHandlersByClass(ContextHandler.class);
                for (int i = 0; i < installed.length; i++)
                {
                    ContextHandler c = (ContextHandler) installed[i];

                    if (context.equals(c.getContextPath()))
                        continue files;

                    String path;
                    if (c instanceof WebAppContext)
                        path = ((WebAppContext) c).getWar();
                    else
                        path = (c.getBaseResource() == null) ? "" : c.getBaseResource().getFile()
                                .getAbsolutePath();

                    if (path.equals(app.getFile().getAbsolutePath()))
                        continue files;

                }
            }

            // create a webapp
            WebAppContext wah = null;
            if (contexts instanceof ContextHandlerCollection
                    && WebAppContext.class.isAssignableFrom(((ContextHandlerCollection) contexts)
                            .getContextClass()))
            {
                try
                {
                    wah = (WebAppContext) ((ContextHandlerCollection) contexts).getContextClass()
                            .newInstance();
                }
                catch (Exception e)
                {
                    throw new Error(e);
                }
            }
            else
            {
                wah = new WebAppContext();
            }

            // configure it
            wah.setContextPath(context);
            if (configurationClasses != null)
                wah.setConfigurationClasses(configurationClasses);
            if (defaultsDescriptor != null)
                wah.setDefaultsDescriptor(defaultsDescriptor);
            wah.setExtractWAR(extract);
            wah.setWar(app.toString());
            wah.setParentLoaderPriority(parentLoaderPriority);
            log.info("Adding additional path to the WebAppContext");
            if (extraClasspath != null)
            {
                log.info("Adding additional path to the WebAppContext: " + extraClasspath);
                System.out.println("Adding additional path to the WebAppContext: "
                        + extraClasspath);
                wah.setExtraClasspath(extraClasspath);
            }
            // add it
            contexts.addHandler(wah);
            deployed.add(wah);

            if (contexts.isStarted())
                contexts.start(); // TODO Multi exception
        }
    }

    public void doStop() throws Exception
    {
        for (int i = deployed.size(); i-- > 0;)
        {
            ContextHandler wac = (ContextHandler) deployed.get(i);
            wac.stop();// TODO Multi exception
        }
    }
}
