<#--
============================================================================ 
Name        : codescanner.mk.ftl 
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
###################################################################
# Template for CodeScanner.
###################################################################
<#assign all_target="codescanner: "/>
<#assign scanid=1/>
<#list data['inputs'] as input>
codescan${scanid}:
	${data['executable']} -c ${data['config']} -o${data['output_fmt']} ${input} ${data['output_dir']}\${data['outputs'][scanid - 1]}

<#assign all_target ="${all_target}\\\n\tcodescan${scanid} "/>
<#assign scanid=scanid + 1/>
</#list>


${all_target}
