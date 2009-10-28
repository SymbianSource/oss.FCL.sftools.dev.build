/* 
============================================================================ 
Name        : XPathMapper.java 
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

============================================================================
 */
package com.nokia.cruisecontrol.sourcecontrol;

import java.util.List;
import net.sourceforge.cruisecontrol.CruiseControlException;
import org.jdom.*;
import org.jdom.xpath.*;
import org.apache.log4j.Logger;

public class XPathMapper
{
    private static final Logger LOG = Logger.getLogger(XPathMapper.class);

    private String expression;

    private String value;

    private String name = "";


    /**
     * Validating the configuration input. 
     * @throws CruiseControlException
     */
    public void validate() throws CruiseControlException
    {
        // Has expression been defined?
        if (name == null)
            throw new CruiseControlException("'expression' attribute not defined.");
        if (expression == null && value == null)
            throw new CruiseControlException(
                    "Either 'expression' or 'value' attribute must be defined.");
        if (value != null && expression != null)
            throw new CruiseControlException(
                    "You can define both attributes 'expression' and 'value'.");
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

    public void setValue(String value)
    {
        this.value = value;
    }

    public String getValue()
    {
        return value;
    }

    public String extract(Object element) throws CruiseControlException
    {
        if (value != null)
            return value;

        try
        {
            List nodes = (List) XPath.selectNodes(element, this.getExpression());
            if (nodes.size() > 1)
                throw new CruiseControlException("'" + this.getExpression()
                        + "' returns several results.");
            if (nodes.size() < 1)
                throw new CruiseControlException("'" + this.getExpression()
                        + "' does not return any result.");

            Attribute attr = (Attribute) nodes.get(0);
            return attr.getValue();
        }
        catch (org.jdom.JDOMException exc)
        {
            throw new CruiseControlException("Could not extract data using '"
                    + this.getExpression() + "' " + exc);
        }
    }
}