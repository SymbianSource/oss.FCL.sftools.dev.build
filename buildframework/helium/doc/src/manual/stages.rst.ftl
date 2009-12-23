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
.. index::
  module: Stages

=============
Helium stages
=============

.. contents::

This section gives details of each of the phases of a Helium build and what they do.


.. index::
  single: Stage - startup

Stage: Startup
==============

.. index::
  single: Remote builds

Remote builds
-------------

.. index::
  single: Remote build Commands

Remote build Commands
:::::::::::::::::::::

Remote builds are used when a number of build configurations need to be run on several machines from a single work area. For a remote machine to receive the commands, a build manager must login and start the antserver process by running ``c:\apps\antserver\run_ant_server.bat``.

Two commands are supported::

  hlm distribute-work-area

Tars up the work area, copies it to a network location defined by the work.area.temp.dir property, and sends a command to the remote servers to untar the work area. On the remote servers the basedir is deleted before the work area is untarred. ::

  hlm start-remote-builds

Sends commands to start the builds based on the remote builds configuration file entries.


.. index::
  single: Remote build configuration

Remote build configuration
::::::::::::::::::::::::::

The configuration file format defines one or more builds::

  <BuildProcessDefinition>
      <remoteBuilds>
          <build machine="vcbldsrv12" ccmhomedir="${r'$'}{ccm.home.dir}" basedir="${r'$'}{ccm.base.dir}" executable="hlm" dir="${r'$'}{mc_4031_build.dir}\PRODUCT" args="product-build -Dbuild.number=${r'$'}{build.number} -Dprep.root.dir=d:\pmackay"/>
      </remoteBuilds>
  </BuildProcessDefinition>

Each ``<build>`` element has a number of attributes:

machine
  The name of the remote build machine. The commands will only work if an Ant server instance is running, so be careful not to run the server on the local machine!

ccmhomedir
  This should match to the ``ccm.home.dir`` property.

basedir
  This defines the directory in which the current work area (under ``ccm.home.dir``) is located.

executable
  The file to be executed when starting a build. Typically this can be left as ``hlm``.

dir
  The directory where the executable should be found and where the command will be run from.

args
  The arguments passed to the executable. These should consist of Ant arguments, as the build is run using Ant. Note that this attribute value is treated in the same way as the line attribute in the Ant ``exec`` task - spaces are interpreted as separating the arguments.

The ``remote.builds.config.file`` property defines the location of the configuration file. This should be defined in a team Ant configuration file.


.. Commented out because we will not use this for our releases
   Subcon bootstrap
   ----------------
    
   The subcon edition of Helium does not include any 3rd party libraries due to licensing restrictions.
   Before you start using a copy of helium for the first time you need to call ``hlm-bootstrap.bat``.
    
   Run like this if you get timeout errors and set to the values of your proxy server::
   
     hlm-bootstrap.bat -Dproxy.host=172.16.42.137 -Dproxy.port=8080
    
   Or if you have no proxy server::
    
     hlm-bootstrap.bat -Dproxy.disabled=y
    
   The bootstrap process is:
    
    * Download Ivy jars.
    * Use Ivy to download dependencies.
    * Extract and install dependencies.


.. index::
  single: Stage - Preparation

Stage: Preparation
==================

At the start of preparation a new directory is created for the build and subst'ed to ``build.drive``. If a directory with this name already exists, it is renamed to have a current timestamp on the end.

.. index::
  single: How to prepare the build area?

How to prepare the build area?
------------------------------

A key part of build preparation is initialising the build drive by copying or unzipping the input files. The ``build.prep.config.file`` should reference a file that follows the prep XML file format (e.g. mc\mc_build\mc_4031_build\prep.xml). A suggestion is that this file is called prep.xml by default.

The XML format of the prep file is as follows:

Beginning of the file and config
:::::::::::::::::::::::::::::::::

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>
    <prepSpec>
        <config>
            <exclude name="_ccmwaid.inf"/>
            <exclude name="abld.bat"/>
            <exclude name=".static_wa"/> 
            <exclude name="documentation/*"/> 
            <exclude name="documents/*"/> 
            <exclude name="doc/*"/>
        </config>

Each exclude under config defines which files are NOT extracted during unzip phases.

Unzip
:::::

.. code-block:: xml

    <source label="Symbian" basedir="${r'$'}{symbian.release.dir}">
        <unzip name="${r'$'}{symbian.zip.prefix}${r'$'}{symbian.release}_src_generic_part1.zip"/>
        <unzip name="${r'$'}{symbian.zip.prefix}${r'$'}{symbian.release}_epoc32.zip">
            <include name="epoc32/tools/*"/>
        </unzip>
    </source>

Each separate unzip phase is defined beginning with source. Each file that needs to be unzipped is specified with unzip. It is also possible to define what parts of the zips are extracted using include tags.

ICD/ICF Unzip
::::::::::::::

.. code-block:: xml

    <source name="icds" basedir="">
        <unzipicds dest="Z:\">
            <location name="${r'$'}{ccm.base.dir}/S60_3_1/S60_3_1/Symbian_ICD_ICF/${r'$'}{symbian.release}" />
            <include name="src/*" />
        </unzipicds>
    </source>

ICDs/ICFs (Intermediate Code Fix\Drop) are extracted using unzipicds tag. Using this command ensures that the files are extracted in the correct order. Multiple ICD/ICF directories can be given to be extracted by giving multiple locations.

Copy
::::

.. code-block:: xml

    <source label="S60" basedir="${r'$'}{ccm.base.dir}/S60_3_1/S60_3_1">
        <copy name="adaptation" dest="adaptation"/>
        <copy name="S60" dest="S60">
            <exclude name="S60/bldvariant/Series_60_3_1_common/ProductVariant.hrh"/>
        </copy>
    </source>

Each separate copy phase is defined beginning with source. The dest parameter for each copy command defines to what folder the files are copied starting fron the given basedir. It is also possible to exclude files using the exclude tag.

File end
::::::::

::

    </prepSpec>


ICF/ICD:
````````

This information is extracted from the filesystem, it uses the sources defined in the preparation xml configuration file to retreive the ICF/ICD content.

.. Note::
    This means that all ICD/ICF extracted from any other source will not be considered.
    So you MUST use the <unzipicds dest=""> statement of the preparation configuration file.

Flags:
``````

Flags are extracted from the ProductVariant.hrh (mc_config/${r'$'}{build.configuration}_config/${r'$'}{product.name}/include/ProductVariant.hrh).

.. index::
  single: Stage - Source preparation

Stage: Source preparation
=========================

The build preparation consists in two parts:

 * Getting delivery content (SCM, zips...),
 * Preparing the build area.

To get SCM source you just have to run::

  hlm prep-work-area

To create 'build of materials'::

  hlm create-bom

Synergy
-------

In order for the synergy commands to be executed you must define the property ccm.enabled=true in one of the your config files or on the command line. e.g. 

.. code-block:: xml

    <property name="ccm.enabled" value="true" />

It is possible to automatically get content from Synergy using the Helium framework.
To handle that you have to configure the delivery.xml file from your family build configuration folder and reference by the property prep.delivery.file.

Example configurations like a minibuild can be found under the Helium source tree.

Example of configuration:

.. code-block:: xml

    <build>
        <config name="mc_5132" abstract="true">
            <set name="database" value="fa1f5132"/>
            <set name="host" value="${r'$'}{ccm.engine.host}" />
            <set name="dbpath" value="${r'$'}{ccm.database.path}" />
        
            <set name="dir" value="Z:\some\location"/>
            <set name="threads" value="4"/> 
            <set name="sync" value="true"/> 
            <set name="use.reconfigure.template" value="false"/> 
            <set name="release" value="${r'$'}{release.tag}" />
            
            <config name="ppd_sw-PPD51.32_200810:project:sa1spp#1" type="checkout" >
               <set name="folders" value="jk1f5132#1820" />
            </config>
            
            <config name="WLANSniffer2-2007_wk21:project:e002sa08#1" type="snapshot" />
            
            <config name="NSeries08_Themes-1:project:fa1f5132#1" type="checkout" >
               <set name="tasks" value="jk1f5132#1763" />
               <set name="skip.ci" value="true"/> 
            </config>
            
            <config name="NSeries08_Themes-1:project:fa1f5133#2" type="checkout" >               
               <set name="skip.ci" value="false"/> 
               <set name="ci.custom.query" value="(release='MinibuildDomain/next')"/>
            </config>
            
            <config name="S60-S60.32_200810:project:sa1spp#1" type="checkout" >
               <set name="folders" value="jk1f5132#1983" />
            </config>

            <config name="ppd_sw-username:project:sa1spp#1" type="update"/>
             
            <config name="cellmo" abstract="true">
                <set name="dir" value="${r'$'}{ccm.base.dir}\cellmo" />
                <set name="threads" value="1" />
            
                <config name="cellmo_bins_rm235_PRODUCT-ncpp.ICPR71_08w24.2:project:tr1cmtsw#1" type="snapshot" />
                <config name="cellmo_bins_rm236_PRODUCT_chn-ncpp.ICPR71_08w24.2:project:tr1cmtsw#1" type="snapshot" />
                <config name="cellmo_bins_rm342_PRODUCT_lta-ncpp.ICPR71_08w24.2:project:tr1cmtsw#1" type="snapshot" />
            </config>

        </config>
    <build>
    
    
Checkout: only need to define this when extra tasks are required on top of the listed project, otherwise use the snapshot type.
    The following properties are required:
        - release : synergy release to use.
        - dir     : the location of your target snapshot.
        - database: the name of the synergy database you want to use.
    The following properties are optional:
        - thread  : optional parameter, this define the number of process to run for parallel snapshots.
        - purpose : Purpose to check out with.
        - sync : Force a sync step after the work area update.
        - version : the version to check out toward to.
        - tasks : add additional tasks to the reconfigure properties.
        - folders : add additional folders to the reconfigure properties.
        - use.reconfigure.template: enable the usage of the reconfigure templates, this means the project will just be reconfigured, the reconfigure properties will not be modified.
        - fix.missing.baselines: automatically detect new projects and check them out.
        - replace.subprojects: boolean value to enable/disable project replacement during update (default: true).
        - skip.ci: boolean value to include/exclude the project from CC modificationset checking.
        - ci.custom.query: Extend the synergy query for CC modificationset checking eg.(release='MinibuildDomain/next').
        - show.conflicts: boolean value to check for task conflicts.
        - show.conflicts.objects: boolean value to check for object conflicts.
