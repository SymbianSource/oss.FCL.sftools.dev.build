..  ============================================================================ 
    Name        : developer_guide.rst
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
  module: Developer Guide

###################################
Developer Guide
###################################

.. contents::

Introduction
============

This describes various practices, procedures and conventions used within Helium. It should be read by all contributors to Helium along with the `Coding Conventions`_.

.. _`Coding Conventions`: coding_conventions.html

.. index::
  single: Directory Structure

Directory structure
===================

The ``/helium`` directory structure consists of:

``/build``
    This is not under source control. It is created on demand to store generated documentation, testing and coverage output and so on.
    
``/config``
    Configuration files for parts of Helium. Some of these may only need to be defined in Helium, whereas others may be default configuration that may be overridden by a user.
    
``/doc``
    All documentation related to Helium. Files are in .rst format (HTML versions can be generated under ``/build/doc`` using the ``hlm doc`` command).
    
``/external``
    Applications and libraries that are maintained outside of the Helium team.

``/tests``
    Test data for unit tests. All unit tests are co-located with the code under test.

``/tools``
    A number of subdirectories for each stage of the build. Each directory may contain Ant scripts and other tools and scripts related to that stage.

``/tools/common``
    Common libraries for Java, Perl and Python and XML schemas.
    
Anatomy of a library project
----------------------------

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

Ant script structure
--------------------

The ``helium.ant.xml`` file in the project root should be imported by each build configuration. This in turn imports the root files for each of the key build stages defined in the ``/tools`` directory. ``helium.ant.xml`` also defines a number of common Ant default properties.


.. index::
  single: Custom Ant libraries

Custom Ant libraries
====================

All custom Ant tasks, types and loggers should be added as new components under the ``/sf`` folder. If the component being created is Java-based, then add it inside the ``/java`` folder. The component directory must contain a ``build.xml`` file that imports ``${builder.dir}/java/macros.ant.xml``. Also the name of the project must be the name of the future JAR file e.g::

   <?xml version="1.0"?>
   <project name="mycomponent">
       <import file="${builder.dir}/java/macros.ant.xml" />
   </project> 

The component also need an Ivy file (``ivy.xml``) in order to be detected and built. The file must define the correct list of dependencies for the component so it get built in the correct order.

Structure
---------

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

build.xml file
--------------

This is the simplest file you must have at component level, ``<name of the component>`` is really important
as it defines the future name of the JAR file.
::
   
   <project name="<name of the component>">
       <description>Component build file.</description>
       <import file="../../builder/java/macros.ant.xml"/>
   </project>

ivy.xml file
------------

The ``ivy.xml`` file is used to gather the relevant dependencies to build your component and to order
the build of the components correctly::
    
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

AntUnit files
-------------

The builder will automatically test all the AntUnit files from ``<component>/tests/antunit``.
Test must be written by keeping in mind that source tree must remain unmodified after the testing (please use the ``test.temp.dir``).

Test file example::
   
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

Source code license
-------------------

