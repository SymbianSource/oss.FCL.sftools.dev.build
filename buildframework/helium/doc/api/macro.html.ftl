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
<#list doc['antDatabase/*/macro'] as macro>
<@pp.changeOutputFile name="macro-${macro.name}.html" />

<@helium_api_header title="Macro ${macro.name}"/>



<h2>Macro ${macro.name}</h2>

<b>Scope: </b>${macro.scope}<br/>

<p><b>Description</b></p>
<p>${macro.description}</p>

<p><b>Location</b></p>
<p><@helium_api_location_path location="${macro.location}"/></p>

<hr/>

<h3>Documentation</h3>
<p>
<#recurse macro.documentation>
</p>
<p/>

<p>Example: <pre>${macro.usage}</pre></p>

<hr/>

<h3>Source code</h3>
<pre>
    ${macro.source?html}
</pre>
   
<@helium_api_html_footer/>

</#list>