Snapshot: define type of the spec as snapshot and name as the baseline name.
    The following properties are required:
        - dir     : the location of your target snapshot.
        - database: the name of the synergy database you want to use.
    The following properties are optional:
        - thread  : optional parameter, this define the number of process to run for parallel snapshots.

Update: define type of the spec as update and name as the project to update.
    The following properties are required:
        - database: the name of the synergy database you want to use.

Mercurial
---------

Add to ant configuration:

.. code-block:: xml

    <target name="prep-work-area">
        <hlm:scm scmUrl="scm:hg:C:/Build_C/master"> 
            <hlm:checkout baseDir="${r'$'}{ccm.project.wa_path}/GraphicsDomain"/>
            <hlm:changelog baseDir="${r'$'}{ccm.project.wa_path}/GraphicsDomain" xmlbom="${r'$'}{build.log.dir}/${r'$'}{build.id}_bom.xml" />
        </hlm:scm>
    </target>

For more information see API_

.. _API: ../helium-antlib/api/doclet/index.SCM.html

.. index::
  single: Stage - Compilation

Stage: Compilation
==================

Compilation is based on configuration using Symbian System Definition XML files.
See http://developer.symbian.org/wiki/index.php/System_Definition

Every System Definition file can contain content for two separate sections:

System model
    A definition of the system describing the components that exist, broken into layers, modules, etc.
    
Build model
    Build configurations that define what is to be built and how it will be built. Separate unitLists define groups of components.

The steps to configure a Helium build for main compilation are as follows:

1. Put together a list of the System Definition files that define the components needing to be built in the system model sections. This could be one or several files depending on what components need building. They should be defined in an Ant ``<path>`` type with an ``id`` atttribute set to ``system.definition.files``, e.g:

.. code-block:: xml

    <path id="system.definition.files">
        <fileset dir="${r'$'}{build.drive}/src/common/generic/tools/build" includes="System_Definition*.xml"/>
        <pathelement path="${r'$'}{build.drive}/mc/mc_build/ibusal_40_build/ibusal_40/IBUSAL40_System_Definition.xml"/>
        <fileset dir="${r'$'}{build.drive}/s60/tools/build_platforms/build/data" includes="S60_System*.xml"/>
        <pathelement path="${r'$'}{build.drive}/me/me_scd_desw/sysdef/System_Definition_PRODUCT.xml"/>
        <pathelement path="${r'$'}{build.drive}/mc/mc_build/${r'$'}{product.family}_build/4032_System_Definition.xml"/>
    </path>
    
The order of the files is significant. If building Symbian OS, the Symbian System Definition file must come first. Here both ``fileset`` and ``pathelement`` are used. ``pathelement`` selects just one file whereas a ``fileset`` can use wildcards to select multiple files or handle problems of filenames changing across different platform releases.

2. Determine if an existing build configuration in any of the build model sections of the files are suitable for what needs to be built. A build configuration typically looks something like this:

.. code-block:: xml

    <configuration name="foo_config" description="Build foo">
         <unitListRef unitList="foo_list"/>
        
         <task><buildLayer command="bldmake bldfiles" unitParallel="Y"/></task>
         <task><buildLayer command="abld export" unitParallel="Y"/></task>
         <task><buildLayer command="abld makefile" targetList="default" unitParallel="Y" targetParallel="N"/></task>
         <task><buildLayer command="abld resource" targetList="default" unitParallel="N" targetParallel="N"/></task>
         <task><buildLayer command="abld library" targetList="default" unitParallel="N" targetParallel="N"/></task>
         <task><buildLayer command="abld target" targetList="default" unitParallel="Y" targetParallel="Y"/></task>
         <task><buildLayer command="abld final" targetList="default" unitParallel="N" targetParallel="N"/></task>
         <task><buildLayer command="abld -what export" unitParallel="Y"/></task>
         <task><buildLayer command="abld -what target" targetList="default" unitParallel="Y" targetParallel="Y"/></task>
         <task><buildLayer command="abld help" unitParallel="Y"/></task>
         <task><buildLayer command="abld -check build" targetList="default" unitParallel="Y" targetParallel="Y"/></task>
    </configuration>

A ``unitListRef`` includes a ``unitList`` defined somewhere else as part of this configuration. The ``buildLayer`` elements define ``abld`` steps to run on each component. If an existing configuration is not sufficient a new one must be defined in a separate file (which should be included in the ``path`` type).

3. Define the ``sysdef.configurations`` Ant property to contain a comma-separated list of build configuration names that must match the ``name`` attribute of the ``configuration``. Each configuration will be built in turn in the ``compile-main`` Ant target.

Note: Build will fail if compilation error exceeds the number specified in ``build.errors.limit``. Default value is ``0`` and set it to ``-1`` to ignore this.

.. index::
  triple: Builds; EBS; EC

EBS and EC compilation
----------------------

If you want to get Helium to switch compiler version you need to define the HLM_RVCT_VERSION environment variable (Nokia specific feature)::

    set HLM_RVCT_VERSION=22_593


The setting could be mentioned under the configuration's Helium bootstrapper.


By default Helium is configured to run EBS builds. The ``build.system`` property determines what build system to use. An EC build can be run from the command line using::

    hlm <build target> -Dbuild.system=ec-helium


EC build could be configured to be running in parallel (default) or in serial mode (1 node build)::

    hlm <build target> -Dbuild.system=ec-helium -Dec.mode=serial

Also the --emake-debug could be configured either by the environment using the EMAKE_DEBUG variable or using the ``emake_debug_flag`` property. Its default value is 'g'.


SBS (Raptor) compilation
------------------------

.. toctree::
   :maxdepth: 1

   sbs


.. index::
  single: Stage - Post Build

Stage: Post Build
=================

.. index::
  single: SIS Files

Sis Files
---------
SIS files can be built during the postbuild stage. The ``sis.config.file`` property defines the path to a :ref:`common-configuration-format-label` file, e.g.

.. code-block:: xml

    <build>
        <config abstract="true">
            <set name="makesis.tool" value="${r'$'}{build.drive}\epoc32\tools\makesis.exe"/>
            <set name="signsis.tool" value="${r'$'}{build.drive}\epoc32\tools\signsis.exe"/>
            <set name="build.sisfiles.dir" value="${r'$'}{build.sisfiles.dir}"/>
            <set name="key" value="${r'$'}{build.drive}\s60\tools\taskmgr\internal\sis\RDTest_02.key"/>
            <set name="cert" value="${r'$'}{build.drive}\s60\tools\taskmgr\internal\sis\RDTest_02.der"/>
            <config>
                <set name="name" value="ScreenGrabber_3"/>
                <set name="path" value="${r'$'}{build.drive}\s60\tools\screengrabber\sis"/>
            </config>
            <config>
                <set name="name" value="app_trk"/>
                <set name="path" value="${r'$'}{build.drive}\s60\tools\trk\sis"/>
            </config>
        </config>
    </build>

The propertes are:

.. csv-table:: Property descriptions
   :header: "Property", "Description", "Values"

   "``makesis.tool``", "The path for the makesis tool that builds a .sis file.", ""
   "``signsis.tool``", "The path for the signsis tool that signs a .sis file to create a .sisx file.", ""
   "``publish.unsigned``", "This will copy .sis files into ${r'$'}{build.output.dir}/sisfiles.", "true, false"
   "``build.sisfiles.dir``", "The directory where the .sis file should be put.", ""
   "``key``", "The key to use for signing.", ""
   "``cert``", "The certificate to use for signing.", ""
   "``name``", "The name of the .pkg file to parse.", ""
   "``sis.name``", "The name of the .sis file to create. If omitted it will default to the name of the .pkg file.", ""
   "``path``", "The path where the .pkg file exists as input to building the .sis file.", ""
   
Configuration enhancements
::::::::::::::::::::::::::

*Since Helium 7.0.*

The configuration method above will be replaced by a more flexible approach:

.. csv-table:: Property descriptions
   :header: "Property", "Description", "Values"

   "``makesis.tool``", "The path for the makesis tool that builds a .sis file.", ""
   "``signsis.tool``", "The path for the signsis tool that signs a .sis file to create a .sisx file.", ""
   "``build.sisfiles.dir``", "The directory where the .sis file should be put.", ""
   "``key``", "The key to use for signing.", ""
   "``cert``", "The certificate to use for signing.", ""
   "``input``", "The full path and filename of the input file. This can be a .pkg file, for generating a SIS file, a .sis file for signing, or a .sisx file for multiple signing.", ""
   "``output``", "The full path and filename of the output file. This is only needed if the location or name needs to be different from the default, which is that the file extension changes appropriately.", ""

Also a ``sis.config.name`` property is added that allows the name of a <config> block to be supplied. This can be overridden to allow particular subsets of configurations to be built.

Checking Stub SIS files
-----------------------
This step involves checking stub sis files published to ``z:/epoc32/data/z/system/install`` and it ensures that only valid stub sis files are published.The target is included in postbuild and using ParseStubSis.pl script to do the work, it will run automatically and save the output in stubresult.log.xml. It can also be run from the command line by using::

    hlm check-stub-sis
    
It checks all files in the target folder and renames the invalid sis files with .bak extention. 

.. index::
  single: S60 3.2 Localisation

Stage: S60 3.2 Localisation
===========================

.. csv-table:: Ant property descriptions
   :header: "Property", "Description", "Default Values"

   "``localisation.language.file``", "This defines where to find the languages.xml database.", "/epoc32/tools/s60tools/languages.xml"
   "``rombuild.config.file``", "This key defines  where this parsed file will be located.", ""
   "``localisation.files``", "This key  defines which files should be used to localise the build.", "-i ${r'$'}{build.drive}/epoc32/tools/s60tools/LocInfo_input_S60.txt"
   "``localisation.tool``", "This key defines which tool should be used to localise the build area (localise-resources or localisation-s60-localiser).", "localise-resources"

The process uses the information from the languages.xml to know what languages have to be localised. In order to have language pack configured correctly you also have to configure them (as explained in the next section).

.. index::
  single: Creation of core, language pack and customer variant images

Creation of core, language pack and customer variant images
-----------------------------------------------------------

Core, language pack and customer variant images are created automatically in product-build. 
They can also be created separately calling localisation target::

  hlm -Dbuild.number=xx localisation


Stage: ROM creation
===================

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
 
