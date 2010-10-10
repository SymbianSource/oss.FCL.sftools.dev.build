<#--
============================================================================ 
Name        : bom.html.ftl 
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
        <title>Bill of Materials</title>
        <@helium_logger_html_head/>
    </head>
    <body>


<#macro printtype project title type>
    <#assign helium_node_id = helium_node_id + 1>
    <@helium_logger_node_head nodeid="${helium_node_id}" title="${title}">
        <@helium_message_box nodeid="${helium_node_id}" type="${type}" count=project?size/>
    </@helium_logger_node_head>    
    <@helium_logger_node_content nodeid="${helium_node_id}">
        <#list project as node>
            <@helium_logger_print type="${type}">
                ${node}
            </@helium_logger_print>
        </#list>
    </@helium_logger_node_content>
</#macro>

<#macro printTasks project>
    <#list project.task as node>
    <@helium_logger_print type="task">
      ${node.id}:${node.synopsis}
    </@helium_logger_print>
    </#list>
</#macro>

<#macro printTasksAndFolders project title>
    <#assign helium_node_id = helium_node_id + 1>
    <@helium_logger_node_head nodeid="${helium_node_id}" title="${title}">
        <@helium_message_box nodeid="${helium_node_id}" type="task" count=project["count(//task)"]/>
    </@helium_logger_node_head> 
    <@helium_logger_node_content nodeid="${helium_node_id}">
        <@printTasks project=project/>
        <#list project.folder as node>           
            <#assign helium_node_id = helium_node_id + 1>
            <@helium_logger_node_head nodeid="${helium_node_id}" title="${node.name}">
                <@helium_message_box nodeid="${helium_node_id}" type="task" count=project.task?size/>
            </@helium_logger_node_head>    
            <@helium_logger_node_content nodeid="${helium_node_id}">
                <@printTasks project=node/>
            </@helium_logger_node_content>
        </#list>          
    </@helium_logger_node_content>
</#macro>

<#macro printproject project>
    <#assign helium_node_id = helium_node_id + 1>
    <@helium_logger_node_head nodeid="${helium_node_id}" title="${project.name}">
        <@helium_message_box nodeid="${helium_node_id}" type="baseline" count=project.baseline?size/>
        <@helium_message_box nodeid="${helium_node_id}" type="task" count=project["count(//task)"]/>
        <@helium_message_box nodeid="${helium_node_id}" type="fix" count=project.fix?size/>
    </@helium_logger_node_head>    
    <@helium_logger_node_content nodeid="${helium_node_id}">
        <@printtype project=project.baseline title="Baselines" type="baseline"/>
        <@printTasksAndFolders project=project title="Tasks"/>
        <@printtype project=project.fix title="Fix" type="fix"/>
    </@helium_logger_node_content>
</#macro>


    
    <@helium_logger_header title="${doc.bom.build} build"/>
        
    <@helium_logger_content title="Baseline and Task details">
        <#list doc.bom.content.project as project>
            <@printproject project=project />
        </#list>
    </@helium_logger_content>

    <@helium_logger_content title="ICDs / ICFs">
        <@printtype project=doc.bom.content.input.icds.icd.name title="ICDs / ICFs" type="icd"/>
    </@helium_logger_content>
    
    </body>
</html>

