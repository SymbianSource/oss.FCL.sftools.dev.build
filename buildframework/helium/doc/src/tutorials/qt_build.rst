.. index::
  module: How to create a ROM Image

################################
Configure Helium for Qt building
################################

.. contents::

This tutorial explains how to update your configuration to enable Qt building.


Building Qt components
======================

Qt component can be configured using system definition files version 1.5.1, its definition could be 
found under HELIUM_HOME/tools/common/dtd/sysdef_1_5_1.dtd. You also need to define this schema as the 
main one for the system definition file merging operations, this can be done by adding the following 
line to your build configuration::

   <property name="compile.sysdef.dtd.stub" location="${helium.dir}/tools/common/dtd/sysdef_dtd_1_5_1.xml" /> 


Then qmake building needs to be activated by defining the ``qmake.enabled`` property. 
   
Then you can configure your Qt components by using the proFile attribute under the system definition files.
The proFile attribute defines the name of the pro file relatively to the path defined by the bldFile attribute.
Default qMake command line parameters can be overridden by using the optional qmakeArgs attribute. 

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
   

The system definition files can now be merged and filtered(similarly to Raptor). Helium will use the filtered information
during the build to run qMake and generate the bld.inf required to make Symbian builds.
This will follow this algorithm::

   foreach unit from the filtered system definition file:
      cd <bldFile>
      qmake <proFile>

The file qmake.generated.txt is created with the list of files generated.