.. index::
  single: Legacy ROM creation

.. _ROM-creation-label:

Stage: Legacy ROM creation
==========================

A S60 3.2 build uses the localisation target which calls localisation-roms. A S60 5.0 build only requires the localisation-roms target since localisation is done differently.

There are 2 targets used to create the ROM images these are 'ee-roms' and 'localisation-roms'. The 'ee-roms' target
builds an Engineering English version and the 'localisation-roms' target builds all the localised ROM images. Both require
some configuration particularly the 'localisation-roms' target so that it knows which variants to build etc. This configuration
is explained below but 1st here is an example of how to create the EE ROM image using Helium::

  hlm -Dbuild.number=xx ee-roms
  
where xx is the build number.

To see an example of how to build the localised versions click :ref:`localised example <localisation-label>`:

.. index::
  single: ROM Image configuration

Legacy ROM Image configuration
------------------------------

Engineering English ROMs, including debug/trace images, can be configured per build configuration. The path to the configuration file is defined by the ``rombuild.config.file`` property. The :ref:`common-configuration-format-label` is used, e.g.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>
    <build>
        <config name="PRODUCT" abstract="true">
            <set name="rommake.cmt.path" value="${r'$'}{build.drive}\epoc32\rombuild"/>
            ....
            <!-- GUI images -->
            <set name="rommake.args" value="-rebldxld -es60ibymacros -DS60_IN_ROM"/>
            
            <config name="ee_roms">
                <config name="flash">
                    <set name="image.type" value="rnd"/>
                </config>
            </config>
        </config>
    </build>

The properties that can be set for configuring each ROM image are described below:

.. csv-table:: Property descriptions
   :header: "Property", "Description", "Values"

   "``output.makefile.template``", "This defines the name of the output makefile (MUST NOT contain path info).", "${r'$'}{rombuild.makefile.name}"
   "``main.makefile.template``", "This defines the location of the main part of the makefile (template).", "${r'$'}{mc_5132_build.dir}/imaker.mk"
   "``flash.makefile.template``", "This defines template location for flash makefile targets (ee roms).", "${r'$'}{mc_5132_build.dir}/flash.mk"
   "``mytraces.file``", "The path for the mytraces.txt file that contains the list of debug binaries to include. (Template)", ""
   "``version.product.name``", "The name of the product that appears in the version string.", "e.g. N91"
   "``version.pd.milestone``", "The current PD milestone.", ""
   "``version.pr``", "The current PR branch number.", ""
   "``version.bandvariant``", "The band variant.", ""
   "``version.buildnumber``", "The build number. This should be set to the Ant property.", "${r'$'}{build.number} (default)"
   "``version.variant``", "The variant version number.", ""
   "``version.product.type``", "The product type shown in the version string.", "e.g. RM43"
   "``version.rimcycle``", "The year and week of the current RIM cycle.", ""
   "``rom.id``", "An identifier for the ROM image filenames. Currently based on Ant ``build.id`` property.", ""
   "``rommake.hwid``", "The hardware ID provided to the ROM build tool.", ""
   "``rommake.product.name``", "The product name provided to the ROM build tool.", "e.g. devlon4"
   "``rom.output.dir``", "The directory where the ROM image files will be copied.", ""
   "``cmt``", "The CMT to use (if included).", ""
   "``image.ui``", "The UI type.", "gui, text"
   "``image.iby``", "The path for the top-level .iby file", ".iby path"
   "``image.nocmt``", "Whether the image should include a CMT or not", "true, false (default)"
   "``image.name.extension``", "A text extension added to the image filename.", "Optional"
   "``version.copyright``", "Copyright text used in the version string.", ""
   "``core.template``", "The template for the core version string format.", ""
   "``variant.template``", "The template for the variant version string format.", ""
   "``uda.template``", "The template for the UDA version string format.", ""
   "``model.template``", "The template for the model version string format.", ""
   "``core.txt.path``", "Path to the sw.txt version file.", ""
   "``variant.txt.path``", "Path to the langsw.txt version file.", ""
   "``model.txt.path``", "Path to the model.txt version file.", ""
   "``uda.txt.path``", "Path to the UDA version file.", ""
   "``mytraces.binaries``", "A list of binaries that should be ``UDEB``. The list will be included in ``mytraces.txt``. Either comma-separated items can be used or multiple properties defined.", ""
   "``build.parallel``", "Defines if a group is buildable in parallel.", "true/false"


Ant properties can be used and they will be replaced by their values before the file is processed.

All abstract ``<config>`` element will be considered as makefile group target. You have to ensure that you defined an ee_roms abstract spec to be able to build EE roms.

This example configuration will build one rom during ee_roms call that will use flash template:

.. code-block:: xml
    
   <config name="ee_roms" abstract="true">
       <config name="flash">
            <set name="flash.id" value="ui_rom" />
       </config>
   </config>

Mandatory keys:
    "``flash.id``" defines a uniq id for the rom creation, used to define makefile template.


.. index::
  single: Main makefile template

Main makefile template
----------------------

The ROM image creation tools use a makefile template to generate a target for each image. The main.makefile.template is used as the top-level part of the makefile, you can define any common custom steps in there. The template allows us to easily add any custom dependencies before creating the variant (also post steps could be added). The current version of the main makefile template should look like that, dont't forget it is tied to the product family.

.. index::
  single: Xinclude
  
.. _`Xinclude-label`:

Xinclude
---------

Xinclude is a generic tool to include lists of files in tasks. However, Xinclude for ROM creation is deprecated, so please ensure you are using iMaker for all ROM image creation. Click on :ref:`iMaker-label` for details.  


.. _localisation-label:
  
Legacy Customer variant configuration 
:::::::::::::::::::::::::::::::::::::
To create a new customer variant, just add a spec of the type customer: e.g:

.. code-block:: xml

  <config type="customer">
      <set name="customer.id" value="100"/>
      <set name="customer.revision" value="2"/>
      <set name="description" value=""/>
      <set name="compatible.languagepack" value="01,03"/>
  </config>


This specification must be added in the specification of the appropriate region (western, china, japan or thai).

For each customer specification, helium creates 
  * the customer variant image 
  * the flash configuration file (during publishing.).

If compatible.languagepack property is omitted, the system assumes the customer variant is compatible with all language packs. A flash configuration file is created for each language pack.

In case a variant created with a previous build is re-used with the current build, an extra property must be declared: e.g:

.. code-block:: xml

  <config type="customer">
      <set name="customer.image.version.name" value="10.30"/>
      <set name="customer.id" value="101"/>
      <set name="description" value="OPERATOR_UK"/>
      <set name="compatible.languagepack" value="01"/>
  </config>


customer.image.version.name is the build ID with which the re-used variant was created.


.. index::
  single: Trace image creation

Trace image creation
--------------------
Initial support for recompiling and creating rom images is provided by the build-traces target. This feature will be refactored and revised, so the details will still change.

.. csv-table:: Ant property descriptions
   :header: "Property", "Description", "Values"

   "``tracebuild.tracetype``", "This defines the type of traces to create", "general, phone or all"
   "``tracebuild.product``", "This defines the product for which to create images.", ""
   "``tracebuild.variant``", "This defines the imaker target to use in image creation", ""


.. index::
  single: Stage - Publishing

Stage: Publishing
=================

.. index::
  single: Uploading to Diamonds

Uploading build information to Diamonds web application
-------------------------------------------------------

Diamonds is a utility tool that keeps track of build and release information. See the **Metrics** manual under section `Helium Configuration`_ for more info.

.. _Helium Configuration: ../metrics.html#helium-configuration


.. index::
  single: Zipping Build area

Zipping of the build area
-------------------------

The Engineering English build area is archived in the ``zip-ee`` target. Zipping of the localised build area is done by ``zip-localisation`` target. These properties need to be set:

``zip.config.file``
    Location of the config file.
    
``zips.ee.spec.name``
    Spec name for ee zipping (e.g. "ee").
    
``zips.localised.spec.name``
    Spec name for localised build area zipping (e.g. "localised").

The ``zip.config.file`` property defines the path to a :ref:`common-configuration-format-label` file that defines the content of the zips created. It can consist of multiple configs, e.g.

.. code-block:: xml

    <build>
        <config name="ee" abstract="true">
            <set name="max.uncompressed.size" value="2000000000"/>
            <set name="max.files.per.archive" value="65000"/>
            <set name="archive.tool" value="7za"/>
            <set name="root.dir" value="${r'$'}{build.drive}\"/>
            <set name="archives.dir" value="${r'$'}{build.output.dir}\build_area\engineering_english_test"/>
            <set name="temp.build.dir" value="${r'$'}{temp.build.dir}"/>
            <config>
                <set name="name" value="${r'$'}{build.id}_dev_flashfiles"/>
                <set name="include" value="output\development_flash_images\"/>
                </config>
                <config>
                    <set name="name" value="${r'$'}{build.id}_release_flashfiles"/>
                    <set name="include" value="output\release_flash_images\"/>
                </config>
            </config>
            <config name="localised" abstract="true">
                <set name="max.uncompressed.size" value="2000000000"/> 
                <set name="max.files.per.archive" value="65000"/>    
                <set name="archive.tool" value="7za"/>
                <set name="root.dir" value="${r'$'}{build.drive}\"/>
        
                <set name="archives.dir" value="${r'$'}{build.output.dir}\build_area\localised"/>
                <set name="temp.build.dir" value="${r'$'}{temp.build.dir}"/>
    
                <config>
                    <set name="name" value="${r'$'}{build.id}_dev_flashfiles_ee"/>
                    <set name="include" value="output\development_flash_images\engineering_english\"/>
                </config>
                
                <config>
                    <set name="name" value="${r'$'}{build.id}_dev_flashfiles_localised"/>
                    <set name="include" value="output\development_flash_images\localised\"/>
                </config>
            </config>
        </config>
      
        <config name="policy">
            <config>
                <set name="name" value="${r'$'}{build.id}_dev_flashfiles"/>
                <set name="include" value="output\development_flash_images\"/>
                <set name="mapper" value="policy"/>
                <set name="policy.internal.name" value="really_confidential_stuff"/>
                <set name="policy.filenames" value="Distribution.Policy.S60"/>
            </config>
        </config>

        <config name="policy.remover">
            <config>
                <set name="name" value="${r'$'}{build.id}_s60_osext"/>
                <set name="include" value="s60\osext\"/>
                <set name="mapper" value="policy.remover"/>
                <set name="policy.internal.name" value="really_confidential_stuff"/>
                <set name="policy.filenames" value="Distribution.Policy.S60"/>
                <set name="policy.root.dir" value="${r'$'}{root.dir}/s60"/>
            </config>
        </config>
      
        <config name="scanner">
            <config>
                <set name="name" value="${r'$'}{build.id}_dev_flashfiles"/>
                <set name="scanners" value="abld.what"/>
                <set name="abld.buildpath" value="path/to/component/group"/>
                <set name="exclude" value="**/*.dll"/>
                <set name="exclude.lst" value="${r'$'}{build.drive}/exclude.lst"/>
            </config>
        </config>

    </build>



