.. index::
  module: Configuring ROM creation

========================
Configuring ROM creation
========================

Called by ``build-roms`` target.

.. index::
   single: imakerconfigurationset type

The imakerconfigurationset type
-------------------------------

Information on how to configure the properties is given below:

The imakerconfigurationset supports imakerconfiguration nested elements.

'''imakerconfiguration''' element:

.. csv-table:: Ant properties to modify
   :header: "Attribute", "Description", "Values"

   "``regionalVariation``", "Enable regional variation switching. - Deprecated (always false)", "false"

The imakerconfiguration supports three sub-types:

.. csv-table:: Ant properties to modify
   :header: "Sub-type", "Description"

   "``makefileset``", "Defines the list of iMaker configuration to run image creation on."
   "``targetset``", "List of regular expression used to match which target need to be executed."
   "``variableset``", "List of variable to set when executing iMaker."


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

The target can be configured by defining an hlm:imakerconfigurationset element with the '''imaker.rom.config''' reference.

.. code-block:: xml
    
    <hlm:imakerconfigurationset id="imaker.rom.config">
    ...
    </hlm:imakerconfigurationset>

The other configurable element is the engine. The '''imaker.engine''' property defines the reference
to the engine configuration to use for building the roms. Helium defines two engines by default:
* imaker.engine.default: multithreaded engine (hlm:defaultEngine type)
* imaker.engine.ec: ECA engine - cluster base execution (hlm:emakeEngine type)
  
If the property is not defined Helium will guess the best engine to used based on the build.system property.
 