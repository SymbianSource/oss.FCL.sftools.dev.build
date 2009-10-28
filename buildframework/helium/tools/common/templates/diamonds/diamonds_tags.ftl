<#--
============================================================================ 
Name        : diamonds-tags.ftl 
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
<#if ant?keys?seq_contains("diamonds.build.tags")>
  <tags>
  <#list ant["diamonds.build.tags"]?split(",") as key>
   <#if key?length<=50>
    <tag>${key}</tag>
   <#else>
      <#stop "--> The build tag '${key}' defined in property 'diamonds.build.tags' is too long. The maximum length allowed is 50. Please adjust it accordingly.">
   </#if>
  </#list> 
  </tags>
</#if>
