<#--
============================================================================ 
Name        : compile.xml.ftl 
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
<#include "diamonds_header.ftl"> 
    <build>    
        <#if ant?keys?seq_contains("object.files")><objects>${ant["object.files"]}</objects></#if>
        <#if ant?keys?seq_contains("generated.files")><generated_files>${ant["generated.files"]}</generated_files></#if>
    </build>
<#if doc?? >
    <faults>
        <#list doc.compile.components.component as component>
        <component>
            <name>${component.@name}</name>
            <total severity="error">${component.@error}</total>
            <total severity="warning">${component.@warning}</total>
        </component>
        </#list>
        <!-- print summary of the errors -->
        <total severity="error">${doc.compile.total.@error}</total>      
        <total severity="warning">${doc.compile.total.@warning}</total>
        <total severity="warning_rvct_other">0</total>
        <!-- todo update to calculate the correct value -->
        <total severity="warning_rvct_bad">${doc.compile.total.@critical}</total>
    </faults>
    <components>
        <#list doc.compile.components.component as component>
        <component>${component.@name}</component>
        </#list>
    </components>
</#if>
<#include "diamonds_footer.ftl"> 

    