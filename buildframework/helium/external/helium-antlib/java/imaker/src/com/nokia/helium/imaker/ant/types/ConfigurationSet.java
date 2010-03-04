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
 
package com.nokia.helium.imaker.ant.types;

import org.apache.tools.ant.types.DataType;

import com.nokia.helium.imaker.IMaker;
import com.nokia.helium.imaker.ant.Command;
import com.nokia.helium.imaker.ant.IMakerCommandSet;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

/**
 * Set of iMaker configuration.
 *
 * <pre>
 * &lt;hlm:imakerconfigurationset&gt;
 *     &lt;imakerconfiguration regionalVariation="true"&gt;
 *         &lt;makefileset&gt;
 *             &lt;include name="*&#42;/product/*ui.mk"/&gt;
 *         &lt;/makefileset&gt;
 *         &lt;targetset&gt;
 *             &lt;include name="^core$" /&gt;
 *             &lt;include name="langpack_\d+" /&gt;
 *             &lt;include name="^custvariant_.*$" /&gt;
 *             &lt;include name="^udaerase$" /&gt;
 *         &lt;/targetset&gt;
 *         &lt;variableset&gt;
 *             &lt;variable name="USE_FOTI" value="0"/&gt;
 *             &lt;variable name="USE_FOTA" value="1"/&gt;
 *         &lt;/variableset&gt;
 *         &lt;variablegroup&gt;
 *             &lt;variable name="TYPE" value="rnd"/&gt;
 *             &lt;variable name="USE_FOTI" value="0"/&gt;
 *             &lt;variable name="USE_FOTA" value="1"/&gt;
 *         &lt;/variablegroup&gt;
 *         &lt;variablegroup&gt;
 *             &lt;variable name="TYPE" value="subcon"/&gt;
 *             &lt;variable name="USE_FOTI" value="0"/&gt;
 *             &lt;variable name="USE_FOTA" value="1"/&gt;
 *         &lt;/variablegroup&gt;
 *     &lt;/imakerconfiguration&gt;
 * &lt;/hlm:imakerconfigurationset&gt;
 * </pre>
 * @ant.type name="imakerconfigurationset" category="imaker"
 */
public class ConfigurationSet extends DataType implements IMakerCommandSet {

    private Vector<Configuration> configurations = new Vector<Configuration>();

    /**
     * This method create an iMaker Configuration element. 
     */
    public Configuration createImakerConfiguration() {
        Configuration config = new Configuration();
        configurations.add(config);
        return config;
    }

    /**
     * Get the list of iMaker configuration. 
     */
    public Vector<Configuration> getImakerConfiguration() {
        return configurations;
    }

    @Override
    public List<List<Command>> getCommands(IMaker imaker) {
        List<List<Command>> cmdset = new ArrayList<List<Command>>();
        for (Configuration config : configurations) {
            if (config.isReference()) {
                config = (Configuration) config.getRefid().getReferencedObject();
            }
            cmdset.addAll(config.getCommands(imaker));
        }
        return cmdset;
    }
}