.. csv-table:: Common property descriptions
   :header: "Property", "Description", "Values"   

   "``temp.build.dir``", "Directory to store temporary files generated during the process.", ""
   "``name``", "The name of the zip file.", ""


.. csv-table:: File System scanner property descriptions (default)
   :header: "Property", "Description", "Values"

   "``include``", "Path to include files/directories in the zip. Follows the Ant fileset convention.", ""
   "``exclude``", "Path to exclude files/directories in the zip. Follows the Ant fileset convention.", ""
   "``exclude.lst``", "Location of a file containing an exclude list(one pattern per line).", ""
   "``distribution.policy.s60``", "Defines that the included files will be filtered based on the value of the ``Distribution.Policy.S60`` files. The file found closest to the root will override those in subdirectories.", "The value found in the file, e.g. 0 or 1. This can be negated by putting a '!' in front."


.. csv-table:: Abld what scanner property descriptions (abld.what)
   :header: "Property", "Description", "Values"

   "``exclude``", "Path to exclude files/directories in the zip. Follows the Ant fileset convention.", ""
   "``exclude.lst``", "Location of a file containing an exclude list(one pattern per line).", ""
   "``abld.buildpath``", "The path to an bld.inf directory. The files built from this component will be included.", ""
   "``abld.type``", "For what platform should abld be run for.", "armv5"
   "``abld.epocroot``", "To specify an EPOCROOT other than \\.", ""


.. csv-table:: Default Mappers property description (default)
   :header: "Property", "Description", "Values"

   "``name``", "The name of the zip file.", ""
   "``max.uncompressed.size``", "Maximum size in bytes of the content being included in each zip file. If the included content exceeds this, multiple zips will be created.", ""
   "``max.files.per.archive``", "Maximum number of files that can be included in an archive. If the total exceeds this, multiple zips will be created.", ""
   "``archive.tool``", "The command-line archiving tool. 7zip and zip are supported.", "7za, zip"
   "``root.dir``", "The root directory of the content being zipped.", ""
   "``archives.dir``", "The directory where the zip files are saved to.", ""
   "``zip.root.dir``", "The root directory for the content inside the zip file.", "root.dir value"


.. csv-table:: Policy Mappers property description (policy)
   :header: "Property", "Description", "Values"

   "``name``", "The name of the zip file.", ""
   "``policy.internal.name``", "Suffix of the archive that contains the confidential content.", "internal"
   "``policy.filenames``", "Comma separated list of policy filename.", "Distribution.Policy.S60"
   "``archive.tool``", "The command-line archiving tool. 7zip and zip are supported.", "7za, zip"
   "``archives.dir``", "The directory where the zip files are saved to.", ""
   "``policy.csv``", "This property defines the location of the policy definition file.", ""
   "``policy.default.value``", "This property defines the policy value when policy file is missing or invalid (e.g. wrong format).", "9999"

The policy mapper enables the sorting of the content compare to its policy value. The mapper is looking for a policy file in the file to archive directory.
If the distribution policy file is missing then the file will go to the ``policy.default.value`` archive. Else it tries to open the file which
MUST be ASCII encoded, and have its content matching the following expression: ``^\\d+\\s*$``.
File not matching those specifications will be reported as invalid and the assiociated content will go to the ``policy.default.value`` archive.

Archive filenames are generated the following way:

Policy value is 0::
   
   ${r'$'}{archive.dir}/${r'$'}{name}.zip

Policy value is different from 0::
   
   ${r'$'}{archive.dir}/${r'$'}{name}_${r'$'}{policy.internal.name}_<policy_value>.zip

If the policy file is missing or its content is invalid ot the olicy value is not found in the ``${r'$'}{policy.csv}``::
   
   ${r'$'}{archive.dir}/${r'$'}{name}_${r'$'}{policy.internal.name}_${r'$'}{policy.default.value}.zip


.. csv-table:: Policy Remover Mappers property description (policy)
   :header: "Property", "Description", "Values"

   "``name``", "The name of the zip file.", ""
   "``policy.internal.name``", "Suffix of the archive that contains the confidential content.", "internal"
   "``policy.filenames``", "Comma separated list of policy filename.", "Distribution.Policy.S60"
   "``archive.tool``", "The command-line archiving tool. 7zip and zip are supported.", "7za, zip"
   "``archives.dir``", "The directory where the zip files are saved to.", ""
   "``policy.root.dir``", "This property allows the user to restrict the root of policy scanning.", "root.dir value"
   "``policy.default.value``", "This property defines the policy value when policy file is missing or invalid (e.g. wrong format).", "9999"

The remover mapper in addition to policy mapper behaviour will remove the content not required for the build.
The removal process is based on the policy.csv file information, content will be kept in the following cases:

 * Included in build column is ``yes``    
 * Included in build column is ``bin``    


Two additionals removers have been introduced to support action from SFL and EPL column, you use the following
named mappers to use them:

 * sfl.policy.remover based on the 4th column of the csv
 * epl.policy.remover based on the 5th column of the csv

They support the same set of configuration properties as the default policy.remover.

 
.. index::
  single: Zipping SUBCON

Subcon zipping
--------------

Subcon zipping is also configured using the same XML format as ``zip-ee`` and implemented in the ``zip-subcon`` target. A ``zips.subcon.spec.name`` property must be defined but currently it is still a separate configuration file.

.. index::
  single: Zipping .loc files

Zipping .loc files
------------------

```zip-loc-files``` -target finds, sorts into language specific folders and archives all the .loc files from the build area. Usage::

   hlm -Dbuild.number=XX zip-loc-files

The following properties are needed (default values defined in helium.ant.xml):

- loc.temp.dir - the temporary directory used by zip-loc-files
- loc.output.dir - the directory where the output zip file is stored
- loc.output.filename - the name of the output-file (xxx.zip)
- loc.files.zipper - The location of the tool (should not be changed)
  

.. index::
  single: Stage - Releasing

Stage: Releasing
================

A published build can be made into a release by running the command::

    hlm release

from the root of the directory on the network where the build is located. This will create a matching release directory and copy the appropriate files there. The selected files are defined in ``release.ant.xml``.

.. index::
  single: Stage - Delta Releasing

Stage: Delta releasing
======================

Introduction:

A delta release is a zip file with only the changed and new files between two build areas. A xml file is also generated that contains the list of files removed between the two build areas. This xml file is read by SymDEC and deletes these files.

Prequisities for automated use:

- Publish is run after this stage

Each build should run the 'delta-zip' target which creates a delta from a previous build to the current one. (This target looks at previous builds in the publish dir for the md5 file and chooses the most recent one).

Optionally: A previous builds md5 can be passed as a argument, this might be the last bi-weekly release or used when builds are not published (The last build would have run the delta-zip target)::

  hlm delta-zip -Dold.md5.file=e:\wk01_build\output\build_area\delta_zip\0.0742.3.X.15.md5 -Dold.md5.file.present=y
  
Exclude directories from the zip::

  <property name="delta.exclude.commasep" value="epoc32_save.zip,output/**/*,delta_zips/**/*,temp/**/*"/>

Uploading of this into Grace is similar to the grace-upload target::

  hlm delta-zip-grace-upload

Output::

  Z:\output\build_area\delta_zip
   + delta_zip.zip
   + specialInstructions.xml
   + release_metadata.xml


.. index::
  single: Stage - Release Notes

Stage: Release Notes
====================

Introduction:

This generates a release note by modifying a template (that you can edit yourself) with values from the build and Synergy.

Usage::

  hlm release-notes -Dbuild.number=1

Define in your build configuration the path to the config of relnotes::

  e.g. <property name="relnotes.config.dir" value="${r'$'}{helium.dir}/../mc_config/${r'$'}{product.family}_config/${r'$'}{build.name}/relnotes"/>

The contents of "config_template" in helium/extensions/nokia/config/relnotes should be copied to the appropriate directory::

  e.g. mc/mc_config/mc_5132_config/mc_5132/relnotes

Contents of template:
 * logo.png : the logo of your product
 * template.rtf : the document that is modified to form the output
 * relnotes_properties.ant.xml : the names of the tokens in template.rtf that will be replaced
                  Many of the values are commented out as they change rapidly and will need to be added to the output RTF file manually.
 * relnotes.properties : the values of the tokens
                         New values can be added e.g. token1=1.0 and referenced in relnotes.xml by ${r'$'}{token1}
                         If you want a link to a file start with .\\filename or .\\folder\\filename or \\\\share1\\file

Project names can be looked up from the BOM and are set into properties, see ``config_template/relnotes/relnotes_properties.ant.xml`` for example

If you want to add a new value to the output that is dynamic then you should:

1) Open your template.rtf in Word and add some text that is unique eg. NewValueHere
2) Open your template.rtf in a plain text editor such as UltraEdit and search for your value. You may find it is split over two lines or contains RTF markup language mixed into the value e.g. New\\pardValueHere
   If this is the case reformat so you get the value all on one line and remove extra markup.
3) Check your template still works in Word
4) Add a new property to relnotes.properties or use existing properties from Helium or your build config files
5) Add a new replace statement to relnotes_properties.ant.xml that references the property in step 4

Output::

  Z:\output\relnotes

.. index::
  single: Executing a build

Executing a build
====================

This section explains how to execute a general build step-by-step.



.. index::
  single: Running build operations

Running build operations
------------------------

Needed configuration
::::::::::::::::::::

TODO

Setting the build number
::::::::::::::::::::::::

The ``build.number`` property is typically not defined in a configuration file, as it changes for every new build. It should be defined as a command line parameter::

    -Dbuild.number=123

A shortcut can also be used::    

    -Dbn=123    

.. index::
  single: Setting the team property

.. _Setting-Team_properties-label:

