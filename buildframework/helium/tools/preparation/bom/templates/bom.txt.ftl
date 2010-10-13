<#--
============================================================================ 
Name        : bom.txt.ftl 
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
Bill Of Materials
=================

Build: ${doc.bom.build}

<#list doc.bom.content.project as project>

Project
-------

${project.name}

Baselines
`````````
<#list project.baseline as baseline>
${baseline}
</#list>

Tasks
`````
<#list project.task as task>
${task.id}
${task.synopsis}
</#list>
<#list project.folder as folder>
<#list folder.task as task>
${task.id}
${task.synopsis}
</#list>
</#list>

Folders
```````
<#list project.folder as folder>
<#list folder.name as name>
${name}
</#list>    
</#list>
</#list>

Symbian ICD/ICFs
----------------

<#list doc.bom.content.input.icds.icd as icd>
${icd.name}
</#list>

