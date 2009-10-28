<#--
============================================================================ 
Name        : summary.html.ftl 
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


<#include "/@macro/logger/logger.ftl"/>

    <#assign table_info = pp.loadData('com.nokia.helium.metadata.SQLFMPPLoader',
        "${dbPath}") >

<head>
    <title>
<#if loginfo?? >
<#assign mykey=loginfo.info.id>
<#if (conv[mykey])?exists>
${loginfo.info.id}
</#if>
build summary</title>
    <@helium_logger_html_head/>
</head>
</#if>
<body>


<!--
    Processing the Helium log summary.
-->
<#macro logentry text, severity>
    <#assign conv={"error": "error", "warning": "warning"}>
    <#if (conv['${severity}'])?exists>
        <@helium_logger_print type="${conv[\"${severity}\"]}">${text}</@helium_logger_print>
    <#else>
        <@helium_logger_print type="">${text}</@helium_logger_print>
    </#if>
</#macro>

<#macro logfile_severity logname, priority, count, helium_node_id>
    <@helium_message_box nodeid="${helium_node_id}" type="${priority}"  count="${count}"?number />
</#macro>


<#macro logfile_entry_detail recordentry, helium_node_id>
    <#if recordentry?keys?size &gt; 0 >
        <@logentry "${recordentry['data']}", "${priority_table[\"${recordentry['priority_id']}\"]}"?lower_case />
    </#if>
</#macro>

<!-- Call the macros to render the log contents. -->
<#assign mykey=loginfo>
<#if (conv[mykey])?exists>
<@helium_logger_header title="${loginfo.info.id} build"/>

<@helium_logger_content title="Build overview">
    Time started: ${loginfo.info.startTime}<br/>
    Build machine: ${loginfo.info.machine}<br/>
    Is published?: ${loginfo.info.publish.status}<br/>
    <#if loginfo.info.publish.status?string == true?string>
        Published location: ${loginfo.info.publish.location}</br>
    </#if>
</@helium_logger_content>
</#if>

<@helium_logger_content title="Errors and warnings details">
<#assign priority_table = table_info['select * from priority'] >
<#assign logpath_table = table_info['select * from logfiles'] >
<#assign priority_ids = priority_table?keys>
<#assign logpath_id = logpath_table?keys>
<#list logpath_id as logpath>
    <#assign component_table = table_info['select id, component from component where logPath_id=${logpath}'] >
    <#assign component_ids = component_table?keys?sort >
    <#assign helium_node_id = helium_node_id + 1>
    <#-- -->
    <@helium_logger_node_head nodeid="${helium_node_id}" title="${logpath_table['${logpath}']}">
        <#list priority_ids as priority>
            <@logfile_severity "${logpath_table['${logpath}']}", "${priority_table['${priority}']}"?lower_case, 
                "${table_info['select count(data) as COUNT from metadata where logpath_id=${logpath} and priority_id = ${priority}'][0]['COUNT']}", 
                "${helium_node_id}" />
        </#list>
    </@helium_logger_node_head>
    <@helium_logger_node_content nodeid="${helium_node_id}">
        <#list component_ids as component_id>
            <#assign helium_node_id = helium_node_id + 1>
            <@helium_logger_node_head nodeid="${helium_node_id}" title="${component_table['${component_id}']}">
                <#list priority_ids as priority>
                    <#assign priority_text = "${priority_table['${priority}']}"?lower_case>
                    <#assign priority_count = "${table_info['select count(data) as COUNT from metadata where logpath_id=${logpath} and priority_id = ${priority} and component_id = ${component_id}'][0]['COUNT']}" >
                    <@logfile_severity "${component_table['${component_id}']}", "${priority_text}", 
                            "${priority_count}", 
                            "${helium_node_id}" />
                </#list>
            </@helium_logger_node_head>
            <@helium_logger_node_content nodeid="${helium_node_id}">
            <#list priority_ids as priority>
                <#list table_info['select * from metadata where logpath_id = ${logpath} and priority_id = ${priority} and component_id = ${component_id}'] as recordentry >
                    <#-- <#if sublog?node_name == "logfile"> --> 
                        <@logfile_entry_detail recordentry, "${helium_node_id}" />
                    <#-- <#elseif sublog?node_name == "log">
                        <@antlognode sublog/>
                    </#if> -->
                </#list>
            </#list>
            </@helium_logger_node_content>
        </#list>
    </@helium_logger_node_content>
</#list>
</@helium_logger_content>
</body>
</html>
