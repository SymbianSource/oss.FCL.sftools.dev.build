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

import com.nokia.helium.core.EmailSendException;
import com.nokia.helium.core.PropertiesSource;
import com.nokia.helium.core.TemplateInputSource;
import com.nokia.helium.signal.ant.Notifier;
import com.nokia.helium.core.TemplateProcessor;
import com.nokia.helium.core.ant.ResourceCollectionUtils;

import java.util.List;
import java.util.Hashtable;
import java.util.ArrayList;
import java.io.IOException;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.ResourceCollection;

import java.io.File;

/**
 * The emailNotifier provides you an easy way to send a you and email containing
 * the summary of a build failure.
 * 
 * @ant.type name="emailNotifier" category="Signaling"
 */
public class EMAILNotifier extends DataType implements Notifier {

    private TemplateProcessor templateProcessor = new TemplateProcessor();
    private File defaultTemplate;
    private String title;
    private String smtp;
    private String ldap;
    private String rootdn;
    private String notifyWhen = "never";
    private String from;
    private String additionalRecipients;

    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public void sendData(String signalName, boolean failStatus,
            ResourceCollection notifierInput, String message) {
        if (notifyWhen != null
                && (notifyWhen.equals("always")
                        || (notifyWhen.equals("fail") && failStatus) || (notifyWhen
                        .equals("pass") && !failStatus))) {
            if (title == null) {
                throw new BuildException(
                        "The 'title' attribute has not been defined.");
            }

            if (smtp == null) {
                throw new BuildException(
                        "The 'smtp' attribute has not been defined.");
            }

            if (ldap == null && from == null) {
                throw new BuildException(
                        "The 'ldap' attribute has not been defined.");
            }
            EmailDataSender emailSender = createEmailDataSender();

            Project subProject = getProject().createSubProject();
            subProject.setProperty("signal.name", signalName);
            subProject.setProperty("signal.status", "" + failStatus);
            subProject.setProperty("signal.message", "" + message);
            try {
                
                File fileToSend = null;
                if (notifierInput != null) {
                    fileToSend = ResourceCollectionUtils.getFile(notifierInput, ".*.html");
                }
                if (fileToSend == null) {
                    if (defaultTemplate != null && defaultTemplate.exists()) {
                        File emailOutputFile;
                        try {
                            emailOutputFile = File.createTempFile("helium_",
                                    "email.html");
                            emailOutputFile.deleteOnExit();
                            log("sending data by e-mail:outputDir: "
                                    + emailOutputFile.getAbsolutePath(), Project.MSG_DEBUG);

                            List<TemplateInputSource> sourceList = new ArrayList<TemplateInputSource>();
                            sourceList.add(new PropertiesSource("ant",
                                    getProject().getProperties()));
                            Hashtable<String, String> signalProperties = new Hashtable<String, String>();
                            signalProperties.put("signal.name", signalName);
                            signalProperties.put("signal.status", ""
                                    + failStatus);
                            signalProperties
                                    .put("signal.message", "" + message);
                            sourceList.add(new PropertiesSource("signaling",
                                    signalProperties));

                            templateProcessor.convertTemplate(defaultTemplate,
                                    emailOutputFile, sourceList);
                            fileToSend = emailOutputFile;
                        } catch (IOException e) {
                            log("EmailNotifier: IOexception: " + e.getMessage(), Project.MSG_DEBUG);
                        }
                    } else {
                        if (defaultTemplate == null) {
                            log("The 'defaultTemplate' has not been defined.",
                                    Project.MSG_WARN);
                        } else if (!defaultTemplate.exists()) {
                            log("Could not find default template: "
                                    + defaultTemplate.getAbsolutePath(),
                                    Project.MSG_WARN);
                        }
                    }
                }
                emailSender.sendData("signaling", fileToSend, "application/html",
                        subProject.replaceProperties(title), null);
            } catch (EmailSendException ese) {
                log(this.getDataTypeName() + " Warning: " + ese.getMessage(), Project.MSG_WARN);
            }
        }
    }

    /**
     * Create an EmailDataSender base on this type settings.
     * @return
     */
    private EmailDataSender createEmailDataSender() {
        String smtpUpdated = getProject().replaceProperties(smtp);
        String ldapUpdated = getProject().replaceProperties(ldap);
        String additionalRecipientsUpdated = getProject()
                .replaceProperties(additionalRecipients);

        log("Sending data by e-mail.", Project.MSG_DEBUG);
        EmailDataSender emailSender;
        if (additionalRecipientsUpdated == null) { 
            additionalRecipientsUpdated = from;
        } else {
            additionalRecipientsUpdated += (from != null) ? (additionalRecipientsUpdated.length() > 0 ? "," : "") + from : "";
        }
        if (rootdn != null) {
            String[] to = null;
            if (additionalRecipientsUpdated != null) {
                to = additionalRecipientsUpdated.split(",");
            }
            emailSender = new EmailDataSender(to, smtpUpdated, ldapUpdated,
                    getProject().replaceProperties(rootdn));
        } else {
            emailSender = new EmailDataSender(additionalRecipientsUpdated,
                    smtpUpdated, ldapUpdated);
        }
        if (from == null) {
            try {
                emailSender.addCurrentUserToAddressList();
            } catch (EmailSendException ex) {
                // Consider the error as a warning, let's try to send the email anyway
                log(this.getDataTypeName() + " Warning: " + ex.getMessage(), Project.MSG_WARN);
            }
        }
        if (from != null) {
            log("Setting from: " + from);
            emailSender.setFrom(from);
        }
        log("EmailNotifier:arlist: " + additionalRecipientsUpdated, Project.MSG_DEBUG);
        return emailSender;
    }
    
    /**
     * Set when the notifier should emit the massage. Possible values are:
     * never, always, fail, pass.
     * 
     * @ant.not-required Default is never.
     */
    public void setNotifyWhen(NotifyWhenEnum notifyWhen) {
        this.notifyWhen = notifyWhen.getValue();
    }

    /**
     * When do we need to notify the user?
     * 
     * @return
     */
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
     * 
     * @deprecated
     * @ant.required
     */
    @Deprecated
    public void setTemplateSrc(File template) {
        log(
                "The usage of the templateSrc attribute is deprecated,"
                        + " please consider using the defaultTemplate attribute instead.",
                Project.MSG_ERR);
        this.defaultTemplate = template;
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
     * @ant.required (or from attribute can be used)
     */
    public void setLdap(String ldap) {
        this.ldap = ldap;
    }

    /**
     * The LDAP rootdn.
     * @param rootdn
     * @ant.required
     */
    public void setRootdn(String rootdn) {
        this.rootdn = rootdn;
    }

}
