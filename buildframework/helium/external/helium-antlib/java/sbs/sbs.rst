.. index::
  module: Configuring Raptor (SBS)

========================
Configuring Raptor (SBS)
========================

.. contents::

This document describes requirements and how to run sbs builds using helium. Now it is 
possible to pass directly pass all the raptor input directly and there are no mapping of
raptor parameter specific to helium.


SBS Requirements
-----------------

Before starting the build, SBS needs to be updated for s60 related changes, please follow the instructions from the link below,

`How to Build Raptor <http://s60wiki.nokia.com/S60Wiki/How_To_Build_With_Raptor>`_

1. SBS_HOME environment variable needs to be set
2. PATH environment variable needs to be updated with SBS related exe::

   path(SBS_HOME\\BIN;SBS_HOME\\win32\\mingw\\bin;SBS_HOME\\win32\\msys\\bin)

3. RVCT requirement for raptor is 22_686 or higher, in IDO config / product config batch file the env variable needs to be set to `HLM_RVCT_VERSION=22_686`

For Example: ::

 set HELIUM_HOME=E:\Build_E\ec_test\helium-trunk\helium
 set PATH=e:\svn\bin;E:\sbs\bin;c:\apps\actpython;%PATH%
 set SBS_HOME=E:\sbs
 set MWSym2Libraries=%MWSym2Libraries%;C:\APPS\carbide\x86Build\Symbian_Support\Runtime\Runtime_x86\Runtime_Win32\Libs
 set TEAM=site_name
   
(Note: For IDOs, these environment variables are set automatically, for S60 option is proposed).

Required SBS input for Helium
------------------------------

SBS Input consists of SBSInput and SBSBuild types:

1. SBSInput - SBS Input stores the list of raptor arguments both the sbs options and
sbs make options. Nested sbs input option is also possible, for details please see the 
antdoclet information for sbsInput.

2. SBSBuild - SBS Build is the collection of SBSInput. Each SBSInput refering within
SBSBuild corresponds to a single invocation of raptor with the corresponding sbs arguments
refered within the sbsInput. Each sbsInput refered within SBSBuild roughly corresponds to
the abld commands associated with corresponding abld configurations. <configuration> </configuration>
is corresponds ot SBSBuild. This is there only for backward compatibility and will be removed
once the mighration is completed for schema 3.0, in which case, abld mapping of configuration
is not required and sbsInput could be directly used. Example is as below,

.. code-block:: xml

    <hlm:sbsbuild id="sbs.dfs_build_export">
        <sbsInput refid="dfs_build_export_input" />
    </hlm:sbsbuild> 