Each file should include the following license header::
   
   /*
    * Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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

All classes and methods must be documented.
Ant facade classes like task or type must be doclet documented. This implies the javadoc
to be user and not developer oriented, for instance examples of the task/type usage are really appreciated.
Also all setter methods visible through Ant must be documented properly using *@ant.required* 
or *@ant.not-required* javadoc style attributes.

You can find more information on how to document Ant tasks using the doclet plugin on http://antdoclet.neuroning.com/.

General coding guidelines
-------------------------

 * Java components must not use ``getProperty()`` with a hardcoded name coming from helium (e.g.: ``getProject().getProperty("helium.dir"))`` The only exceptions to this are:
    * Ant listeners (the name of the property must be linked to the listener not to Helium!)
    * Code under the legacy component.
 * It is forbidden to share unittest data between components (else it breaks the "self-contained" principle).


Ant type and task guidelines
----------------------------

In order to match as must as  configurability concepts, Helium custom types and tasks must follow  development guidelines as 
much as possible. You can find then on http://ant.apache.org/ant_task_guidelines.html.

Logging
-------

Developer must preferably use standard Ant logging for any user log output.
Internal debug logging must be implemented using the log4j framework.

 * ANT Listeners must use log4j logging framework - using Ant logging system might cause some looping issues.
 * Ant ``Type`` and ``Task`` classes must use the Ant logging mechanism to report to the user.
 * Generic framework code (that which doesn't link to Ant directly) must use log4j. 
 * Usage of ``System.out.println()`` should be avoided.
 * All the unhandled exceptions should be considered as errors and should be reported as such:
    * use ``log("message", Project.MSG_ERR)`` under Ant.
    * ``log.error()`` otherwise.
    * Exceptions to this rule must be clearly commented under the code.
 * Debug information:
    * log4j framework (``log.debug()``) must be used to push information to the Helium debug log - so debug information is not
      directly visible by the user.
    * The Ant logging framework can also be used to log Type/Task debug info (but log4j is preferred).
    * The ``printStackTrace()`` method should be used on below scenarios:
       * At the time of an unknown exception.
       * Should be used with exceptions other than ``BuildException``.
       * In case it is difficult to debug the issue with ``Exception.getMessage()``.
       * Use when debugging complex issues (this doesn't mean the line should remain in the code after development).
       * When it is required to print the all the information about the occurring ``Exception``. 


This is an example on how to use logging::
   
   import org.apache.log4j.Logger;
   
   class MyClass extends Task {
       private static Logger log = Logger.getLogger(MyClass.class);
       
       public void execute() {
           log("Executing...");
           log.debug("some useful debug information.");
       }
   }

Please find more information on log4j from the online manual: http://logging.apache.org/log4j/1.2/manual.html.

Debug log
``````````

The log4j debug output is written to ``hlm_debug.log`` that is stored under ``HELIUM_CACHE_DIR``. This may be set one of these two values::

    %TEMP%\helium\%USERNAME%\%JOB_ID%
    %TEMP%\helium\%USERNAME%
    
Ensure ``TEMP`` is set to a location that is visible to all so the file can be accessed from all accounts.

Exceptions
----------

Exceptional event reporting and handling is crutial in software development. Developer must make sure it is done accordingly
to the framework it is currently using:

 * To report a build failure under Ant a ``BuildException`` must be used.
    But we have to keep in mind that a ``BuildException`` is not tracked because it derives from ``RuntimeException``.
    So we have to be careful with those and try to limit their puprose to the original usage: Ant build failure.
 * It is preferable to use a meaningful exception type like ``FileNotFoundException``.
 * Throwing or catching raw exceptions like ``Exception``, ``RuntimeException`` should be avoided.  
 
Deprecation
-----------

Deprecation is an inevitable in involving software. The usage of deprecation implies most of the time the replacement of a feature 
by an newer. To make sure it has the minimum impact on the user, we need to provide both features for at least one major release, so 
the customer has time to do the relevant modification to migrate. In order to ease as much as possible the deployment and the migration
to a newer version of any Ant object please follow this guidelines:
 
 * Ant attributes replacement
    * Use the @Deprecated annotation on the Java code to make sure this method is not in use anymore under our code.
    * Log a warning message to the user using Ant logging. Please use the following template:
        * The usage of the '<deprecated_attribute_name>' attribute is deprecated, please consider using the '<new_attribute_name>' attribute.
    * Try to keep the functionality by adapting the code inside the deprecated setter to use the newer API.
    
Example of Ant attribute deprecation for a Java task::
   
   @Deprecated
   public void setDb(File database) {
       log("The usage of the 'db' attribute is deprecated, please consider using the 'database' attribute.", Project.MSG_WARN);
       this.database = database;
   }

 
.. index::
  single: How to build the delivery?

How to build the delivery?
==========================   

From Helium 9.0 onward, the delivery will be released as source code, without any pre-built binaries. In order to build the release please follow the next instructions.

Building the dependencies
-------------------------

In order to build the Helium components you need to use the builder available under the helium directory::

   > cd builder
   > bld build

This will build all the components needed to create the Helium release: egg or jar files.

Retrieving Helium dependencies
------------------------------

Building the dependency will not bring Helium in a workable stage. It is a preparation stage where components could be unit tested in isolation for example. Retrieving Helium dependencies based on the version of Helium you desire is then needed. The builder can achieve this operation by running the following command::

   > cd builder
   > bld -Dconfig=sf get-deps
  
The previous command will retrieve Helium sf configuration dependencies.

Packaging up the built version
------------------------------

A deliverable ZIP package of binary version of Helium can be created using the following commands::

    > cd builder
    > bld -Dconfig=sf create-releasable

The archive can be found at ``build/helium-bin.zip``.

.. index::
  single: Testing
  
Testing
=======

Components
-----------

Component tests can be run using::

    > cd builder
    > bld unittest
   
A specific type of tests can be selected using::

    > bld -Dcomponent.type=java unittest
   
A specific component can be selected using::

    > bld -Dcomponent=sbs unittest

Debug logs for component tests can be found at ``/build/components/<component>/xunit``.

Filtering Python tests using nose
---------------------------------

Python unit tests are run through the nose testing framework. To run just a single Python test module, use::

    bld test -Dcomponent=pythoncore -Dnose.args=amara
    
The value of ``nose.args`` is passed through to nose.


.. index::
  single: Assertions

Assertions
==========

There are some basic assertion macros defined in ``common.ant.xml``. These can be used to check for correctness at the end of a target, e.g. checking that a file exists which the target was supposed to create.

The assertions can be enabled by defining the ``hlm.enable.asserts``. If ``hlm.enable.asserts`` is not enabled, macro will print warnings only.
There are several macros:

``hlm:assert``
    A basic assertion that will check any task contained within it.
    
``hlm:assertFileExists``
    Takes a file attribute and asserts that the file exists.

.. index::
  single: Ivy Configuration

Ivy Configuration
=================

Ibiblio
-------

Libraries in Maven2 Ibiblio_ repository can use: ``helium/config/ivy/ivy.xml``

.. _Ibiblio: http://mirrors.ibiblio.org/pub/mirrors/maven2/

These parameters should be used, if library has passed legal tests: ``transitive="false"``, ``conf="subcon"``
Otherwise use: ``transitive="false"``, ``conf="core_install"``

Direct URLs
------------

Use these for a direct url link, if the library is needed for the subcon release::

    helium/config/ivy/modules/jars_subcon-1.0.ivy.xml
    helium/config/ivy/modules/eggs_subcon-1.0.ivy.xml

Otherwise add to these files for non subcon libraries::

    helium/config/ivy/modules/eggs-1.0.ivy.xml
    helium/config/ivy/modules/jars-1.0.ivy.xml
    
A new Ivy config file can be added for a non-jar or egg type file.


Feature enable Configuration
============================

If we are adding new features (which are similar to diamonds, coverage toosl), then those feature needs to enabled in the build sequence using 'feature.enabled' property.

Using feature.enabled property we need to set intermediate property and that intermidiate property should have the name pattern as internal.feature.enabled.

Intermidiate properties should be set using ant <condition> task. Do not use antcontrib <if> task (avoid as much as possible).

We need to trigger the targets using intermidiate property. 

Target based feature testing
----------------------------

And depending target should be called using intermediate property.

Ex::
    
    feature.enabled = true
    
    <condition property="internal.feature.enabled">
        <istrue value="${feature.enabled}"/>
    </condition>
    
    <target name="xyz" if="internal.feature.enabled"/>
    
If any property is deprecated then that should be documented in the respective .ant.xml.

Ex::

    <!-- Set to true to enable feature - deprecated: Start using feature.enabled property
    @type boolean
    @editable required
    @scope public
    @deprecated since 11.0 
    -->
    <property name="old.feature" value="true"/>
    
    feature.enabled = true
    old.feature = false
    
    <condition property="internal.feature.enabled">
        <or>
            <istrue value="${feature.enabled}"/>
            <isset property="old.feature"/>
        </or>
    </condition>
    
    <target name="xyz" if="internal.feature.enabled"/>
        

Task base feature testing
-------------------------

If the if task is used inside a target it is then preferable to use the feature.enabled property directly:

::
   
   <target name="target-name">
       ...
       <if>
          <or>
              <istrue value="${feature.enabled}"/>
              <isset property="old.feature"/>          
          </or>
          <then>
              ...
          </then>
          ...
       </if>
       ...
   </target>
   

Of course the 'old.feature' will be kept for one major release and removed in the next one.
 