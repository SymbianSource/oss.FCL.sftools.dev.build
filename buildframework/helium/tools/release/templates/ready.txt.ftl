<#--
============================================================================ 
Name        : ready.txt.ftl 
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
ido_name:${ant['build.name']}
date(gt):${pp.now?string("EEE MMM d HH:mm:ss yyyy")}
source_path:${ant['ccm.project.wa_path']}
<#if ant?keys?seq_contains('email.from')>email:${ant['email.from']}</#if>
<#if ant?keys?seq_contains('robot.email.to')><#list ant['robot.email.to']?split(',') as email>
email:${email}
</#list></#if>

