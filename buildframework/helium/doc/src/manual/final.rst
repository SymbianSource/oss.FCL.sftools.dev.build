..
    ============================================================================ 
    Name        : final.rst
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

.. index::
  single: Stage - Final operations

Final operations
================

Final operation are steps which could happen at the workflow completion.


Running a target at build completion
------------------------------------

Helium offers the possibility to run a final target despite any error which could occur during the build.
The configuration of the target is done using the **hlm.final.target** property.

e.g:
::
   
   <property name="hlm.final.target" value="my-final-target" />
   

Running action on failure
-------------------------

The signaling framework will automatically run all signalExceptionConfig in case of Ant failure at the
end of the build. 

This example shows how simple task can be run in case of failure: 
::
   
       <hlm:signalExceptionConfig id="signal.exception.config">
           <hlm:notifierList>
               <hlm:executeTaskNotifier>
                   <echo>Signal: ${r'$'}{signal.name}</echo>
                   <echo>Message: ${r'$'}{signal.message}</echo>
                   <runtarget target="build-log-summary" />
               </hlm:executeTaskNotifier>
           </hlm:notifierList>
       </hlm:signalExceptionConfig>
   


