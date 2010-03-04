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

package com.nokia.helium.signal.ant.types;

import com.nokia.helium.core.EmailDataSender;
import java.util.Iterator;
import com.nokia.helium.core.PropertiesSource;
import com.nokia.helium.core.TemplateInputSource;
import com.nokia.helium.core.XMLTemplateSource;
import com.nokia.helium.signal.Notifier;
import com.nokia.helium.signal.ant.SignalListener;
import com.nokia.helium.core.TemplateProcessor;
import com.nokia.helium.core.HlmAntLibException;
import java.util.List;
import java.util.Hashtable;
import java.util.ArrayList;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;
import org.apache.log4j.Logger;
import java.io.File;

/**
 * The emailNotifier provides you an easy way to send a you and email containing
 * the summary of a build failure.
 * 
 * @ant.type name="emailNotifier" category="Signaling"
 */
public class EMAILNotifier extends DataType implements Notifier {

    private Logger log = Logger.getLogger(EmailDataSender.class);
    private TemplateProcessor templateProcessor = new TemplateProcessor();
    private File defaultTemplate;
    private File templateSrc; // Deprecated    
    private String title;
    private String smtp;
    private String ldap;
    private String rootdn;
    private String notifyWhen = "never";
    private String from;
    private String additionalRecipients;

    /**
     * Rendering the template, and sending the result through email.
     * @deprecated
     * @param signalName
     *            - Name of the signal that has been raised.
     */
    @SuppressWarnings("unchecked")
    public void sendData(String signalName, boolean failStatus,
            List<String> fileList) {
        if (notifyWhen != null
                && (notifyWhen.equals("always") || (notifyWhen.equals("fail") && failStatus)
                        || (notifyWhen.equals("pass") && !failStatus))) {
            if (templateSrc == null) {
                throw new HlmAntLibException(SignalListener.MODULE_NAME,
                        "templateSrc attribute has not been defined.");
            }

            if (title == null) {
                throw new HlmAntLibException(SignalListener.MODULE_NAME,
                        "title attribute has not been defined.");
            }

            if (smtp == null) {
                throw new HlmAntLibException(SignalListener.MODULE_NAME,
                        "smtp attribute has not been defined.");
            }

            if (ldap == null) {
                throw new HlmAntLibException(SignalListener.MODULE_NAME,
                        "ldap attribute has not been defined.");
            }

            log.debug("Sending data by e-mail.");
            File emailOutputFile;
            try {
                emailOutputFile = File.createTempFile("helium_", "email.html");
                emailOutputFile.deleteOnExit();
                log.debug("sending data by e-mail:outputDir: "
                        + emailOutputFile.getAbsolutePath());

                List<TemplateInputSource> sourceList = new ArrayList<TemplateInputSource>();
                sourceList.add(new PropertiesSource("ant", getProject()
                        .getProperties()));
                Iterator iter = fileList.iterator();
                String sourceBaseName = "doc";
                int count = 0;
                while (iter.hasNext()) {
                    String srcFile = (String) iter.next();
                    sourceList.add(new XMLTemplateSource(sourceBaseName + count, 
                            new File(srcFile)));
                    count++;
                }
                Hashtable<String, String> signalProperties = new Hashtable<String, String>();
                signalProperties.put("signal.name", signalName);
                signalProperties.put("signal.status", "" + failStatus);
                sourceList.add(new PropertiesSource("signaling",
                        signalProperties));

                templateProcessor.convertTemplate(templateSrc, emailOutputFile,
                        sourceList);
                EmailDataSender emailSender;
                if (rootdn != null)
                {
                    String[] to = null;
                    if (additionalRecipients != null)
                    {
                        to = additionalRecipients.split(",");
                    }
                    emailSender = new EmailDataSender(to, smtp, ldap, rootdn);
                }
                else
                {
                    emailSender = new EmailDataSender(
                        additionalRecipients, smtp, ldap);
                }
                if (from != null)
                {
                    emailSender.setFrom(from);
                }
                log.debug("EmailNotifier:arlist: " + additionalRecipients);
                Project subProject = getProject().createSubProject();
                subProject.setProperty("signal.name", signalName);
                subProject.setProperty("signal.status", "" + failStatus);
                emailSender.addCurrentUserToAddressList();
                emailSender.sendData("signaling", emailOutputFile
                        .getAbsolutePath(), "application/html", subProject
                        .replaceProperties(title), null);
            } catch (Exception e) {
                log.debug("EmailNotifier:exception: ", e);
            }
        }
    }
            
    
    /**
     * Rendering the template, and sending the result through email.
     * 
     * @param signalName - is the name of the signal that has been raised.
     * @param failStatus - indicates whether to fail the build or not
     * @param notifierInput - contains signal notifier info
     * @param message - is the message from the signal that has been raised. 
     */

