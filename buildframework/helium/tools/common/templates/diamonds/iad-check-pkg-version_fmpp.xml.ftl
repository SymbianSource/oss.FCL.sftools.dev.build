<#--
============================================================================ 
Name        : iad-check-pkg-version_fmpp.xml.ftl
Part of     : Helium

Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
<#assign db = pp.loadData('com.nokia.helium.metadata.ORMFMPPLoader', "${dbPath}") >
    <quality aspect="iad">
        <summary message="IAD errors" value="${db['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p where UPPER(p.severity)=\'ERROR\' and l.path LIKE \'%_iad_validation.log\''][0]}"/>
        <#list db['jpa']['select m from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p where UPPER(p.severity)=\'ERROR\' and l.path LIKE \'%_iad_validation.log\''] as m>
        <message severity="error" type="IAD" message="${m.text}" />
        </#list>
    </quality>
<#include "diamonds_footer.ftl">

