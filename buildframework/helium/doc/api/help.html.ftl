<#--
============================================================================ 
Name        : 
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
-->
<#include "api.ftllib"/>

<@helium_api_header title="Helium API Help"/>

    <center>
    <h1>
    How This API Document Is Organized
    </h1>
    
    </center>
    
    This API document describes the Helium user API (Application Programming Interface) in terms of its Ant targets, properties and other configuration. It has pages corresponding to the items in the navigation bar, described as follows:
    
    <h3>Project</h3>
    
    A project corresponds to an Apache Ant XML file. Each project contains a number of targets.
    
    <h3>Target</h3>
    
    Each target has its own page listing the following sections:
    <ul>
    <li>Location</li>
    <li>Description</li>
    <li>Property dependencies. A list of Ant properties that this target uses and their edit status requirements.</li>
    <li>Target dependencies. A list of other targets that will be called before or during this target execution.</li>
    </ul>
    
    Target dependencies legend:
    <ul>
    <li>Blue arrows point to direct dependencies.</li>
    <li>Green arrows point to antcall and runtarget dependencies.</li>
    </ul>
    
    <p align="center">
    <img src="target-example.dot.png" usemap="#target-example"
         style="border-style: none"/>
    <map name="target-example" id="target-example">
        <#include "target-example.dot.cmap"/>
    </map>
    </p>

    <h3>Property Group</h3>
    A list of Property groups that group together related configuration elements, their usage requirements within that group and their edit status requirements..    
    
    <h3>Property</h3>
    Each property has its own page listing the following sections:
    <ul>
    <li>Description</li>
    <li>Usage</li>
    <li>Type</li>
    <li>Edit Status : The values could be must, recommended, allowed, discouraged or never.</li>
    </ul>    
    <h3></h3>
    <h3></h3>


<@helium_api_html_footer/>