Setting the team property
:::::::::::::::::::::::::

SET TEAM=<team-name> (this defines which team specific .xml file from /mc/mc_build/teams is used for build configuration).

Also see :ref: `Team-Properties-label` for more information.

.. index::
  single: ANT properties

ANT properties
::::::::::::::

build.configuration
build.drive
ec.cluster.manager
major.version
minor.version
prep.root.dir
product.name


.. index::
  single: Build Types

Types of build
::::::::::::::

There are different types of builds that can be run depending on the required output.

.. index::
  single: Build Main

build-main
::::::::::

Before this phase it is needed to run the prebuild command (hlm prebuild -Dbuild.number=123) which creates necessary folders to the build area.

Build-main phase is used to compile the components defined in the build.configuration property which refers to defined configuration in System_Definition.xml file(s) (ANT property system.definition.files in /mc/mc_build/PLATFORM/PLATFORM_build.ant.xml). The command to run is: hlm build-main -Dbuild.number=123


.. index::
  single: Product-Build

product-build
:::::::::::::

A product build executes the typical stages for building product software and ROM images. Generally this involves building all the software completely from scratch. It can be run using the command:
  hlm product-build -Dbuild.number=123

This can be run from a product build configuration directory, e.g. <tt>/mc/mc_build/mc_4031_build/cogsworth</tt>.

Product-build command combines all needed subcommands for doing a build. The subcommands run in product-build are:
prep -> Prepares the build area (see prep instructions above)
build-generic -> Runs prebuild, build-main, postbuild, flashfiles, java-certification-rom, zip-main and publish-generic commands.
build-variants -> Runs notify-errors, mobilecrash-prep, zip-flashfiles, zip-localization and publish-variants commands.
final -> Notifies of errors and creates log files.

.. index::
  single: platform build

platform-build
::::::::::::::

A platform build executes the typical stages for building a platform deliverable. This is more limited than a product build, as some of the stages are unnecessary, e.g. building variant ROM images.

The commands executed are:
prep -> Prepares the build area
build-main -> Compiles the components defined in the build.configuration
flashfiles -> Creates flashfiles
zip-main -> Zips the build area

.. index::
  single: Incremental Build

Incremental build
:::::::::::::::::

An incremental build will use a previous completed product build as a starting point (probably unzipping it during preparation) and will clean and rebuild a handful of components. This is useful for testing platform component releases and off-cycle integration operations. An incremental build can be run using the command::

  hlm incremental-build

.. Note::

  Incremental builds are not currently supported.


Cenrep creation (S60 3.2.3 - 5.x)
:::::::::::::::::::::::::::::::::
<#if !(ant?keys?seq_contains("sf"))>
See: http://configurationtools.nmp.nokia.com/builds/cone/docs/cli/generate.html?highlight=generate
</#if>

The target ``ido-gen-cenrep`` can be used to run the ConE Tool to generate cenreps.

* IDO can use the ido-gen-cenrep to generate the cenreps which are IDO specific.
* We should pass the sysdef.configurations.list as parameter to ido-gen-cenrep target. Else it will use the defualt one of helium.

Example:
:::::::::::::::::::::::::::::::::

Below example will generate the cenrep only for IDO specific confml files.

.. code-block:: xml

    <target name="ido-generate-cenrep">
        <antcall target="ido-gen-cenrep">
            <param name="sysdef.configurations.list" value="dfs_build"/>    
        </antcall>
    </target>

Below example will generate the cenreps for S60 SDK.

.. code-block:: xml

    <target name="generate-s60-cenrep">
        <hlm:conEToolMacro>
            <arg name="output" value="<Path to output log file>"/>
            <arg name="path" value="build.drive/epoc32/tools/" />
            <arg name="-v" value="5" />
            <arg name="-p" value="\epoc32\rom\config" />
            <arg name="-o" value="\epoc32\release\winscw\urel\z " />
            <arg name="-c" value="s60_root.confml" />
        </hlm:conEToolMacro>
    </target>

By using conEToolMacro you can pass any arguments which are mentioned in the above link.

.. code-block:: xml

    <target name="generate-s60-cenrep">
        <hlm:conEToolMacro>
            <arg name="output" value="<Path to output log file>"/>
            <arg name="path" value="<path to cone.cmd file>" />
            <arg name="-v" value="<verbose level 0 - NONE (all), 1- CRITICAL, 2- ERROR, 3- WARNING, 4- INFO, 5- DEBUG>" />
            <arg name="-p" value="<path to root folder containing conml file>" />
            <arg name="-o" value="<path to output folder on the SDK to generate output files.> " />
            <arg name="-c" value="<confml file name>" />
        </hlm:conEToolMacro>
    </target>
        
After running this command generated file can be found from <temp.build.dir>/<build.id>_cenrep_includefile.txt


Running individual build commands
---------------------------------

Individual build stages can be run from command line with a command "hlm _COMMAND_ -Dbuild.number=123". Each of the commands defined in this guide can be run individually. The functionality of a certain command can be looked up by searching '<target name="COMMAND"' from files in mc directory.


.. index::
  single: Build Types

Customising the build
---------------------

TODO

Customising the build sequence
::::::::::::::::::::::::::::::

TODO

Overriding properties
:::::::::::::::::::::

TODO
    

.. index::
  single: Integration Help

Integration Help
================

This section provides information about the various integration help programs included into Helium framework. The tools described in this section should help the build manager in his pre-build work (e.g. merge detection,...).

.. index::
  single: Cleaning the build machines

Cleaning the build machines
---------------------------

After several builds have been run it is necessary to clean the build machine of old work areas. Deleting several work areas run under the same username can be done using the ``clean-pc`` command, which displays a dialog showing the build area directories. Select the checkboxes of those to be deleted.


.. index::
  single: Advanced Usage

Advanced Usage
=================


.. index::
  single: UDA (using iMaker)

UDA (using iMaker)
------------------

UDA creation using iMaker follows the same process, it uses a template that requires the following keys to be defined.

"``uda.id``" this key defines uniquely the uda.
"``content.dir``" defines the location of UDA content.

This is a simple example of uda spec:

::

    <config name="uda">
      <set name="uda.id" value="myuda" />
      <set name="content.dir" value="${r'$'}{build.drive}/uda1/" />
    </config>

To build the uda you have to run the following Ant target: (use uda.makefile.target to specify which rom you want to build)
  hlm uda-roms -Dteam=kawa -Dbuild.number=xx


.. index::
  single: Core and Variant images creation

Core and Variant images creation
--------------------------------

Core and variant images are created automatically in product-build. They can also be created separately calling do-localisation target::

  hlm localisation-roms -Dteam=kawa -Dbuild.number=xx

Variation (S60 3.2.3 - 5.x)
---------------------------

See http://delivery.nmp.nokia.com/trac/imaker/wiki/iMakerUseCaseCustomerVariantConfml

Variation (S60 3.2)
-------------------

In the new process the variation handling deviate from regular Nokia variation rule as the backup/export/restore process from Creator.pl has been dropped. Now each variant is self contained, which means the content must be reference from the variation folder! On the same way  language pack configuration is automated, which means that branching files like ``languages.txt``, ``lang.txt``... is strictly forbiden.

Structure and Naming
::::::::::::::::::::

The variation folder naming must match that rule ``.+_${r'$'}{variant.id}``.

Finally your variation folder must have the following structure::

    + variation
        + euro1_01
            + data
                + VariantData_01.xml
        + euro2_02
            + data
                + VariantData_02.xml
        + japan_15
            + data
                + VariantData_15.xml
        + ...


Cenrep variation
::::::::::::::::


Developer has to create a VariantData_${r'$'}{variant.id}.xml file for each variant that references product one (SPP/PRODUCT process).

Example of an dummy PRODUCT variant configuration:

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>
    <Variant xmlns:xi="http://www.w3.org/2001/xinclude">
        <xi:include href="file:\\\%EPOCROOT%\spp_config\s60_32_config\PLATFORM_config\PLATFORM_PRODUCT_config\config\data\CenrepVar_PRODUCT\data\VariantData_PRODUCT.xml"/>
    </Variant>


To rebuild cenrep configuration using Customisation Tool for all variants you can use the following command:
    hlm -Dbuild.number=xx localisation-create-cenrep

Note: for Xinclude information see :ref:`Xinclude-label`:

.. index::
  single: iMaker image creation template

iMaker image creation template
------------------------------

::

   ###############################################################################
   # iMaker templates
   ###############################################################################
   
   # defining helium in the build area if not set by the environment
   HELIUM_HOME?=\mc\helium
   PYTHONPATH?=$(HELIUM_HOME)\install\python\lib\python2.4\win32;$(HELIUM_HOME)\tools\common\python\lib
   
   # using winimage from helium delivery.
   WINIMAGE_TOOL=$(HELIUM_HOME)/tools/localisation/exports/winimage.exe
   
   CALL_IMAKER_PLATFORM=imaker -p$(PRODUCT_NAME) -c$(COREPLAT_NAME) -f $(E32ROMCFG)/helium_features.mk
   CALL_IMAKER=imaker -p$(PRODUCT_NAME) -c$(COREPLAT_NAME) $(if $(UI_PLATFORM),-u$(UI_PLATFORM)) -f $(E32ROMCFG)/helium_features.mk
   CALL_TARGET=imaker -p$(PRODUCT_NAME) -c$(COREPLAT_NAME) -f $(E32ROMCFG)/$(COREPLAT_NAME)/$(PRODUCT_NAME)/mc_imaker.mk
   
   transfer_option=$(foreach option,$1,$(if $($(option)),"$(option)=$($(option))",))
   
   #
   # Variation handling
   #
   unzip_%:
       @echo Unzipping variation $*...
       -@unzip -o -qq -d $(subst \,/,$(EPOCROOT)) /output/build_area/localised/delta_$*_package.zip
   
   
   include helium_features.mk
   ###############################################################################   


.. index::
  single: Flash makefile template

Flash makefile template
-----------------------

This is the currently used template for flash rom type.

