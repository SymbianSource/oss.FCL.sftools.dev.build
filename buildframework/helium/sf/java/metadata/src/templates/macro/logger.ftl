<#--
============================================================================ 
Name        : logger.ftl 
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

<#macro helium_logger_html_head>
    <style type="text/css">
        <#include "log3.css"/>
    </style>
    <script type="text/javascript">
        <#include "expand3.js"/>
    </script>
</#macro>


<#global helium_node_id = 0>


<#macro helium_logger_header title subtitle="">
    <div id="h_wrapper">
        <div class="h_elmt">
              <div class="h_title">${title}</div>
              <div class="h_subtitle">${subtitle}</div>
        </div>
      </div>
</#macro>


<!-- Renders a main body of content -->
<#macro helium_logger_content title>
    <#assign helium_node_id = helium_node_id + 1>
    <div id="mb">
        <div class="mc">
            <h1>${title}</h1>                                   
            <div class="node_head"></div>
                <div id="Content${helium_node_id}">
                    <div class="node_content">
                        <#nested>
                    </div>
                </div>      
            </div>      
        </div>      
    </div>
</#macro>


<#macro helium_logger_print type>
    <#if type == "">
        <code><#nested></code><br/>
    <#else>
        <code class="code_${type}"><#nested></code><br/>
    </#if>
</#macro>

<#macro helium_message_box nodeid type count>
    <#if (count > 0)>
        <a href="javascript:ToggleNode('Img${nodeid}')">
            <span class="node_${type}">
                <span class="count_${type}">${count} ${type}s</span>
            </span>
        </a>
    </#if>
</#macro>

<#macro helium_logger_node_head nodeid title>
    <div class="node_head">                    
        <a href="javascript:ToggleNode('Img${nodeid}')">
            <span id="Img${nodeid}">
                <span class="node_action">[X]</span><span class="node_title">${title}</span>
            </span>
        </a>
        <a href="javascript:ShowChilds('Img${nodeid}')">
                <span class="node_action">[Show All]</span>
        </a>
        <a href="javascript:HideChilds('Img${nodeid}')">
                <span class="node_action">[Hide All]</span>
        </a>        
        <!-- error reporting managenent -->
        <#nested>
    </div>
</#macro>


<#macro helium_logger_node_content nodeid>
    <div id="Content${nodeid}" style="display:none">
        <div class="node_content">
            <#nested>
        </div>
    </div>
</#macro>
