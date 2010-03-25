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
package com.nokia.helium.antlint.checks;

import java.io.File;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import com.nokia.helium.antlint.AntLintHandler;

/**
 * <code>CheckIndentation</code> is used to check the indentations in the ant files.
 *
 */
public class CheckIndentation extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(String antFileName) {
        try {
            SAXParserFactory saxFactory = SAXParserFactory.newInstance();
            saxFactory.setNamespaceAware(true);
            saxFactory.setValidating(true);
            SAXParser parser = saxFactory.newSAXParser();
            AntLintHandler handler = new AntLintHandler(this);
            handler.setIndentationCheck(true);
            parser.parse(new File(antFileName), handler);
        } catch (Exception e) {
            throw new RuntimeException(e);
        } 
    }
}