    @SuppressWarnings("unchecked")
    public void sendData(String signalName, boolean failStatus,
            NotifierInput notifierInput, String message ) {
        if (notifyWhen != null
                && (notifyWhen.equals("always") || (notifyWhen.equals("fail") && failStatus)
                        || (notifyWhen.equals("pass") && !failStatus))) {
            if (title == null) {
                throw new HlmAntLibException(SignalListener.MODULE_NAME,
                        "title attribute has not been defined.");
            }

            if (smtp == null) {
                throw new HlmAntLibException(SignalListener.MODULE_NAME,
                        "smtp attribute has not been defined.");
            }

            if (ldap == null) {
                throw new HlmAntLibException(SignalListener.MODULE_NAME,
                        "ldap attribute has not been defined.");
            }
            
            String smtpUpdated = getProject().replaceProperties(smtp);
            String ldapUpdated = getProject().replaceProperties(ldap);
            String rootdnUpdated = getProject().replaceProperties(rootdn);
            String additionalRecipientsUpdated = getProject().replaceProperties(additionalRecipients);

            log.debug("Sending data by e-mail.");
                EmailDataSender emailSender;
                if (rootdnUpdated != null)
                {
                    String[] to = null;
                    if (additionalRecipientsUpdated != null)
                    {
                        to = additionalRecipientsUpdated.split(",");
                    }
                    emailSender = new EmailDataSender(to, smtpUpdated, ldapUpdated, rootdnUpdated);
                }
                else
                {
                    emailSender = new EmailDataSender(
                        additionalRecipientsUpdated, smtpUpdated, ldapUpdated);
                }
                if (from != null)
                {
                    emailSender.setFrom(from);
                }
                log.debug("EmailNotifier:arlist: " + additionalRecipientsUpdated);
                Project subProject = getProject().createSubProject();
                subProject.setProperty("signal.name", signalName);
                subProject.setProperty("signal.status", "" + failStatus);
                subProject.setProperty("signal.message", "" + message);
                
                emailSender.addCurrentUserToAddressList();
                String filePath = "";
                File fileToSend = null;
                if (notifierInput != null) {
                    fileToSend = notifierInput.getFile(".*.html");
                    if (fileToSend != null) {
                        filePath = fileToSend.toString();
                    }
                    
                } 
                if (fileToSend == null) {
                    File emailOutputFile;
                    try {
                        emailOutputFile = File.createTempFile("helium_", "email.html");
                        emailOutputFile.deleteOnExit();
                        log.debug("sending data by e-mail:outputDir: "
                                + emailOutputFile.getAbsolutePath());

                        List<TemplateInputSource> sourceList = new ArrayList<TemplateInputSource>();
                        sourceList.add(new PropertiesSource("ant", getProject()
                                .getProperties()));
                        Hashtable<String, String> signalProperties = new Hashtable<String, String>();
                        signalProperties.put("signal.name", signalName);
                        signalProperties.put("signal.status", "" + failStatus);
                        signalProperties.put("signal.message", "" + message);
                        sourceList.add(new PropertiesSource("signaling",
                                signalProperties));

                        templateProcessor.convertTemplate(defaultTemplate, emailOutputFile,
                                sourceList);
                        filePath = emailOutputFile.toString();
                    } catch (Exception e) {
                        log.debug("EmailNotifier:exception: ", e);
                    }
                }
                emailSender.sendData("signaling", filePath, 
                        "application/html", subProject
                        .replaceProperties(title), null);
        }
    }

    /**
     * Set when the notifier should emit the massage. Possible values are: never, always, fail, pass.
     * @ant.not-required Default is never.
     */
    public void setNotifyWhen(String ntfyWhen) {
        notifyWhen = ntfyWhen;
    }

    public String getNotifyWhen() {
        return notifyWhen;
    }

    /**
     * Define the template source file to use while rendering the message.
     * 
     * @ant.required
     */
    public void setDefaultTemplate(File template) {
        this.defaultTemplate = template;
    }

    /**
     * Define the template source file to use while rendering the message.
     * @deprecated
     * @ant.required
     */
    public void setTemplateSrc(File template) {
        this.templateSrc = template;
    }
    
    /**
     * The title of the email.
     * 
     * @ant.required
     */
    public void setTitle(String title) {
        this.title = title;
    }

    /**
     * The STMP server address.
     * 
     * @ant.required
     */
    public void setSmtp(String smtp) {
        this.smtp = smtp;
    }
    
    /**
     * Who the email is sent from.
     * 
     * @ant.not-required
     */
    public void setFrom(String from) {
        this.from = from;
    }

    /**
     * Comma separated list of additional email addresses.
     * 
     * @ant.not-required
     */
    public void setAdditionalRecipients(String ar) {
        this.additionalRecipients = ar;
    }

    /**
     * The LDAP server URL.
     * 
     * @ant.required
     */
    public void setLdap(String ldap) {
        this.ldap = ldap;
    }
    
    public void setRootdn(String rootdn) {
        this.rootdn = rootdn;
    }

}
