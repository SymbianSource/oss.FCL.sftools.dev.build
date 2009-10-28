==============================
Project Development guidelines
==============================


Helium Antlib is a standalone project which is completely independent from Helium. Its only main requirements are:
 * Ant 1.7.0
 * JDK 1.6 or newer

The project is split in several sub-modules which cover specific features.

Anatomy of the project
======================

::
   
   - build.xml
   - bld.bat
   - bld.sh
   + antlibs
     Ant specific dependencies needed to execute ant properly
     e.g: Java checkstyle, Code coverage tools
     The jar in that folder will not be used as compilation dependencies
   + lib
     Common dependencies between modules.
     e.g: common logging, ...
   + doc
     General documentation of the project
   + module1
   + module1
   + modulen...


Anatomy of a module
===================

A module contains a set of Ant feature related to a specific domain (e.g: Diamonds, SCM). The following diagram shows 
the physical structure of a module.

::
   
   + <module_name>
         - build.xml
         - bld.bat
         - bld.sh
         + lib
           module specific jar dependencies
         + src
            + com
               + nokia
                   + helium
                      + <module_name>
                          + ant
                             + taskdefs
                               source of the Ant tasks
                             + types
                               source of the Ant DataType 
                             + listener
                               source of the Ant Listener
                             + condition
                               source of the Ant Conditions
         + tests
           - build.xml
           - bld.bat
           - bld.sh
           - test_xxx.ant.xml* - Unittest implemented using AntUnit  
           + data
             data used for the the unittests.
           + src
             + com
                + nokia
                   + helium
                      + <module_name>
                         + tests
                            source of junit unittests.



General guidelines
==================

Distribution policy
-------------------

Each directory of the Antlib project must have a Distribution.policy.S60 file with the policy value 7 (see S60 guidelines).



External dependencies
---------------------

External dependencies added to the project must be in compliance with Nokia process and rules.


Source code license
-------------------
Each file added to the project should include the following license header.
::
   
   /*
    * Copyright (c) 2007-2008 Nokia Corporation and/or its subsidiary(-ies).
    * All rights reserved.
    * This component and the accompanying materials are made available
    * under the terms of the License "Eclipse Public License v1.0"
    * which accompanies this distribution, and is available
    * at the URL "http://www.eclipse.org/legal/epl-v10.html".
    *
    * Initial Contributors:
    * Nokia Corporation - initial contribution.
    *
    * Contributors:
    *
    * Description:  
    *
    */

Documentation
-------------

All classes and methods must be documented. Ant facade classes (like Task or DataType)
must be Antdoclet documented (preferably with usage example).

You can find more information on how to document Ant task using the Antdoclet plugin on http://antdoclet.neuroning.com/.
 
Logging
-------

Developer must use standard Ant logging for any user log output.
Internal debug logging must be implemented using Log4J framework.

This is an example on how to use logging:
::
   
   import org.apache.log4j.Logger;
   
   class MyClass extends Task {
       private static Logger log = Logger.getLogger(MyClass.class);
       
       public void execute() {
           log("Executing...");
           log.debug("some useful debug information.");
       }
   }


Please find more information on Log4J from the online manual: http://logging.apache.org/log4j/1.2/manual.html.
