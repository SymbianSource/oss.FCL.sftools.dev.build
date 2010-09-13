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

package com.nokia.helium.diamonds;

import java.io.BufferedWriter;
import java.io.FileInputStream;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Calendar;
import java.util.Date;
import java.util.Vector;
import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.Target;

/**
 * Generate target times
 */
public class AllTargetDiamondsListener extends DiamondsListenerImpl {

    private static Logger log = Logger.getLogger(DiamondsListenerImpl.class);

    private Vector<AntTarget> antTargets = new Vector<AntTarget>();


    

    /**
     * Function to process logging info during begining of target execution
     * 
     * @param event of target execution.
     */
    public void targetBegin(BuildEvent buildEvent) {
        antTargets.add(new AntTarget(buildEvent.getTarget()));
    }

    /**
     * Function to process logging info during end of target execution
     * 
     * @param event of target execution.
     */
    public void targetEnd(BuildEvent buildEvent) {
        for (AntTarget at : antTargets)
        {
            if (at.equals(buildEvent.getTarget())) {
                at.setEndTime(new Date());
            }
        }
    }

    /**
     * Function to process logging info during end of build
     * 
     * @param event of target execution.
     */
    public void buildEnd(BuildEvent buildEvent) throws DiamondsException {
        try {
            if (isInitialized()) {
                File tempFile = File.createTempFile("diamonds-targets", ".xml");
                FileWriter fstream = new FileWriter(tempFile);
                BufferedWriter out = new BufferedWriter(fstream);
                out.write("<targets>\n");
                
                for (AntTarget at : antTargets)
                {
                    Calendar startcalendar = Calendar.getInstance();
                    Calendar endcalendar = Calendar.getInstance();
                    startcalendar.setTime(at.getStartTime());
                    if (at.getEndTime() != null)
                    {
                        endcalendar.setTime(at.getEndTime());
                        endcalendar.add(Calendar.SECOND, -5);
                        if (endcalendar.after(startcalendar))
                        {
                            out.write("<target>\n");
                            out.write("<name>" + at.getName() + "</name>\n");
                            out.write("<started>" + getTimeFormat().format(at.getStartTime()) + "</started>\n");
                            out.write("<finished>" + getTimeFormat().format(at.getEndTime()) + "</finished>\n");
                            out.write("</target>\n");
                        }
                    }
                }
                
                out.write("</targets>\n");
                out.close();
                FileInputStream stream = new FileInputStream(tempFile);
                log.debug("alltargetdiamondslistener file: " + tempFile);
                mergeToFullResults(stream);
                stream.close();
                stream = new FileInputStream(tempFile); 
                log.debug("diamondsclient: " + getDiamondsClient());
                log.debug("diamondsclient: " + DiamondsConfig.getBuildId());
                getDiamondsClient().sendData(stream, DiamondsConfig.getBuildId());
            }
        }
        catch (IOException e)
        {
            e.printStackTrace();
        }
    }
    
    class AntTarget {
        private String targetName;
        private Date startTime;
        private Date endTime;
        private int hashCode;
        
        public AntTarget(Target target)
        {
            targetName = target.getName();
            hashCode = target.hashCode();
            startTime = new Date();
        }
        public String getName() { return targetName; }
        public Date getStartTime() { return startTime; }
        public Date getEndTime() { return endTime; }
        public void setEndTime(Date e) { endTime = e; }
        public boolean equals(Object obj) { return obj.hashCode() == hashCode; }
        public int hashCode() { return hashCode; }
    }
}