::

   ###############################################################################
   # Flash template
   ###############################################################################
   
   flash${r'$'}{flash.id}${r'$'}{image.type}: TYPE=${r'$'}{image.type}
   flash${r'$'}{flash.id}${r'$'}{image.type}: NAME=${r'$'}{build.id}_$(TYPE)$(if ${r'$'}{flash.id},_${r'$'}{flash.id},)
   flash${r'$'}{flash.id}${r'$'}{image.type}: WORKDIR=${r'$'}{rom.output.dir}/${r'$'}{rommake.product.name}/${r'$'}{image.type}
   flash${r'$'}{flash.id}${r'$'}{image.type}: OBYPARSE_UDEBFILE=${r'$'}{mytraces.file}
   flash${r'$'}{flash.id}${r'$'}{image.type}: FEAT_UDEBFILE=$(if "${r'$'}{mytraces.binaries}",1,0)
   flash${r'$'}{flash.id}${r'$'}{image.type}: BLDROM_OPTVAR=${r'$'}{rommake.flags}
   flash${r'$'}{flash.id}${r'$'}{image.type}: HWID=${r'$'}{rommake.hwid}
   flash${r'$'}{flash.id}${r'$'}{image.type}: OPTION_LIST=TYPE NAME WORKDIR OBYPARSE_UDEBFILE CORE_UDEBFILE BLDROM_OPTVAR HWID
   flash${r'$'}{flash.id}${r'$'}{image.type}: unzip_western
      -@echo $(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) flash
      -@$(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) flash
    
The target is using target specific variable to override the default iMaker values. The script also makes sure that the current environment is western, so do not need anymore to switch between environments. You can customize your target as needed, e.g. call custom scripts...

.. Note::
        Don't forget that all template are parsed and concatenated, which means a modification in the main one could affect any target one.

.. index::
  single: Create a customize makefile target

How to create a customize makefile target
-----------------------------------------

In order to create a custom makefile target for rom image creation you have to first create the makefile template: You will call your target test for example. In that case you have to create a test.mk file that should define your target. E.g

::
   
   ###############################################################################
   # Test template
   ###############################################################################
   
   flash_${r'$'}{target.name}_${r'$'}{image.type}: TYPE=${r'$'}{image.type}
   flash_${r'$'}{target.name}_${r'$'}{image.type}: OPTION_LIST=TYPE
      -@echo $(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) flash
      -@$(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) flash

Then you have to declare it into your configuration file, just add the following line to your main configuration:
::
   
   <set name="test.makefile.template" />

Then to create a ROM according to that template just add a specification to the configuration file::
   
   <config name="test">
       <set name="image.type" value="rnd,prd" />
       <set name="target.name" value="ui_rom" />
   </config>
 
This will create two targets in the generated makefiles: test_ui_rom_rnd and test_ui_rom_prd.

.. index::
  single: Language pack configuration

Language pack configuration
---------------------------

Please read the ``ROM Image configuration (using iMaker)`` part first to have a better understanding of this part.

.. index::
  single: Main Language configuration

Main configuration
------------------

These keys must be defined in order to enbable localisation/variation process.

.. csv-table:: Configuration property descriptions
   :header: "Property", "Description", "Values"

   "``zips.loc.dir``", "The directory where to find variation delta packages.", "${r'$'}{zips.loc.dir}"
   "``languages.xml.location``", "This defines where to find the languages.xml database.", "${r'$'}{localisation.language.file}"
   "``variation.dir``", "This defines the path where variation for a product is located.", "${r'$'}{mc_5132_config.dir}\${r'$'}{product.name}\variation"
   "``rombuild.config.file``", "That key defines where this parsed file will be located.", "${r'$'}{rombuild.config.file.parsed}"
   "``core.makefile.template``", "This defines what template to use for core creation.", "${r'$'}{mc_5132_build.dir}/core.mk"
   "``languagepack.makefile.template``", "This defines what template to use for core creation.", "${r'$'}{mc_5132_build.dir}/languagepack.mk"
   "``operator.makefile.template``", "This defines what template to use for core creation.", "${r'$'}{mc_5132_build.dir}/operator.mk"

Other keys could be defined accordingly to the template you are using.


.. index::
  single: Language pack configuration

Legacy Language pack configuration
----------------------------------

Language pack could be defined into the rom image configuration, the name of the template is "``languagepack``" (this is used to render the correct makefile template).
Example of configuration:

.. code-block:: xml
   
   <config name="languagepack">
       <set name="languagepack.id" value="01" />
       <set name="description" value="01" />
          <set name="default" value="01" />
       <set name="languages" value="01,02,03" />
       <set name="variation" value="western" />
   </config>

The following fields are mandatories to define a correct language pack:
"``variant.id``" defines the variant id from the variant chart.
"``description``" defines variant content (must not contains space).
"``default``" default language id.
"``languages``" comma separated list of languages to be included.
"``variation``" defines which variation to use (western, china, japan) You can define western variation at top level and override it on target.


.. index::
  single: Customer Variant configuration

Legacy Customer variant configuration
-------------------------------------

Customer variant could be define the same way.
Example:

.. code-block:: xml
   
   <config name="customer_variants" abstract="true">
   ...

      <set name="variation.dir" value="\path\to\customer\variants" />
      <config name="customer">
          <set name="customer.id" value="20" />
          <set name="description" value="OPERATOR" />
      </config>
      <config name="customer">
          <set name="customer.id" value="10" />
          <set name="description" value="orange" />
          ...
      </config>
        <config name="customer">
              <set name="customer.id" value="11" />
              <set name="description" value="orange_fr" />
        </config>
      ...
   </config>
      
Only description and customer.id and variation.dir are mandatory for customer variants.

The variant creation process is now working without any copy on top of epoc32 directory, you can override epoc32 content directly from the variant directory.

To run the creation of all images under the '''customer_variants''' group, just call the following command line on your configuration:

  hlm customer-roms -Dteam=kawa -Dbuild.number=xx 

If you just want to build one particular customer variant just invoke the following command:

  hlm customer-roms -Dteam=kawa -Dbuild.number=xx -Dcustomer.makefile.target=customer99rnd
  
The naming of the target follows this template: customer``customer.id````image.type``.


.. index::
  single: ATS - STIF, TEF, RTEST, MTF and EUnit

.. _`Stage-ATS-label`:

Stage: ATS - STIF, TEF, RTEST, MTF and EUnit (also Qt)
=======================================================

ATS testing is the automatic testing of the phone code once it has been compiled and linked to create a ROM image.

Explanation of the process for getting ATS (`STIF`_ and `EUnit`_) tests compiled and executed by Helium, through the use of the ``ats-test`` target.

http://developer.symbian.org/wiki/index.php/Symbian_Test_Tools

<#if !(ant?keys?seq_contains("sf"))>
.. _`STIF`: http://s60wiki.nokia.com/S60Wiki/STIF
.. _`EUnit`: http://s60wiki.nokia.com/S60Wiki/EUnit
</#if>

.. image:: ats.dot.png

Prerequisites
----------------

* `Harmonized Test Interface (HTI)`_ needs to be compiled and into the image.
* The reader is expected to already have a working ATS setup in which test cases can be executed.  ATS server names, 
  access rights and authentication etc. is supposed to be already taken care of.

<#if !(ant?keys?seq_contains("sf"))>
.. _`Harmonized Test Interface (HTI)`: http://s60wiki.nokia.com/S60Wiki/HTI
<#else>
.. _`Harmonized Test Interface (HTI)`: http://developer.symbian.org/wiki/index.php/HTI_Tool
</#if>

Test source components
-------------------------

Test source usually lives in a component's ``tsrc`` directory.  Test source components are created like any other Symbian SW component; 
there is a ``group`` directory with a ``bld.inf`` file for building, ``.mmp`` files for defining the targets, and so on.

The test generation code expects ``.pkg`` file in the ``group`` directory of test component to be compiled, to get the paths of the files 
(can be data, configuration, initialization etc. files) to be installed and where to install on the phone. 

Three STEPS to setup ATS with Helium
--------------------------------------

**STEP 1: Configure System Definition Files**
 If the tsrc directory structure meets the criteria defined in the `new API test automation guidelines`_, then test components 
 should be included in the System Definition files; **layers** in ``layers.sysdef.xml`` file and **configuration** in ``build.sysdef.xml`` 
 file (`Structure of System Definition files`_).
 
 <#if !(ant?keys?seq_contains("sf"))>
.. _`new API test automation guidelines`: http://s60wiki.nokia.com/S60Wiki/Test_Asset_Guidelines
.. _`Structure of System Definition files`: http://delivery.nmp.nokia.com/trac/helium/wiki/SystemDefinitionFiles
</#if>

A template of layer in layers.sysdef.xml

.. code-block:: xml

    <layer name="name_test_layer">
        <module name="module_name_one">
            <unit unitID="unit_id1" name="unit_name1" bldFile="path_of_tsrc_folder_to_be_built" mrp="" />
        </module>
        
        <module name="module_name_two">
            <unit unitID="unit_id2" name="unit_name2" bldFile="path_of_tsrc_folder_to_be_built" mrp="" />
        </module>
    </layer> 

* Layer name should end with **_test_layer**
* Two standard names for ATS test layers are being used; ``unit_test_layer`` and ``api_test_layer``. Test components (the``unit`` tags) 
  should be specified under these layers and grouped by ``module`` tag(s).
* In the above, two modules means two drop files will be created; ``module`` may have one or more ``unit``
* By using property ``exclude.test.layers``, complete layers can be excluded and the components inside that layer will not be included in the AtsDrop. This property is a comma (,) separated list


**STEP 2: Configure ATS properties in build.xml**

**(A)** Username and Password for the ATS should be set in the `.netrc file`_

.. code-block:: text

    machine ats login ats_user_name password ats_password

Add the above line in the .netrc file and replace *ats_user_name* with your real ats username and "ats_password" with ats password.
    
**(B)** The following properties are ATS dependent with their edit status

* [must] - must be set by user
* [recommended] - should be set by user but not mandatory
* [allowed] - should **not** be set by user however, it is possible.

