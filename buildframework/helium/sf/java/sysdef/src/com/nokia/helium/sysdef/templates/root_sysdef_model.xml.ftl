<#--
============================================================================ 
Name        : root_sysdef_model.xml.ftl 
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
<?xml version="1.0" encoding="UTF-8"?>
<!-- 
============================================================================ 
Name        : package_model.xml 
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
<!DOCTYPE SystemDefinition [
<!ELEMENT SystemDefinition ( systemModel | layer | package | collection | component)>
<!ATTLIST SystemDefinition
  schema CDATA #REQUIRED
  id-namespace CDATA "http://www.symbian.org/system-definition"
>
<!-- this DTD describes schema="3.0.0" --> 

<!-- all relative paths are relative to this file
    all absolute paths are relative to the environment variable specified by the root attribute, or SRCROOT if not.  -->

<!-- Container for metadata
    meta, if present, should always be the first element in the parent 
     -->
<!ELEMENT meta ANY>
<!ATTLIST meta
  href      CDATA #IMPLIED
  type  CDATA "auto"
  rel   CDATA "Generic"
>

<!-- systemModel element has name but no ID -->
<!ELEMENT systemModel (meta*, layer+)>
<!ATTLIST systemModel
  name CDATA #IMPLIED
>

<!-- All items from layer down to component should have either @href or at least one valid child item.
    Anything else will be considered a placeholder
    -->

<!ELEMENT layer (meta*, (package | collection)*)  >
<!ATTLIST layer
  id ID #REQUIRED
  name CDATA #IMPLIED
  href      CDATA #IMPLIED
  levels NMTOKENS #IMPLIED
  span CDATA #IMPLIED
  before NMTOKEN #IMPLIED
>

<!ELEMENT package (meta*,  (package | collection)*)>
 <!-- Nested packages are for backwards compatibility only -->
<!ATTLIST package
  id ID #REQUIRED
  name CDATA #IMPLIED
  version CDATA #IMPLIED
  tech-domain CDATA #IMPLIED
  href   CDATA #IMPLIED
  levels NMTOKENS #IMPLIED
  span CDATA #IMPLIED
  level NMTOKEN #IMPLIED
  before NMTOKEN #IMPLIED  
>

<!ELEMENT collection (meta*, (component* ))>
<!ATTLIST collection
  id ID #REQUIRED
  name CDATA #IMPLIED
  href      CDATA #IMPLIED
  level NMTOKEN #IMPLIED
  before NMTOKEN #IMPLIED  
>

<!ELEMENT component (meta*, unit*)>
<!-- contains units or is a placeholder -->
<!ATTLIST component
  id ID #REQUIRED
  name CDATA #IMPLIED
  href      CDATA #IMPLIED
  deprecated CDATA #IMPLIED
  introduced CDATA #IMPLIED
  target  ( device | desktop | other ) "device"
  purpose ( optional | mandatory | development ) "optional"  
  class NMTOKENS #IMPLIED
  filter CDATA #IMPLIED
  before NMTOKEN #IMPLIED  
  origin-model CDATA #IMPLIED
>
<!--
    "filter" attribute is deprecated
    "origin-model" attribute is only to be inserted by tools when merging models
    recommended class values are: doc, config, plugin, tool, api -->

<!ELEMENT unit EMPTY >
<!ATTLIST unit
  mrp CDATA #IMPLIED
  bldFile CDATA #IMPLIED
  base CDATA #IMPLIED
  root CDATA #IMPLIED
  version NMTOKEN #IMPLIED
  prebuilt NMTOKEN #IMPLIED
  late (yes|no) #IMPLIED
  filter CDATA #IMPLIED
  priority CDATA #IMPLIED
>
<!-- filter and priority are deprecated 
    "root" attribute will usually be inserted by tools when merging models, although it can be set manually-->
]>
<SystemDefinition schema="3.0.0">
<#assign name="">
<#list roots?keys as root><#assign name=name + root + "_"></#list>
<systemModel name="${name}">
<#list layers?keys as layer>
    <layer id="${layer}" name="${layer}">
    <#list roots?keys as root>
        <#if roots[root]?keys?seq_contains(layer)>
            <#list roots[root][layer] as pkg>
        <package id="${pkg}" href="${dest_dir_to_epocroot?replace('\\', '/')}${root}/${layer}/${pkg}/package_definition.xml"/>
            </#list>
        </#if>
    </#list>
    </layer>
</#list>
</systemModel>
</SystemDefinition>