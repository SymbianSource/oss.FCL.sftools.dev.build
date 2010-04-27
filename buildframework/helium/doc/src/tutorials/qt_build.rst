..  ============================================================================ 
    Name        : qt_build.rst
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
  module: How to create a ROM Image

################################
Configure Helium for Qt building
################################

.. contents::

This tutorial explains how to update your configuration to enable Qt building.


Building Qt components
======================

Qt component can be configured using System Definition version 1.5.1, its definition could be 
found under ``HELIUM_HOME/tools/common/dtd/sysdef_1_5_1.dtd``. You also need to define this schema as the 
main one for the System Definition file merging operations, this can be done by adding the following 
line to your build configuration::

    <property name="compile.sysdef.dtd.stub" location="${helium.dir}/tools/common/dtd/sysdef_dtd_1_5_1.xml" /> 

Then qmake building needs to be activated by defining the :hlm-p:`qmake.enabled` property. 
   
Then you can configure your Qt components by using the proFile attribute under the System Definition files.
The ``proFile`` attribute defines the name of the pro file relatively to the path defined by the ``bldFile`` attribute.
Default qMake command line parameters can be overridden by using the optional ``qmakeArgs`` attribute. 

Example

.. code-block:: xml
   
   <?xml version="1.0"?>
   <!DOCTYPE SystemDefinition SYSTEM "sysdef_1_5_1.dtd" []>
   <SystemDefinition name="organizer" schema="1.5.1">
     <systemModel>
       <layer name="app_layer">
         <module name="module">
           <unit unitID="my.component" name="my.component"  bldFile="my/component/location/group"  proFile="component.pro" mrp=""/>
           <unit unitID="my.component2" name="my.component2"  bldFile="my/component/location/group"  proFile="component.pro" qmakeArgs="-r" mrp=""/>
         </module>
       </layer>
     </systemModel>
   </SystemDefinition>
   

The System Definition files can now be merged and filtered (similarly to Raptor). Helium will use the filtered information
during the build to run qMake and generate the ``bld.inf`` required to make Symbian builds.
This will follow this algorithm::

   foreach unit from the filtered System Definition file:
      cd <bldFile>
      qmake <proFile>

The file ``qmake.generated.txt`` is created with the list of files generated.


System Definition 3 support
===========================

The newer version of the System Definition format is now supported by the Qt integration. The only difference with previous format is the
usage of a namespaced attribute like in the following example:

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>
    <SystemDefinition schema="3.0.0" xmlns:qt="http://www.nokia.com/qt">
      <package id="helloworldapi" name="helloworldapi" levels="demo">
        <collection id="helloworld_apis" name="helloworlds APIs" level="demo">
          <component id="helloworld_api" name="Hello World API" purpose="development" >
            <unit bldFile="group" mrp="" qt:proFile="helloworld.pro" qt:qmakeArgs="-nomoc"/>
          </component>
        </collection>
      </package>
    </SystemDefinition>


Important to note that ``xmlns:qt="http://www.nokia.com/qt"`` must be declared as mentioned (if URL is incorrect component will be ignored).
