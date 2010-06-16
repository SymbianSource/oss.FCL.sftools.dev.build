<#--
============================================================================ 
Name        : package.rst.ftl
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
<#include "api.ftllib"/>
   
<#list doc.antDatabase.package as package>
<@pp.changeOutputFile name="package-${package.name}.rst" />

.. index::
   ${package.name}
   
==========================================================
Package ${package.name}
==========================================================

.. toctree::
   :maxdepth: 2
   
<#assign projectList=package.projectRef.name?sort>
<#list projectList as project>
   project-${project}
</#list>
<#assign antlibList=package.antlibRef.name?sort>
<#list antlibList as antlib>
   antlib-${antlib}
</#list>


</#list>


