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

package com.nokia.helium.scm.ant.taskdefs;

import java.util.Date;
import java.text.SimpleDateFormat;
import java.util.Iterator;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmRevision;
import org.apache.maven.scm.ChangeSet;
import org.apache.maven.scm.command.changelog.ChangeLogScmResult;
import org.apache.maven.scm.command.changelog.ChangeLogSet;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;

/**
 * Get change log within a date range i.e startDate and endDate; 
 * OR get change log of a number of days i.e numDays
 * OR get change log within a range of starVersion and endVersion
 * Parameters either startDate="20090317 18:49:31" endDate="20090318 24:49:31" datePattern="yyyyMMdd HH:mm:ss"
 * Or numDays='1'
 * Or startVersion="1" endVersion="2"
 * Add logOutput="xml" to output log in xml format
 * 
 * <pre>
 * &lt;hlm:scm verbose="false" scmUrl="scm:hg:${repo.dir}/changelog"&gt;
 *     &lt;hlm:changelog basedir="${repo.dir}/changelog" startVersion="1" endVersion="2"/&gt;
 *     &lt;hlm:changelog baseDir="${repo.dir}/changelog" numDays='1' /&gt;
 * &lt;/hlm:scm&gt;
 * </pre>
 *
 * @ant.type name="changelog" category="SCM"
 */
public class ChangelogAction extends BaseDirectoryScmAction {

    private String startDate;

    private String endDate;

    private String datePattern;

    private String logOutput;
    
    private int numDays;

    private String startVersion;

    private String endVersion;
    private String xmlproperty;


    /**
     * Start version
     * 
     * @ant.not-required
     */
    public void setStartVersion(String startVersion) {
        this.startVersion = startVersion;
    }

    /**
     * End version
     * 
     * @ant.not-required
     */
    public void setEndVersion(String endVersion) {
        this.endVersion = endVersion;
    }

    /**
     * Start date
     * 
     * @ant.not-required
     */
    public void setStartDate(String startDate) {
        this.startDate = startDate;
    }

    /**
     * End date
     * 
     * @ant.not-required
     */
    public void setEndDate(String endDate) {
        this.endDate = endDate;
    }

    /**
     * Number of days
     * 
     * @ant.not-required
     */
    public void setNumDays(int numDays) {
        this.numDays = numDays;
    }

    /**
     * Date pattern default is EEE MMM dd HH:mm:ss yyyy Z
     * 
     * @ant.not-required
     */
    public void setDatePattern(String datePattern) {
        this.datePattern = datePattern;
    }

    /**
     * Output pattern default is log output, to get xml output set logoutput=xml
     * 
     * @ant.not-required
     */    
    public void setLogOutput(String logOutput)
    {
        this.logOutput = logOutput;
    }
    
    /**
     * Output property for xml output of changeset list
     * 
     * @ant.not-required
     */ 
    public void setXMLProperty(String xmlproperty)
    {
        this.xmlproperty = xmlproperty;
    }

    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    @Override
    public void execute(ScmRepository repository) throws ScmException
    {
        ScmManager scmManager = getTask().getScmManager();
        ScmRevision startRevision = new ScmRevision(startVersion);
        ScmRevision endRevision = new ScmRevision(endVersion);

        ChangeLogScmResult result;
        Date start = null;
        Date end = null;

        if (numDays == 0 && (startDate != null || endDate != null) )
        {
            try {
                SimpleDateFormat format = new SimpleDateFormat(datePattern);
                start = format.parse(startDate);
                end = format.parse(endDate);
             }
             catch (Exception e)
             {
                 throw new BuildException("Date Format not supported jash:" + e.getMessage());
             }
         }
         else 
         {
             start = null;
             end = null;
         }
        try
        {
        if (startVersion == null)
            result = scmManager.changeLog(repository, getScmFileSet(), start, end, numDays, null, datePattern);
        else
            result = scmManager.changeLog(repository, getScmFileSet(), startRevision, endRevision, datePattern);
        } catch (ScmException e) {
            throw new BuildException(
                    "Execution of SCM changelog action failed.");
        }
        if (!result.isSuccess()) {
            throw new BuildException("SCM changelog command unsuccessful.");
        }
        // Output changelog information
        ChangeLogSet changelogSet = result.getChangeLog();
        if (logOutput != null && logOutput.equals("xml"))
        {
            getTask().log(changelogSet.toXML());
        }
        else if (xmlproperty != null)
        {
            String output = "";
            for (Object o : changelogSet.getChangeSets())
            {
                String revision = "";
                ChangeSet c = (ChangeSet)o;
                for (String x : c.toString().split("\n"))
                {
                    if (x.contains("revision:"))
                        revision = x.replace("revision:", "");
                }
                
                output = output + "<task><id>" + revision + "</id><synopsis>" + c.getComment() + "</synopsis><completed>" + new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss").format(c.getDate()) + "</completed></task>";
            }
            
            getProject().setProperty(xmlproperty, output);
        }
        else
        {
            Iterator iterator = changelogSet.getChangeSets().iterator();
            while (iterator.hasNext())
            {
                getTask().log(iterator.next().toString());
            }
        }
    }
}
