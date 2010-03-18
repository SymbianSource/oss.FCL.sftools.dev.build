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

Developer must preferably use standard Ant logging for any user log output.
Internal debug logging must be implemented using Log4J framework.

 * ANT Listeners must use log4j logging framework - using Ant logging system might cause some looping issues.
 * Ant Type and Task must use the Ant logging mechanism to report to the user.
 * Generic framework (part of the code which doesn't links to Ant directly) must use Log4J. 
 * Usage of System.out.println should be avoided.
 * All the non-handled exceptions should be considered as errors and should be reported as such:
    * use log("message", Project.MSG_ERR) under Ant
    * log.error() otherwise.
    * Exception to this rule must be clearly commented under the code.
 * Debug information:
    * Log4J framework (log.debug()) must be used to push information to the Helium debug log - so debug information are not
      directly visible by the user.
    * Ant logging framework can also be use to log Type/Task debug info (but log4j is preferred).
    * PrintStackTrace method should be used on below scenario's:
       * At the time of unknown exception.
       * Should be used with exceptions other than BuildException.
       * In case it is difficult to debug the issue with Exception.getMessage().
       * use this method during debugging complex issue (this doesn't mean the line should remain in the code after development).
       * When it is required to print the all the information about the occurring Exception. 


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


Exception
---------

Exceptional event reporting and handling is crutial in software development. Developer must make sure it is done accordingly
to the framework it is currently using:

 * To report a build failure under Ant the BuildException must be used.
    But we have to keep in mind that a BuildException is not tracked because it derives from the RuntimeError type.
    So we have to be careful with those and try to limit their puprose to the original usage: Ant build failure.
 * It is preferable to have meaningful exception type like: FileNotFoundException.
 * Developer should try to avoid as much as possible the throw or catch raw type of exception like Exception, RuntimeError.  
   