1. To run using SBS mode (schema 1.4.0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

List of SBSInput one to one mapping with corresponding abld commands mapped for a configuration.
    
example is below,

.. code-block:: xml

    <!-- tools common sbs options -->
    <hlm:sbsoptions id="commonSBS">
        <arg line="-k" />
        <arg name="--filters" value="FilterMetadataLog"/>
    </hlm:sbsoptions>

    <hlm:sbsoptions id="exportSBS">
        <argset refid="commonSBS" />
        <arg line="--export-only" />
    </hlm:sbsoptions>

    <!-- sbs input for export -->
    <hlm:sbsinput id="export-sbs">
        <sbsoptions refid="exportSBS" />
    </hlm:sbsinput>
    
    <hlm:sbsbuild id="sbs.dfs_build_export">
        <sbsInput refid="dfs_build_export_input" />
    </hlm:sbsbuild> 

Assuming there is a dfs_build_export schema configuration 1.4.0 system definition file.
Then there should be a corresponding <hlm:sbsbuild> type defined prefixing with sbs
as sbs.dfs_build_export as above which contains a reference to sbsinput. The sbsInput
contains actual raptor commands equivalent to abld commands to be executed for that
configuration, in this case it is referring exportSBS, which in turn referring to commonsbs
so finally the command generated would be 

.. code-block:: xml

    sbs -k --filters=FilterMetadataLog --export-only

This command is executed for all the componentes specified in the dfs_build_export
configuration.

No change from the configuration is required, except the new raptor input needs to be imported.

2. To run using SBS mode (schema 3.0.0) - partial support
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

For schema 3.0, required inputs are,
 a. sbs arguments
 b. package definition files
 c. filters to filter the component
 d. patternset - specifying specific set of layers to be executed.

Note: Filters are not supported yet.
 
As raptor doesn't support schema 3.0 directly, the schema 3.0 is downgraded to
2.0 schema, then it is joined / merged with symbian / nokia system definition.
Finally calling raptor commands with the raptor input.

The minimum required input for schema 3.0 is, sbsinput.

.. code-block:: xml

    <!-- sbs input for export -->
    <hlm:sbsinput id="export-sbs">
        <sbsoptions refid="exportSBS" />
    </hlm:sbsinput>

When building for raptor just the export-sbs needs to be passed as the argument to 
compile-main target as below,

.. code-block:: xml

    <antcall target="compile-main" inheritRefs="true">
        <param name="sbs.inputs.list" value="export-sbs,armv5-build"/>
    </antcall>

Which will execute each sbs input from the list as a separate sbs call and execute it. Schema 3.0
is very basic and is only intended for internal testing / validation.

Customizing raptor input
------------------------

Different scenario the user might need to provide the raptor inputs, (required to map raptor 
commands for abld configuration which is not there in the default raptor input xml file, 
want to override the default raptor input to pass additional parameters), below section covers
how these can be customized.

Mapping raptor commands for new configuration from system definition file (1.4.0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

First step is to identify the abld commands executed by the new configuration. Correspondingly the
raptor commands need to be identified for that. Then need to check from the common raptor input 
is there any input which can be reused. If any raptor input could be re-usable, the just refering
that input and adding additional arguments would provide the exact raptor command arguments to be
executed.


For example, if the new configuration for which the raptor command input is to be created is,
os, which is not there in the default raptor input, then abld commands executed are 
(to be simpoer - bldmake, export, tools_rel, winscw, armv5). The corresponding raptor input would
be


.. code-block:: xml

    <hlm:sbsinput id="build_input_os_export">
        <sbsInput refid="export-${build.system}" />
        <sbsOptions>
            <arg name="--logfile" value="${compile.log.dir}/${build.id}_export_os_build.log" />
            <arg name="--makefile" value="${temp.build.dir}/${build.id}_export_os_build" />
        </sbsOptions>
    </hlm:sbsinput>

    <hlm:sbsinput id="build_input_os_tools">
        <sbsInput refid="tools-${build.system}" />
        <sbsOptions>
            <arg name="--logfile" value="${compile.log.dir}/${build.id}_tools_rel_os_build.log" />
            <arg name="--makefile" value="${temp.build.dir}/${build.id}_tools_rel_os_build" />
        </sbsOptions>
    </hlm:sbsinput>

    <hlm:sbsinput id="build_input_os_winscw">
        <sbsInput refid="winscw-${build.system}" />
        <sbsOptions>
            <arg name="--logfile" value="${compile.log.dir}/${build.id}_winscw_os_build.log" />
            <arg name="--makefile" value="${temp.build.dir}/${build.id}_winscw_os_build" />
        </sbsOptions>
    </hlm:sbsinput>


    <hlm:sbsinput id="build_input_os_armv5">
        <sbsInput refid="armv5-${build.system}" />
        <sbsOptions>
            <arg name="--logfile" value="${compile.log.dir}/${build.id}_armv5_os_build.log" />
            <arg name="--makefile" value="${temp.build.dir}/${build.id}_armv5_os_build" />
        </sbsOptions>
    </hlm:sbsinput>

The default raptor input for each build target (tools, winscw, armv5) are reused here and just the
log file names are changed.

Next the sequence of command execution needs to be defined for the corresponding os confoguration as below.

.. code-block:: xml

    <hlm:sbsbuild id="sbs.os">
        <sbsInput refid="build_input_os_export" />
        <sbsInput refid="build_input_os_tools" />
        <sbsInput refid="build_input_os_winscw" />
        <sbsInput refid="build_input_os_armv5" />
    </hlm:sbsbuild>

For configuration name os in the system definition file, it will take the list of raptor input
as defined with sbs.os, then it will execute each sbsinput as separate sbs calls with the arguments
extracted from the corresponding reference id.

Overriding default raptor arguments
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

In case the default argument is not enough for the user requirements, this could be overriden by
redefining the reference of a particular sbsoptions will provide the user to change the arguments.

For example, if the user just wants to pass debug flag for armv5 raptor inputs, the raptor input 

.. code-block:: xml

    <!-- Mainbuild common sbs options -->
    <hlm:sbsoptions id="armv5CommonSBS">
        <argset refid="commonSBS" />
        <arg line="-c armv5" />
    </hlm:sbsoptions>


could be redefined as below in the user configuration,

.. code-block:: xml

    <!-- Mainbuild common sbs options -->
    <hlm:sbsoptions id="armv5CommonSBS">
        <argset refid="commonSBS" />
        <arg line="-c armv5" />
        <arg line="-d" />
    </hlm:sbsoptions>

This would add the debug flag in all the raptor configuration which is using armv5CommonSBS.