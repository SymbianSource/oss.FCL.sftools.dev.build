<#--
============================================================================ 
Name        : finish.xml.ftl 
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
  <signals>
      <#assign diamondsignalname = ""/>
      <#assign diamondkeys = diamondSignal?keys>
      <#list diamondkeys as diamondkey>
      <#if diamondkey?contains("diamond.signal.name")>
      <#list diamondkey?split(".") as index>
      <#assign signalIndex = index/>
      </#list>
      <signal>
      <#list diamondkeys as diamondkey>
      <#if diamondkey?contains("${signalIndex}")>
          <#if diamondkey?contains("diamond.signal.name.${signalIndex}")><name>${diamondSignal[diamondkey]}</name></#if>
          <#if diamondkey?contains("diamond.error.message.${signalIndex}")><message>${diamondSignal[diamondkey]}</message></#if>
          <#if diamondkey?contains("diamond.time.stamp.${signalIndex}")><timestamp>${diamondSignal[diamondkey]}</timestamp></#if>
      </#if>
      </#list>
      </signal>
      </#if>
      </#list>
  </signals>
<#include "diamonds_footer.ftl"> 