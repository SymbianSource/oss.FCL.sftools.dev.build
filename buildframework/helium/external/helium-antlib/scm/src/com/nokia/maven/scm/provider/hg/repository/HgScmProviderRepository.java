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
package com.nokia.maven.scm.provider.hg.repository;

import java.net.URL;

/**
 * Custom implementation use to patch official hg implementation. It uses the
 * URL class for the URL parsing rather than using custom parsing.
 */
public class HgScmProviderRepository extends
        org.apache.maven.scm.provider.hg.repository.HgScmProviderRepository {
    private URL orgUrl;
    private String url;

    /**
     * Default constructor.
     */
    public HgScmProviderRepository(String url) {
        super(url);
        this.url = url;
    }

    /**
     * This method is used to do the actual repository settings.
     * 
     * @param url
     *            the url which points to the repo.
     */
    public void configure(URL url) {
        orgUrl = url;
        setHost(url.getHost());
        if (url.getUserInfo() != null) {
            String[] info = url.getUserInfo().split(":");
            if (info.length == 2) {
                setUser(info[0]);
                setPassword(info[1]);
            }
        }
        if (url.getPort() != -1) {
            setPort(url.getPort());
        }
    }

    public String getURI() {
        return (orgUrl != null) ? orgUrl.toString() : url;
    }

    /**
     * @return A message if the repository as an invalid URI, null if the URI
     *         seems fine.
     */
    public String validateURI() {
        return null;
    }

    /** {@inheritDoc} */
    public String toString() {
        if (orgUrl != null) {
            return "Hg Repository Interpreted from: " + orgUrl + ":\nProtocol: "
                + orgUrl.getProtocol() + "\nHost: " + getHost() + "\nPort: "
                + getPort() + "\nUsername: " + getUser() + "\nPassword: "
                + getPassword() + "\nPath: " + orgUrl.getPath();
        }
        return "Hg Repository Interpreted from: " + url;
    }
}
