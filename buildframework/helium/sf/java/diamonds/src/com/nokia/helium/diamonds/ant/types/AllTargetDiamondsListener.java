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

package com.nokia.helium.diamonds.ant.types;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Vector;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.types.FileMessage;
import com.nokia.helium.diamonds.DiamondsException;
import com.nokia.helium.diamonds.DiamondsListener;
import com.nokia.helium.diamonds.ant.Listener;

/**
 * The targetTimingMessageListener should be used as a reference in a build
 * file so the message listener can detect it an record target execution time 
 * before sending it.
 * 
 * <pre>
 *      &lt;hlm:targetTimingMessageListener id=&quot;target.time.message.listener&quot; /&gt;
 * </pre>
 * 
 * @ant.type name="targetTimingMessageListener" category="Diamonds"
 */
public class AllTargetDiamondsListener extends DataType implements DiamondsListener {

    private List<AntTarget> antTargets = new Vector<AntTarget>();
    private List<AntTarget> completedTargets = new Vector<AntTarget>();
    private Listener diamondsListener;
    private int minTime = 5000; // in ms
    
    /**
     * Function to process logging info during end of build
     * 
     * @param event of target execution.
     */
    class AntTarget {
        private String targetName;
        private Date startTime;
        private Date endTime;
        private int hashCode;
        
        public AntTarget(Target target) {
            targetName = target.getName();
            this.hashCode = target.hashCode();
            startTime = new Date();
        }
        
        public String getName() { return targetName; }
        public Date getStartTime() { return startTime; }
        public Date getEndTime() { return endTime; }
        public void setEndTime(Date e) { endTime = e; }
        public boolean equals(Object obj) { return obj.hashCode() == hashCode; }
        public int hashCode() { return hashCode; }
    }
    
    public synchronized void buildFinished(BuildEvent buildEvent) throws DiamondsException {
        try {
            SimpleDateFormat timeFormat = new SimpleDateFormat(diamondsListener.getConfiguration().getTimeFormat());
            File tempFile = File.createTempFile("diamonds-targets", ".xml");
            tempFile.deleteOnExit();
            BufferedWriter out = new BufferedWriter(new FileWriter(tempFile));
            out.write("<?xml version=\"1.0\" ?>\n");
            out.write("<diamonds-build>\n");
            out.write("<schema>24</schema>\n");
            out.write("<targets>\n");
            
            for (AntTarget at : completedTargets) {
                if (at.getEndTime() != null) {
                    out.write("<target>\n");
                    out.write("<name>" + at.getName() + "</name>\n");
                    out.write("<started>" + timeFormat.format(at.getStartTime()) + "</started>\n");
                    out.write("<finished>" + timeFormat.format(at.getEndTime()) + "</finished>\n");
                    out.write("</target>\n");
                }
            }
                
            out.write("</targets>\n");
            out.write("</diamonds-build>\n");
            out.close();
            FileMessage message = new FileMessage();
            message.setProject(getProject());
            message.setFile(tempFile);
            diamondsListener.getSession().send(message);
        } catch (IOException e) {
            throw new DiamondsException(e.getMessage(), e);
        }
    }

    public void buildStarted(BuildEvent buildEvent) throws DiamondsException {
    }

    public void configure(Listener listener) throws DiamondsException {
        diamondsListener = listener;        
    }

    public synchronized void targetFinished(BuildEvent buildEvent) throws DiamondsException {
        for (AntTarget at : antTargets) {
            if (at.equals(buildEvent.getTarget())) {
                at.setEndTime(new Date());
                if (at.getEndTime().getTime() - at.getStartTime().getTime() >= minTime) {
                    completedTargets.add(at);
                }
                antTargets.remove(at);
                break;
            }
        }
    }

    public synchronized void targetStarted(BuildEvent buildEvent) throws DiamondsException {
        antTargets.add(new AntTarget(buildEvent.getTarget()));
    }
    
    /**
     * Defines the minimum execution time for a target to be recorded. Time is in millisecond.
     * If set to 0 then all target are recorded. 
     * @param minTime
     * @ant.not-required Default is 5000ms
     */
    public void setMinTime(Integer minTime) {
        if (minTime.intValue() < 0) {
            throw new BuildException("Invalid value for minTime attribute: " +
                    minTime.intValue() + ", value must be >=0. At " + this.getLocation());
        }
        this.minTime = minTime.intValue();
    }
}