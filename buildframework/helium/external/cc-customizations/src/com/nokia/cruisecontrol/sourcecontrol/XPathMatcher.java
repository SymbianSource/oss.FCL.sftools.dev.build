/* ============================================================================ 
Name        : XPathMatcher.java
Part of     : Helium 

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.
This component and the accompanying materials are made available
under the terms of the License "Eclipse Public License v1.0"
which accompanies this distribution, and is available
at the URL "http://www.eclipse.org/legal/epl-v10.html".

Initial Contributors:
Nokia Corporation - initial contribution.

Contributors:

Description:

============================================================================ */
package com.nokia.cruisecontrol.sourcecontrol;

import net.sourceforge.cruisecontrol.CruiseControlException;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Vector;
import java.util.Map;
import org.apache.log4j.Logger;

public class XPathMatcher
{
    /**
     * An instance of the logging class
     */
    private static final Logger LOG = Logger.getLogger(XPathMatcher.class);

    private String expression;

    private String name = "";

    private Vector mappers = new Vector();


    public List getModifications(Date arg0, Date arg1)
    {
        return null;
    }

    public Map getProperties()
    {
        return null;
    }

    /**
     * Validate the input from the configuration. 
     * @throws CruiseControlException
     */
    public void validate() throws CruiseControlException
    {
        // Has expression been defined?
        if (expression == null)
            throw new CruiseControlException("'expression' attribute not defined.");
        for (Iterator i = mappers.iterator(); i.hasNext();)
        {
            XPathMapper mapper = (XPathMapper) i.next();
            mapper.validate();
        }
    }

    public void setName(String name)
    {
        this.name = name;
    }

    public String getName()
    {
        return name;
    }

    public void setExpression(String expression)
    {
        this.expression = expression;
    }

    public String getExpression()
    {
        return expression;
    }

    public Object createMap()
    {
        LOG.info("==== Creating a mapper object.");
        XPathMapper mapper = new XPathMapper();
        mappers.add(mapper);
        return mapper;
    }

    public XPathMapper getMapper(String name)
    {
        LOG.info("==== Get mapper: " + name);

        for (Iterator i = mappers.iterator(); i.hasNext();)
        {
            XPathMapper mapper = (XPathMapper) i.next();
            if (mapper.getName().equals(name))
                return mapper;
        }
        return null;
    }

    public boolean hasMapper(String name)
    {
        LOG.info("==== Has mapper: => " + name);
        return this.getMapper(name) != null;
    }

}
