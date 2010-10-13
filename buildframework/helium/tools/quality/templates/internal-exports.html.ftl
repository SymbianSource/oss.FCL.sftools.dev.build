<#--
============================================================================ 
Name        : internal-exports.html.ftl 
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
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
    <#include "/@macro/logger/logger.ftl" />
    <head>
        <title>Internal Exports</title>
        <@helium_logger_html_head/>
    </head>
    <body>

<#macro printconflict node>
    <#assign helium_node_id = helium_node_id + 1>
    <@helium_logger_node_head nodeid="${helium_node_id}" title="${node.@name}">
        <@helium_message_box nodeid="${helium_node_id}" type="InternalExport" count=node[".//file"]?size/>
    </@helium_logger_node_head>    
    <@helium_logger_node_content nodeid="${helium_node_id}">
        <#list node[".//file"] as file>
            <@helium_logger_print type="InternalExport">
                <a href="${file.@name}">${file.@name}</a>
            </@helium_logger_print>
        </#list>
    </@helium_logger_node_content>
</#macro>

    
    <@helium_logger_header title="${ant['build.id']} build"/>
        
    <@helium_logger_content title="Errors and warnings details">
        <#list doc.internalexports["./component"] as component>
            <@printconflict component/>
        </#list>
    </@helium_logger_content>
    
    </body>
</html>