.. table::

    ============================== =============== ===============
    **Property Name**              **Edit Status** **Description**
    ============================== =============== ===============
    **ats.server**                 [must]          For example: "4fix012345" or "catstresrv001.cats.noklab.net:80". Default server port is "8080", but it is not allowed between intra and Noklab. Because of this we need to define server port as 80. The host can be different depending on site and/or product.
    **ats.drop.location**          [must]          Server location (UNC path) to save the ATSDrop file, before sending to the ATS Server. For example: \\\\trwsem00\\some_folder\\. In case, ``ats.script.type`` is set to "import", ATS doesn't need to have access to ats.drop.location,  its value can be any local folder on build machine, for example c:/temp (no network share needed).
    **ats.product.name**           [must]          Name of the product to be tested. For example: "PRODUCT".
    **eunit.test.package**         [recommended]   The EUnit package name to be unzipped on the environment, for executing EUnit tests. "
    **eunitexerunner.flags**       [recommended]   Flags for EUnit exerunner can be set by setting the value of this variable. The default flags are set to "/E S60AppEnv /R Off".
    **ats.email.list**             [recommended]   The property is needed if you want to get an email from ATS server after the tests are executed. There can be one to many semicolon(s) ";" separated email addresses.
    **ats.flashfiles.minlimit**    [recommended]   Limit of minimum number of flash files to execute ats-test target, otherwise ATSDrop.zip will not be generated. Default value is "2" files.
    **ats.plan.name**              [recommended]   Modify the plan name if you have understanding of test.xml file or leave it as it is. Default value is "plan".
    **ats.product.hwid**           [recommended]   Product HardWare ID (HWID) attached to ATS. By default the value of HWID is not set.
    **ats.script.type**            [recommended]   There are two types of ats script files to send drop to ATS server, "runx" and "import"; only difference is that with "import" ATS doesn't have to have access rights to testdrop.zip file, as it is sent to the system over http and import doesn't need network shares. If that is not needed "import" should not be used. Default value is "runx" as "import" involves heavy processing on ATS server.
    **ats.target.platform**        [recommended]   Sets target platform for compiling test components. Default value is "armv5 urel".
    **ats.test.timeout**           [recommended]   To set test commands execution time limit on ATS server, in seconds. Default value is "60".
    **ats.testrun.name**           [recommended]   Modify the test-run name if you have understanding of test.xml file or leave it as it is. Default value is a string consist of build id, product name, major and minor versions.
    **ats.trace.enabled**          [recommended]   Should be "True" if tracing is needed during the tests running on ATS. Default value is "False", the values are case-sensitive. See http://s60wiki.nokia.com/S60Wiki/CATS/TraceTools
    **ats.ctc.enabled**            [recommended]   Should be "True" if coverage measurement and dynamic analysis (CTC) tool support is to be used by ATS. Default value is "False", the values are case-sensitive.
    **ats.ctc.host**               [recommended]   CTC host, provided by CATS used to create coverage measurement reports. MON.sym files are copied to this location, for example "10.0.0.1". If not given, code coverage reports are not created
    **ats.obey.pkgfiles.rule**     [recommended]   If the property is set to "True", then the only test components which will have PKG files, will be included into the test.xml as a test-set. Which means, even if there's a test component (executable) but there's no PKG file, it should not be considered as a test component and hence not included into the test.xml as a separate test. By default the property value is False.
    **reference.ats.flash.images** [recommended]   Fileset for list of flash images (can be .fpsx, .C00, .V01 etc) It is recommended to set the fileset, default filset is given below which can be overwritten. set *dir=""* attribute of the filset to "${r'$'}{build.output.dir}/variant_images" if "variant-image-creation" target is being used.
    **tsrc.data.dir**              [allowed]       The default value is "data" and refers to the 'data' directory under 'tsrc' directory.
    **tsrc.path.list**             [allowed]       Contains list of the tsrc directories. Gets the list from system definition layer files. Assuming that the test components are defined already in te layers.sysdef.xml files to get compiled. Not recommended, but the property value can be set if there are no system definition file(s), and tsrc directories paths to set manually.
    **ats.report.location**        [allowed]       Sets ATS reports store location. Default location is "${r'$'}{publish.dir}/${r'$'}{publish.subdir}".
    **ats.multiset.enabled**       [allowed]       Should be "True" so a set is used for each pkg file in a component, this allows tests to run in parallel on several devices.
    **ats.diamonds.signal**        [allowed]       Should be "true" so at end of the build diamonds is checked for test results and helium fails if tests failed.
    **ats.delta.enabled**          [allowed]       Should be "true" so only ado's changed during do-prep-work-area are tested by ats.
    **ats4.enabled**               [allowed]       Should be "true" if ats4 is to be used.
    ============================== =============== ===============


An example of setting up properties:

.. code-block:: xml

    <property name="ats.server" value="4fio00105"  />
    <property name="ats.drop.location" location="\\trwsimXX\ATS_TEST_SHARE\" />
    <property name="ats.email.list" value="temp.user@company.com; another.email@company.com" />
    <property name="ats.flashfiles.minlimit" value="2" />
    <property name="ats.product.name" value="PRODUCT" />
    <property name="ats.plan.name" value="plan" />
    <property name="ats.product.hwid" value="" />
    <property name="ats.script.type" value="runx" />
    <property name="ats.target.platform" value="armv5 urel" />
    <property name="ats.test.timeout" value="60" />
    <property name="ats.testrun.name" value="${r'$'}{build.id}_${r'$'}{ats.product.name}_${r'$'}{major.version}.${r'$'}{minor.version}" />
    <property name="ats.trace.enabled" value="False" />
    <property name="ats.ctc.enabled" value="False" />
    <property name="ats.obey.pkgfiles.rule" value="False" />
    <property name="ats.report.location" value="${r'$'}{publish.dir}/${r'$'}{publish.subdir}" />
    <property name="eunit.test.package" value="" />
    <property name="eunitexerunner.flags" value="/E S60AppEnv /R Off" />
        
        ...
        <import file="${r'$'}{helium.dir}/helium.ant.xml" />
        ...
    
    <fileset id="reference.ats.flash.images" dir="${r'$'}{release.images.dir}">
        <include name="**/${r'$'}{build.id}*.core.fpsx"/>
        <include name="**/${r'$'}{build.id}*.rofs2.fpsx"/>
        <include name="**/${r'$'}{build.id}*.rofs3.fpsx"/>
    </fileset>
    

*PLEASE NOTE:* Always declare *Properties* before and *filesets* after importing helium.ant.xml.

**STEP 3: Call target ats-test**

To execute the target, a property should be set(``<property name="enabled.ats" value="true" />``).

Then call ``ats-test``, which will create the ATSDrop.zip (test package).

If property *ats.email.list* is set, an email (test report) will be sent when the tests are ready on ATS.

CTC:
----

CTC code coverage measurements reports can be created as part of Test Automation process.

1. Build the src using ``build_ctc`` configuration, which is in ``build.sysdef.xml`` file, to create ``MON.sym`` files. It means that a property ``sysdef.configurations.list`` should be modified either add or replace current build configuration with ``build_ctc``

2. Set the property, ``ats.ctc.host``, as described above, for sending the ``MON.sym`` files to the network drive. *(Please contact ATS server administrator and ask for the value to set this property)*

3. Enable CTC process by setting up property ``ats.ctc.enabled`` to "true"

4. Test drops are sent to the ATS server, where, after executing tests ``ctcdata.txt`` files are created. ``ctcdata.txt`` and ``MON.sym`` files are then further processed to create code coverage reports.

5. View or download the Code coverage reports by following the link provided in the ATS report email (sent after the tests are executed on ATS)

*NOTE: After receiving the email notification, it may take a few minutes before the code coverage reports are available.*


Qt Tests:
---------

QtTest.lib is supported and the default harness is set to EUnit. If ``QtTest.lib`` is there in ``.mmp`` file, Helium sets the Harness to Eunit and ATS supported Qt steps are added to test.xml file

In ``layers.sysdef.xml`` file, the layer name should end with "_test_layer" e.g. "qt_unit_test_layer".

There are several ``.PKG`` files created after executing ``qmake``, but only one is selected based on which target platform is set. Please read the property (``ats.target.platform``) description above.

.. _`Skip-Sending-AtsDrop-label`:

Skip Sending AtsDrop to ATS
----------------------------

By setting property of ``skip.ats.sending``, ``ats-test`` target only creates a drop file, and does not send the drop (or package) to ATS server.

Customizing the test.xml in ATS
--------------------------------

The user can customize the generated test.xml with files:

* **preset_custom.xml** goes before first set
* **postset_custom.xml** goes after last set
* **precase_custom.xml** goes before first case 
* **postcase_custom.xml** goes after last case
* **prestep_custom.xml** goes before first step
* **poststep_custom.xml** goes after last step
* **prerun_custom.xml** goes before first run or execute step
* **postrun_custom.xml** goes after last run or execute step
* **prepostaction.xml** goes before first postaction
* **postpostaction.xml** goes after last postaction

The files must be in the directory custom under the tsrc folder processed. 

The files need to be proper XML snippets that fit to their place. In case of an error an error is logged and a comment inserted to the generated XML file.

A postaction section customization file ( prepostaction.xml or postpostaction.xml) could look like this

.. code-block:: xml

  <postAction>
    <type>Pre PostAction from custom file</type> 
    <params>
       <param name="foo2" value="bar2" /> 
    </params>
  </postAction>
  


The ``prestep_custom.xml`` can be used to flash and unstall something custom.

.. code-block:: xml

  <step name="Install measurement tools" harness="STIF" significant="false">
    <!-- Copy SIS-packages to DUT -->
    <command>install</command>
    <params>
        <param src="Nokia_Energy_Profiler_1_1.sisx"/>
        <param dst="c:\data\Nokia_Energy_Profiler_1_1.sisx"/>
    </params>
    ...
  </step>


And then the  ``prerun_custom.xml`` can be used to start measuring.

.. code-block:: xml

  <step name="Start measurement" harness="STIF" significant="false">
      <!-- Start measurement -->
      <command>execute</command>
      <params>
          <param file="neplauncher.exe"/>
          <param parameters="start c:\data\nep.csv"/>
          <param timeout="30"/>
      </params>
  </step>



**Note:** The users is expected to check the generated test.xml manually, as there is no validation. Invalid XML input files will be disregarded and a comment will be inserted to the generated XML file.

Overriding Test xml values
--------------------------

Set the property ``ats.config.file`` to the location of the config file.

Example configuration:

.. code-block:: xml

    <ATSConfigData>  
        <config name="common" abstract="true">
         
            <!-- Properties to add/ modify -->
            <config type="properties">
               <set name="HARNESS" value="STIF" />
               <set name="2" value="3" />
            </config>
            
            <!-- Settings to add/ modify -->
            <config type="settings">
               <set name="HARNESS" value="STIF" />
               <set name="2" value="3" />
            </config>
            
            <!-- Attributes to modify -->
            <config type="attributes">
               <set name="xyz" value="2" />
               <set name="significant" value="true" />
            </config>
        </config>
    </ATSConfigData>


