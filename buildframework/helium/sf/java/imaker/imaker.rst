.. index::
  module: Configuring ROM creation

========================
Configuring ROM creation
========================

Called by :hlm-t:`build-roms` target. 


.. index::
   single: imakerconfigurationset type

The imakerconfigurationset type
-------------------------------

Information on how to configure the properties is given below:

The imakerconfigurationset supports imakerconfiguration nested elements.

**imakerconfiguration** element:

.. csv-table:: Attributes to modify
   :header: "Attribute", "Description", "Values"

   ":hlm-p:`regionalVariation`", "Enable regional variation switching. - Deprecated (always false)", "false"

The imakerconfiguration supports three sub-types:

.. csv-table:: Attributes to modify
   :header: "Sub-type", "Description"

   ":hlm-p:`makefileset`", "Defines the list of iMaker configuration to run image creation on."
   ":hlm-p:`targetset`", "List of regular expression used to match which target need to be executed."
   ":hlm-p:`variableset`", "List of variable to set when executing iMaker."


Example of configuration:

.. code-block:: xml

   <hlm:imakerconfigurationset>
      <hlm:imakerconfiguration regionalVariation="true">
         <makefileset>
            <include name="**/product_name/*ui.mk" />
         </makefileset>
         <targetset>
            <include name="^core${r'$'}" />
            <include name="langpack_\d+" />
            <include name="^custvariant_.*${r'$'}" />
            <include name="^udaerase${r'$'}" />
         </targetset>
         <variableset>
            <variable name="USE_FOTI" value="0" />
            <variable name="USE_FOTA" value="1" />
            <variable name="TYPE" value="rnd" />
         </variableset>
      </hlm:imakerconfiguration>
   </hlm:imakerconfigurationset>


Other example using product list and variable group:

.. code-block:: xml

   <hlm:imakerconfigurationset>
      <hlm:imakerconfiguration>
         <hlm:product list="product_name" ui="true" failonerror="false" />
         <targetset>
            <include name="^core${r'$'}" />
            <include name="langpack_\d+" />
            <include name="^custvariant_.*${r'$'}" />
            <include name="^udaerase${r'$'}" />
         </targetset>
         <variableset>
            <variable name="USE_FOTI" value="0" />
            <variable name="USE_FOTA" value="1" />
         </variableset>
         <variablegroup>
            <variable name="TYPE" value="rnd" />
         </variablegroup>
         <variablegroup>
            <variable name="TYPE" value="subcon" />
         </variablegroup>
         <variablegroup>
            <variable name="TYPE" value="prd" />
         </variablegroup>
      </hlm:imakerconfiguration>
   </hlm:imakerconfigurationset>


.. index::
   single: The iMaker Task

How to configure the target
---------------------------

The target can be configured by defining an hlm:imakerconfigurationset element with the **imaker.rom.config** reference.

.. code-block:: xml
    
    <hlm:imakerconfigurationset id="imaker.rom.config">
    ...
    </hlm:imakerconfigurationset>

The other configurable element is the engine. The :hlm-p:`imaker.engine` property defines the reference
to the engine configuration to use for building the roms. Helium defines two engines by default:

 - imaker.engine.default: multithreaded engine (hlm:defaultEngine type)
 - imaker.engine.ec: ECA engine - cluster base execution (hlm:emakeEngine type)
  
If the property is not defined Helium will guess the best engine to used based on the :hlm-p:`build.system` property.
 


The imakerconfiguration
-----------------------

The imakerconfiguration enables the build manager to configure his iMaker builds based on introspection. 
The makefileset element will configure the filtering of the "imaker help-config" command. 
Then for each of the configuration found the targetset elements will be used to filter the output from 
the "imaker -f configuration.mk help-target-*-list" command. Finally a set of command will be generated. 

Each command will then be configure using the set of variables defined by the variableset elements. 
Only the WORKDIR variable is under the task control to ensure call safety during the parallelization. 
The usage of the variablegroup will allow you to duplicate the common set of commands and apply 
additional variables. Example:

 
 .. code-block:: xml
 
 
     <imakerconfiguration regionalVariation="true">
         <makefileset>
             <include name="**/product/*ui.mk"/>
         </makefileset>
         <targetset>
             <include name="^core$" />
             <include name="langpack_\d+" />
             <include name="^custvariant_.*$" />
             <include name="^udaerase$" />
         </targetset>
         <variableset>
             <variable name="USE_FOTI" value="0"/>
             <variable name="USE_FOTA" value="1"/>
         </variableset>
         <variablegroup>
             <variable name="TYPE" value="rnd"/>
         </variablegroup>
         <variablegroup>
             <variable name="TYPE" value="subcon"/>
         </variablegroup>
     </imakerconfiguration>
 


This configuration might produce the following calls :

 .. code-block:: xml
    
    imaker -f /epoc32/rom/config/platform/product/image_conf_product_ui.mk TYPE=rnd USE_FOTI=0 USE_FOTA=1 core
    imaker -f /epoc32/rom/config/platform/product/image_conf_product_ui.mk TYPE=subcon USE_FOTI=0 USE_FOTA=1 core
    imaker -f /epoc32/rom/config/platform/product/image_conf_product_ui.mk TYPE=rnd USE_FOTI=0 USE_FOTA=1 langpack_01
    imaker -f /epoc32/rom/config/platform/product/image_conf_product_ui.mk TYPE=subcon USE_FOTI=0 USE_FOTA=1 langpack_01


 
   