<#--
============================================================================ 
Name        : 
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
<@pp.changeOutputFile name="target-example.dot" />

strict digraph G {
    rankdir=LR;
    rotate=180;
    ordering=out;    
    target [fontcolor=brown,fontsize=12,shape=box];
    direct_dependency [fontcolor=brown,fontsize=12,shape=box];
    indirect_dependency [fontcolor=brown,fontsize=12,shape=box];
    antcall_dependency [fontcolor=brown,fontsize=12,shape=box];
    runtarget_dependency [fontcolor=brown,fontsize=12,shape=box]; 
    target -> direct_dependency [color=navyblue,label="1",fontsize=12];
    direct_dependency -> indirect_dependency [color=navyblue,label="1",fontsize=12];
    target -> antcall_dependency [color=limegreen,label="2",fontsize=12];
    target -> runtarget_dependency [color=limegreen,label="3",fontsize=12];
}