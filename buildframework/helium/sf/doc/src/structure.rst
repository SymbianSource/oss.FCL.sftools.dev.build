==============================
Project Development guidelines
==============================


Helium now contains its Java and Python components into its structure. Its main requirements to build the delivery are:
 * Ant 1.7.0
 * JDK 1.6 or newer
 * Python 2.6

The project is split in several sub-modules which cover specific features.

Anatomy of the project
======================

::
   
   + builder
      - build.xml
      - bld.bat
      - bld
      + antlibs
         Ant specific dependencies needed to execute ant properly
         e.g: Java checkstyle, Code coverage tools
         The jar in that folder will not be used as compilation dependencies
   + <layer>
       + doc
          General documentation of the project
       + settings
          + ivysettings.xml
       + deps
          + <org>
             + <name>
                + <rev>
                   - <name>-<rev>.jar
          + ...
       + java
          + component1
          + componentn ...
       + python
          + component1
          + componentn ...
   + <layer> ...


Anatomy of a Component
======================

A component is a self contained structure which implements a set of feature related to a specific domain (e.g: Diamonds, SCM). The following diagram shows 
the physical structure of a component.

::
   
   + <component_name>
         - build.xml
         - ivy.xml
         + src
            + com
               + nokia
                   + helium
                      + <component_name>
                          + ant
                             + taskdefs
                               source of the Ant tasks
                             + types
                               source of the Ant DataType 
                             + listeners
                               source of the Ant Listener
                             + conditions
                               source of the Ant Conditions
         + tests
           - build.xml
           - bld.bat
           - bld.sh
           + antunits
              - test_xxx.ant.xml* - Unittest implemented using AntUnit  
           + data
             data used for the the unittests.
           + src
             + com
                + nokia
                   + helium
                      + <component_name>
                         + tests
                            source of junit unittests.

The build.xml
-------------

This is simplest file you must have at component level, **<name of the component>** is really important
as it defines the future name of the jar file.
::
   
   <project name="<name of the component>">
       <description>Component build file.</description>
       <import file="../../builder/java/macros.ant.xml"/>
   </project>

The ivy.xml
-----------

The ivy.xml is used to gather the relevant dependencies to build your component, and to order
the build of the components correctly:

::
    
   <?xml version="1.0" encoding="ISO-8859-1"?>
   <ivy-module version="2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:noNamespaceSchemaLocation="http://ant.apache.org/ivy/schemas/ivy.xsd">
       <info
          organisation="com.nokia.helium"
           module="<name of the component>"
           status="integration">
       </info>
       <dependencies>
          <dependency name="<name of an another component>" rev="latest.integration" conf="default" />
          <dependency org="dom4j" name="dom4j" rev="1.2.9" conf="default" />
       </dependencies>
   </ivy-module>
   
More info about Ivy can be found from: http://ant.apache.org/ivy/

Antunit files
-------------

The builder will automatically test all the antunit files from <base_component>/tests/antunits.
Test must be written by keeping in mind that src tree must remain unmodified after the testing (please use the test.temp.dir).

Example of test file:
::
   
   <project name="test-<component>-<feature>" xmlns:au="antlib:org.apache.ant.antunit" xmlns:hlm="http://www.nokia.com/helium">
      <description>Helium unittests.</description>
   
      <target name="setUp">
         <delete dir="${test.temp.dir}" failonerror="false" />
         <mkdir dir="${test.temp.dir}" />
      </target>

      <target name="tearDown">
         <delete dir="${test.temp.dir}" failonerror="false" />
         <mkdir dir="${test.temp.dir}" />
      </target>
      
      <target name="test-file-generation">
         <echo message="foo-bar" file="${test.temp.dir}/demo.txt" />
         <au:assertFileExists file="${test.temp.dir}/demo.txt" />
      </target>
   </project>



General guidelines
==================

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

General coding guidelines
-------------------------

 * Java components must not use getProperty() with hardcoded name coming from helium (e.g: getProject().getProperty("helium.dir")), only exceptions:
    * Ant Listeners (name of the property must be link to the listener not to helium!)
    * Code under the legacy component.
 * It is forbidden to share unittest data between components (else it breaks the self-contained principle).
 
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
   
