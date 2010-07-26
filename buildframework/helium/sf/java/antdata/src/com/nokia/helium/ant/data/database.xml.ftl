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
<#macro macroOutputMacro macro>
        <macro>
            <name>${macro.name}</name>
            <description>${macro.description}</description>
            <scope>${macro.scope}</scope>
            <deprecated>${macro.deprecated}</deprecated>
            <location>${macro.location}</location>
            <summary>${macro.summary}</summary>
            <documentation>${wiki(macro.documentation)}</documentation>
            <usage><![CDATA[${macro.usage}]]></usage>
            
            <#list macro.signals as signal>
            <signal>${signal}</signal>
            </#list>
            
            <source><![CDATA[
    ${macro.source}]]></source>
        </macro>
</#macro>
<antDatabase xmlns:hlm="http://www.nokia.com/helium">
    <#list projects as project>
    <project>
        <name>${project.name}</name>
        <default>${project.default}</default>
        <description>${wiki(project.description)}</description>
        <scope>${project.scope}</scope>
        <deprecated>${project.deprecated}</deprecated>
        <location>${project.location}</location>
        <summary>${project.summary}</summary>
        <documentation>${wiki(project.documentation)}</documentation>
        
        <#list project.projectDependencies as dependency>
        <projectDependency>${dependency}</projectDependency>
        </#list>
        
        <#list project.libraryDependencies as dependency>
        <libraryDependency>${dependency}</libraryDependency>
        </#list>
        
        <pythonDependency/>
        
        <#list project.targets as target>
        <target>
            <name>${target.name}</name>
            <ifDependency>${target.if}</ifDependency>
            <unlessDependency>${target.unless}</unlessDependency>
            <description>${target.description}</description>
            <scope>${target.scope}</scope>
            <deprecated>${target.deprecated}</deprecated>
            <location>${target.location}</location>
            <summary>${target.summary}</summary>
            <documentation>${wiki(target.documentation)}</documentation>
            
            <#list target.depends as dependency>
            <dependency type="direct">${dependency}</dependency>
            </#list>
            
            <#list target.execTargets as target>
            <dependency type="exec">${target}</dependency>
            </#list>
            
            <#list target.logs as log>
            <log>${log}</log>
            </#list>
            
            <#list target.signals as signal>
            <signal>${signal}</signal>
            </#list>
            
            <#list target.executables as executable>
            <executable>${executable}</executable>
            </#list>
            
            <#list target.propertyDependencies as propertyDep>
            <propertyDependency>${propertyDep}</propertyDependency>
            </#list>
            
            <source><![CDATA[
    ${target.source}]]></source>
        </target>
        </#list>
        
        <#list project.properties as property>
        <property>
            <name>${property.name}</name>
            <defaultValue>${property.defaultValue}</defaultValue>
            <type>${property.type}</type>
            <editable>${property.editable}</editable>
            <scope>${property.scope}</scope>
            <deprecated>${property.deprecated}</deprecated>
            <location>${property.location}</location>
            <summary>${property.summary}</summary>
            <documentation>${wiki(property.documentation)}</documentation>
            <source><![CDATA[
    ${property.source}]]></source>
        </property>
        </#list>
        
        <#list project.propertyCommentBlocks as property>
        <property>
            <name>${property.name}</name>
            <defaultValue>No default value.</defaultValue>
            <type>${property.type}</type>
            <editable>${property.editable}</editable>
            <scope>${property.scope}</scope>
            <deprecated>${property.deprecated}</deprecated>
            <location>${property.location}</location>
            <summary>${property.summary}</summary>
            <documentation>${wiki(property.documentation)}</documentation>
            <source><![CDATA[
    ${property.source}]]></source>
        </property>
        </#list>
        
        <#list project.macros as macro>
        <@macroOutputMacro macro/>
        </#list>
    </project>
    </#list>
    
    <#list antlibs as antlib>
    <antlib>
        <name>${antlib.name}</name>
        <location>${antlib.location}</location>
        
        <#list antlib.macros as macro>
        <@macroOutputMacro macro/>
        </#list>
    </antlib>
    </#list>
    
    <#list packages as package>
    <package>
        <name>${package.name}</name>
        <summary>${package.summary}</summary>
        <documentation>${package.documentation}</documentation>
        <#list package.projects as projectRef>
        <projectRef>
            <name>${projectRef.name}</name>
        </projectRef>
        </#list>
        <#list package.antlibs as antlibRef>
        <antlibRef>
            <name>${antlibRef.name}</name>
        </antlibRef>
        </#list>
    </package>
    </#list>
    
</antDatabase>



