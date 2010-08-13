  <#--
============================================================================ 
Name        : confml-validate.xml.ftl 
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
    <quality aspect="SW Configurability"> 
        <#if (doc)?? >
            <#list doc["diamonds-build/quality/summary"] as summary>
                <summary message="${summary.@message}" value="${summary.@value}"/> 
            </#list>
        </#if>
    </quality>
<#include "diamonds_footer.ftl">
