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


package com.nokia.helium.core;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import freemarker.template.ObjectWrapper;
import freemarker.template.SimpleCollection;
import freemarker.template.SimpleScalar;
import freemarker.template.TemplateCollectionModel;
import freemarker.template.TemplateHashModelEx;
import freemarker.template.TemplateModel;
import fmpp.Engine;
import fmpp.models.AddTransform;
import fmpp.models.ClearTransform;
import fmpp.models.CopyWritableVariableMethod;
import fmpp.models.NewWritableHashMethod;
import fmpp.models.NewWritableSequenceMethod;
import fmpp.models.RemoveTransform;
import fmpp.models.SetTransform;

/**
 * Downgraded implementation which makes the PPHash public (from FMPP).
 */
public class PPHash implements TemplateHashModelEx {
    private Map<String, TemplateModel> map = new HashMap<String, TemplateModel>();

    /**
    * Constructor
    *     
    */
    public PPHash() {
        // transforms
        put("set", new SetTransform());
        put("add", new AddTransform());
        put("remove", new RemoveTransform());
        put("clear", new ClearTransform());

        // methods
        put("newWritableSequence", new NewWritableSequenceMethod());
        put("newWritableHash", new NewWritableHashMethod());
        put("copyWritable", new CopyWritableVariableMethod());

        // constants
        put("slash", File.separator);
        put("version", Engine.getVersionNumber());
        put("freemarkerVersion", Engine.getFreeMarkerVersionNumber());

    }
    /**
    * Get number of templates.
    * 
    * @return
    *       Number of templates.
    */
    public int size() {
        return map.size();
    }

    /**
    * Get templates.
    * 
    * @return
    *       templates.
    */
    public TemplateCollectionModel keys() {
        return new SimpleCollection(map.keySet(), ObjectWrapper.SIMPLE_WRAPPER);
    }
    
    /**
    * Get template values.
    * 
    * @return
    *       template values.
    */
    public TemplateCollectionModel values() {
        return new SimpleCollection(map.values(), ObjectWrapper.SIMPLE_WRAPPER);
    }

    /**
    * Get a template.
    * 
    * @param String
    *            key for template
    * @return
    *       a template.
    */
    public TemplateModel get(String key) {
        return map.get(key);
    }

     /**
    * Check if there are any template.
    * 
    * @return
    *       True if no template.
    */
    public boolean isEmpty() {
        return map.isEmpty();
    }
     /**
    * Add template
    *     
    * @param String
    *            name of template
    * @param TemplateModel
    *            value
    */
    public void put(String name, TemplateModel value) {
        map.put(name, value);
    }
     /**
    * Add template
    *     
    * @param String
    *            name of template
    * @param String
    *            value
    */
    public void put(String name, String value) {
        map.put(name, new SimpleScalar(value));
    }

     /**
    * Delete template
    *     
    * @param String
    *            name of template
    */
    public void remove(String name) {
        map.remove(name);
    }
}
