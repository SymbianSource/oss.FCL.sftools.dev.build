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

package com.nokia.helium.freemarker;

import info.bliki.wiki.model.WikiModel;

import java.util.List;

import freemarker.template.TemplateMethodModel;
import freemarker.template.TemplateModelException;

/**
 * A FreeMarker method for converting the given text argument into HTML. The
 * text is assumed to be in MediaWiki format. 
 */
public class WikiMethod implements TemplateMethodModel {

    @SuppressWarnings("unchecked")
    public Object exec(List args) throws TemplateModelException {
        String text = (String) args.get(0);
        WikiModel wikiModel = new WikiModel("", "");
        if (!text.contains("</pre>") && (text.contains("**") || text.contains("==") || text.contains("- -"))) {
            text = text.replace("**", "").replace("==", "").replace("- -", "").trim();
            // log("Warning: Comment code has invalid syntax: " + text,
            // Project.MSG_WARN);
        }
        if (text.startsWith("-")) {
            text = text.replace("-", "");
        }
        
        text = text.trim();
        text = wikiModel.render(text);
        return text;
    }
}