.. index::
  single: ATS - ASTE

Stage: ATS - ASTE
===================

Explanation of the process for getting ATS `ASTE`_ tests compiled and executed by Helium, through the use of the ``ats-aste`` target.

<#if !(ant?keys?seq_contains("sf"))>
.. _`ASTE`: http://s60wiki.nokia.com/S60Wiki/ASTE
</#if>

Prerequisites
--------------

* `Harmonized Test Interface (HTI)`_ needs to be compiled and into the image.
* The reader is expected to already have a working ATS setup in which test cases can be executed.  ATS server names, access rights and authentication etc. is supposed to be already taken care of.
* `SW Test Asset`_ location and type of test should be known.

<#if !(ant?keys?seq_contains("sf"))>
.. _`Harmonized Test Interface (HTI)`: http://s60wiki.nokia.com/S60Wiki/HTI
.. _`SW Test Asset`: http://s60wiki.nokia.com/S60Wiki/MC_SW_Test_Asset_documentation
</#if>

Test source components
--------------------------

Unlike STIF, EUnit etc tests, test source components (or ``tsrc`` structure) is not needed for `ASTE`_ tests.

Two STEPS to setup ASTE with Helium
------------------------------------

**STEP 1: Configure ASTE properties in build.xml**

**(A)** Username and Password for the ATS should be set in the `.netrc file`_

.. code-block:: text

    machine ats login ats_user_name password ats_password

Add the above line in the .netrc file and replace *ats_user_name* with your real ats username and "ats_password" with ats password.
    
.. _`.netrc file`: configuring.html?highlight=netrc#passwords


**(B)** The following properties are ASTE dependent with their edit status

* [must] - must be set by user
* [recommended] - should be set by user but not mandatory
* [allowed] - should **not** be set by user however, it is possible.

.. table::

    =============================== =============== ===============
    **Property Name**               **Edit Status** **Description**
    =============================== =============== ===============
    **ats.server**                  [must]          For example: "4fio00105" or "catstresrv001.cats.noklab.net:80". Default server port is "8080", but it is not allowed between intra and Noklab. Because of this we need to define server port as 80. The host can be different depending on site and/or product.
    **ats.drop.location**           [must]          Server location (UNC path) to save the ATSDrop file, before sending to the ATS. For example: \\\\trwsem00\\some_folder\\. In case, ``ats.script.type`` is set to "import", ATS doesn't need to have access to ats.drop.location,  its value can be any local folder on build machine, for example c:/temp (no network share needed).
    **ats.product.name**            [must]          Name of the product to be tested. For example: "PRODUCT".
    **ats.aste.testasset.location** [must]          Location of SW Test Assets, if the TestAsset is not packaged then it is first compressed to a ``.zip`` file. It should be a UNC path.
    **ats.aste.software.release**   [must]          Flash images releases, for example "SPP 51.32".
    **ats.aste.software.version**   [must]          Version of the software to be tested. For example: "W810"
    **ats.aste.email.list**         [recommended]   The property is needed if you want to get an email from ATS server after the tests are executed. There can be one to many semicolon(s) ";" separated email addresses.
    **ats.flashfiles.minlimit**     [recommended]   Limit of minimum number of flash files to execute ats-test target, otherwise ATSDrop.zip will not be generated. Default value is "2" files.
    **ats.aste.plan.name**          [recommended]   Modify the plan name if you have understanding of test.xml file or leave it as it is. Default value is "plan".
    **ats.product.hwid**            [recommended]   Product HardWare ID (HWID) attached to ATS. By default the value of HWID is not set.
    **ats.test.timeout**            [recommended]   To set test commands execution time limit on ATS server, in seconds. Default value is "60".
    **ats.aste.testrun.name**       [recommended]   Modify the test-run name if you have understanding of test.xml file or leave it as it is. Default value is a string consists of build id, product name, major and minor versions.
    **ats.aste.test.type**          [recommended]   Type of test to run. Default is "smoke".
    **ats.aste.testasset.caseids**  [recommended]   These are the cases that which tests should be run from the TestAsset. For example, value can be set as "100,101,102,103,105,106,". A comma is needed to separate case IDs
    **ats.aste.language**           [recommended]   Variant Language to be tested. Default is "English"
    **reference.ats.flash.images**  [recommended]   Fileset for list of flash images (can be .fpsx, .C00, .V01 etc) It is recommended to set the fileset, default filset is given below which can be overwritten. set *dir=""* attribute of the filset to "${r'$'}{build.output.dir}/variant_images" if "variant-image-creation" target is being used.
    
    =============================== =============== ===============
    
An example of setting up properties:
    
.. code-block:: xml
    
    <property name="ats.server" value="4fio00105"  />
    <property name="ats.drop.location" value="\\trwsimXX\ATS_TEST_SHARE\" />
    <property name="ats.aste.email.list" value="temp.user@company.com; another.email@company.com" />
    <property name="ats.flashfiles.minlimit" value="2" />
    <property name="ats.product.name" value="PRODUCT" />
    <property name="ats.aste.plan.name" value="plan" />
    <property name="ats.product.hwid" value="" />
    <property name="ats.test.timeout" value="60" />
    <property name="ats.aste.testrun.name" value="${r'$'}{build.id}_${r'$'}{ats.product.name}_${r'$'}{major.version}.${r'$'}{minor.version}" />
    <property name="ats.aste.testasset.location" value="" />
    <property name="ats.aste.software.release" value="SPP 51.32" />
    <property name="ats.aste.test.type" value="smoke" />
    <property name="ats.aste.testasset.caseids" value="100,101,102,104,106," />
    <property name="ats.aste.software.version" value="W810" />
    <property name="ats.aste.language" value="English" />
         
    ...
    <import file="${r'$'}{helium.dir}/helium.ant.xml" />
    ...
    
    <fileset id="reference.ats.flash.images" dir="${r'$'}{release.images.dir}">
        <include name="**/${r'$'}{build.id}*.core.fpsx"/>
        <include name="**/${r'$'}{build.id}*.rofs2.fpsx"/>
        <include name="**/${r'$'}{build.id}*.rofs3.fpsx"/>
    </fileset>
    

*PLEASE NOTE:* Always declare *Properties* before and *filesets* after importing helium.ant.xml.

**STEP 2: Call target ats-aste**

To execute the target, a property should be set(``<property name="enabled.aste" value="true" />``).

Then call ``ats-aste``, which will create the ATSDrop.zip (test package).

If property ``ats.aste.email.list`` is set, an email (test report) will be sent when the tests are ready on ATS/ASTE.


Skip Sending AtsDrop to ATS
------------------------------

click :ref:`Skip-Sending-AtsDrop-label`:

.. index::
  single: MATTI

Stage: MATTI
=============

MATTI testing is very similar to ATS testing, so for details of how it all links together see :ref:`Stage-ATS-label`: `and the matti website`_.

<#if !(ant?keys?seq_contains("sf"))>
.. _`and the matti website`:  http://trmatti1.nmp.nokia.com/help/
</#if>  

The set up of parameters is very similar (a few less parameters and it mostly uses ATS values). The main difference is that once the drop file has been uploaded to the ATS server it uses MATTI to perform the tests and not ATS, this is achieved by calling the MATTIDrop.py script instead of the ATSE or ATS scripts when creating the drop file (the drop file contains the flash files and the ruby tests to be performed).

The following parameters are the ones that are not listed in the ATS parameters, all other parameters required are as listed in the ATS section above.

* [must] - must be set by user
* [recommended] - should be set by user but not mandatory
* [allowed] - should **not** be set by user however, it is possible.

.. table::

    =============================== =============== ===============
    **Property Name**               **Edit Status** **Description**
    =============================== =============== ===============
    **matti.scripts**               [must]          The location of the test scrips as ruby test files i.e. .rb files.
    **enabled.matti**               [must]          Enable MATTI testing to occur, if not present the target 'matti-test' will not run.
    **template.file**               [must]          Location of the matti template file.
    **ats.sis.images.dir**          [recommended]   Location of the the .sis installation files needed to flash to the phone (if required and present).
    **ats.script.type**             [must]          Always set to import, this means the MATTI server will retrieve the tests.
    **ats.image.type**              [must]          Image type whether Engineering English or localised.
    **ats.flashfiles.minlimit**     [must]          Minimum number of flash files required in to add to the drop file.
    **tsrc.data.dir**               [recommended]   Test source code data directory. only required for testing the ANT MATTI code.
    **ta.flag.list**                [recommended]   TA flag list.
    
    =============================== =============== ===============

All you need to do is setup the following parameters:

.. code-block:: xml

    <property name="enabled.matti" value="true" />
    <property name="matti.scripts" value="${r'$'}{helium.dir}\testconfig\ats3\matti\script" />
    <property name="template.file" value="${r'$'}{helium.dir}\tools\common\python\lib\ats3\matti\template\matti_demo.xml" />
    <property name="ats.sis.images.dir" location="${r'$'}{build.drive}\output\matti\sis" />
    <property name="ats.product.name" value="" />
    <property name="ats.test.timeout" value="60" />

    <!--ATS testing properties-->
    <property name="tsrc.data.dir" value="data_rom" />
    <property name="ats.ctc.enabled" value="True" />
    <property name="ats.flashfiles.minlimit" value="2"/>
    <property name="ta.flag.list" value="TA_M, TA_MU, TA_MMAPPFW,TA_MM"/>
    <property name="ats.server" value="12345675:80"/>

In order to upload and view the test run you need to have a valid user id and password that matches that in your .netrc file. To create the account open a web browser window and enter the name of the ats.server with /ATS at the end e.g. http://123456:80/ATS. Click on the link in the top right hand corner to create the account. To view the test run once your account is active you need to click on the 'test runs' tab.

To run the tests call the target `matti-test` (you will need to define the 'build.drive', 'build.number' and it is best to create the 'core.build.version' on the command line as well if you do not add it to the list of targets run that create the ROM image). e.g.
::

    hlm -Dbuild.number=001 -Dbuild.drive=z: -Dcore.build.version=001 matti-test

If it displays the message 'Testdrop created!' with the file name then the MATTIDrops.py script has done what it needs to do. The next thing to check is that the drop file has been uploaded to the ATS server OK. If that is performed successfully then the rest of the testing needs to be performed by the ATS server. There is also a test.xml file created that contains details needed for debugging any problems that might occur. To determine if the tests have run correctly you need to read the test run details from the server.
