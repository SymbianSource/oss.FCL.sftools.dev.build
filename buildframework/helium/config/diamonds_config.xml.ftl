<?xml version="1.0" encoding="UTF-8"?>
<!-- 
============================================================================ 
Name        : diamonds_config.xml 
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
<configuration>
<config>
    <template-dir path="${ant['helium.dir']}/tools/common/templates/diamonds" />
    <output-dir path="${ant['diamonds.build.output.dir']}"/>
    <property name="smtpserver" value="email.smtp.server" />
    <property name="ldapserver" value="email.ldap.server" />
    <property name="initialiser-target-name" value="diamonds" />
    <server>
        <property name="host" value="diamonds.host" />
        <property name="port" value="diamonds.port" />
        <property name="path" value="diamonds.path" />
        <property name="tstampformat" value="yyyy-MM-dd'T'HH:mm:ss" />
        <property name="mail" value="diamonds.mail" />
        <property name="category-property" value="build.family" />
        <property name="buildid-property" value="diamonds.build.id" />
    </server>
</config>
<logger>
    <stages>
        <stage name="pre-build" start="prep" end="prebuild" />
        <stage name="build" start="compile-main" end="compile-main" />
        <stage name="post-build" start="postbuild" end="zip-localised" />
        <stage name="release" start="publish-variants" end="final" />
    </stages>
    <targets>
        <target name="diamonds" template-file="tool.xml.ftl" 
            logfile="${ant['temp.build.dir']}/build/doc/ivy/tool-dependencies-${ant['build.type']}.xml" ant-properties="true"/>        

        <target name="compile-main" />
            
        <target name="ido-codescanner" template-file="codescanner.xml.ftl"
            logfile="${ant['ido.codescanner.output.dir']}/problemIndex.xml"/>

        <!-- if no logfile provided, looks for xml file to send 
            using <build.id_target_name.xml> file or<target_name.xml> file, 
            if both doesn't exists does nothing. tries to pass ant properties
            and sends it.-->
            
        <target name="create-bom"/>
        
        <target name="post-coverity" template-file="coverity.xml.ftl"
            logfile="${ant['diamonds.coverity.report.file']}"/>
        
        <target name="rndsdk-create-api-descr-xml" template-file="apimetrics.xml.ftl"
            logfile="${ant['build.drive']}/output/apidescr/apidescr.xml"/>
            
        <#if (ant?keys?seq_contains('validate.policy.log'))>
        <target name="render-validate-policy" template-file="validate-policy-log.xml.ftl" 
            logfile="${ant['validate.policy.log']}"/>
        </#if>

        <!-- defer will store all the converted output file and sends only if there any other
            stage / target starts to send some data to diamonds -->
        <target name="check-tool-dependencies" template-file="tool.xml.ftl" 
            logfile="${ant['temp.build.dir']}/build/doc/ivy/tool-dependencies-${ant['build.type']}.xml" ant-properties="true"
            defer="true"/>
    </targets>
</logger>
</configuration>