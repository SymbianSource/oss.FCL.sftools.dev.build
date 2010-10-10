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
package com.nokia.helium.logger.ant.types;

import java.io.File;

import org.apache.tools.ant.types.DataType;

import com.nokia.helium.logger.ant.listener.CommonListenerRegister;
import com.nokia.helium.logger.ant.listener.StageSummaryHandler;
import com.nokia.helium.logger.ant.listener.CommonListener;

/**
 * <code>StageSummary</code> is a Data type when set a build summary is 
 * displayed at the end of build process.
 * 
 * <pre>
 * Usage:
 *       &lt;hlm:stagesummary id=&quot;stage.summary&quot; 
 *          template=&quot;${template.dir}\build_stages_summary.txt.ftl&quot;/&gt;
 * </pre>
 * 
 * @ant.task name="stagesummary" category="Logging"
 * 
 */
public class StageSummary extends DataType implements CommonListenerRegister {

    private File template;
    
    /**
     * Get the template used for displaying build stage summary.
     * 
     * @return the template to display build stage summary.
     */
    public File getTemplate() {
        return template;
    }

    /**
     * Set the template to be used for displaying build stage summary.
     * 
     * @param template
     *            the template to set
     * @ant.required           
     */
    public void setTemplate( File template ) {
        this.template = template;
    }

    @Override
    public void register(CommonListener commonListener) {
        if (commonListener.getHandler(StageSummaryHandler.class) != null) {
            log("Only one stageSummary configuration element should be used. Ignoring type at " + this.getLocation());
        } else {
            commonListener.register(new StageSummaryHandler(getTemplate()));
        }
    }
}
