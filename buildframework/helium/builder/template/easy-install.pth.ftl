<#-- 
============================================================================ 
Name        : easy-install.pth.ftl 
Part of     : Helium AntLib

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
import sys; sys.__plen = len(sys.path)
<#list project.getReference('egg.deps.fileset').toString()?split(ant['path.separator']) as file>
<#assign path = file?split("[\\\\/]", 'r')>
./${path[path?size-2]}/${path?last}
</#list>
import sys; new=sys.path[sys.__plen:]; del sys.path[sys.__plen:]; p=getattr(sys,'__egginsert',0); sys.path[p:p]=new; sys.__egginsert = p+len(new)
