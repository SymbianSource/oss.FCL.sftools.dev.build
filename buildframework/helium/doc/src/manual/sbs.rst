.. index::
  module: SBS in Helium

.. index::
  module: Raptor (SBS) in Helium

=======================
SBS (raptor) In Helium
=======================

.. contents::

This document describes requirements and how to run sbs builds using helium


SBS Requirements
-----------------

Before starting the build, SBS needs to be updated for s60 related changes, please follow the instructions from the link below,

`How to Build Raptor <http://s60wiki.nokia.com/S60Wiki/How_To_Build_With_Raptor>`_

1. SBS_HOME environment variable needs to be set
2. PATH environment variable needs to be updated with SBS related exe:

   path(SBS_HOME\\BIN;SBS_HOME\\win32\\mingw\\bin;SBS_HOME\\win32\\msys\\bin)

3. RVCT requirement for raptor is 22_616, in IDO config / product config batch file the env variable needs to be set to
HLM_RVCT_VERSION=22_616

For Example: ::

 set HELIUM_HOME=E:\Build_E\ec_test\helium-trunk\helium
 set PATH=e:\svn\bin;E:\sbs\bin;c:\apps\actpython;%PATH%
 set SBS_HOME=E:\sbs
 set MWSym2Libraries=%MWSym2Libraries%;C:\APPS\carbide\x86Build\Symbian_Support\Runtime\Runtime_x86\Runtime_Win32\Libs
 set TEAM=site_name
   
(Note: For IDOs, these environment variables are set automatically, for S60 option is proposed).

Required SBS input for Helium
------------------------------
1. To run using SBS mode the following properties need to be set with the values shown below:

   * build.system - sbs - gmake as SBS engine
   * build.system - sbs-ec emake as SBS engine (ECA 4.3 or above required)

2. sbs.config - (configurations for which the sbs needs to be run - for example (armv5 / winscw) - default is armv5 only.

The layers to be built for SBS are obtained from System definition files (layers.sysdef.xml found in each component top level folder in the released code). The requirement for the system definition files to be run using SBS / raptor is to have a unique filter for each configuration. The current setup is using raptor\_<configuration_name> for example, for s60_build configuration, the filter should be raptor\_s60_build.
This is the temporary solution and discussions are on to finalise / improve the filter mechanism for raptor. The raptor\_ change has been added to the layers.sysdef.xml files supplied for the IDOs and S60_SBS build releases but when building using DFS full builds the files need to be modified to add the raptor\_ for each layer.

Supported SBS parameters from helium
-------------------------------------

List of parameters::

   a. layers - No need to specify for the full IDO / product configuration. If there is a requirement to run specific layer alone, then this needs to be set.
   b. config - (configuration to be built - armv5, winscw - with comma seperated values)
   c. skipBuild - just to generate the makefile for SBS and not to run the targets.
   d. singleJob - run in single thread for engine gmake only
   e. layerOrder - If the layers need to be built using order, then this needs to be set to true.
   f. command - command to be executed(SBS commands - REALLYCLEAN, EXPORT, BITMAP, RESOURCE, TARGET)
   g. sysdef-base - base location for the sysdef (root directory for relative paths in the system definition files)
   h. enable-filter - to use the SBS log processing using filter options from SBS, this should be set to true
      to use helium log filter and scanlog.
   i. retry-limit - number of times to try in case of transient failure ( -t of sbs).
   j. run-check - (true / false) runs the --check sbs command if set to true
   k. run-what - (true / false) runs the --what sbs command if set to true

Command line arguments to SBS using Helium:
-------------------------------------------

build.system=sbs
~~~~~~~~~~~~~~~~~
To build using gmake as the engine, and all others with default values (skipBuild - false, with multiple jobs (default
set by helium is number.of.processor*2 and no layer order)

If multiple configurations need to be built, a comma separated list needs to be passed as (armv5,winscw) to sbs.config property.

examples::
   
   <property name="sbs.config" value="armv5" />
   <property name="sbs.config" value="armv5,winscw" />
   <property name="sbs.config" value="armv5,winscw,armv5.test"/>
   
This can be set in the IDO root directory build.xml file.

Here is an example command to use (first 'cd' to IDO configuration directory ido_configuration/running/idos/abs/branches/mcl_devlon ) ::

   hlm -Dbuild.drive=z: -Dbuild.system=sbs -Dbuild.number=005 -Dskip.password.validation=true ido-build

   
build.system=sbs-ec
~~~~~~~~~~~~~~~~~~~~
To build using emake as the engine with default values set by helium (sbs make engine as emake and other emake parameters using ec) just the ``sbs.config`` property has   to be set to configuration to be built(armv5, winscw).
   
Here is an example command to use (first 'cd' to IDO configuration directory ido_configuration/running/idos/abs/branches/mcl_devlon )

hlm -Dbuild.drive=z: -Dbuild.system.main.build=sbs-ec -Dbuild.number=005 -Dskip.password.validation=true ido-build

Note the different flag ``-Dbuild.system.main.build=sbs-ec``


Passing Make options to SBS using helium
-----------------------------------------

Make options for different make engines could be passed to SBS using ant reference as below,
(Note: currently supported make engine options are emake options only, in the future will
be added for pvm and gmake).

Make options for SBS using helium:

.. code-block:: xml

   <hlm:sbsMakeOptions id="sbs-ec.fullbuild.options" engine="emake">
      <hlm:makeOption name="--emake-emulation" value="gmake" />
      <hlm:makeOption name="--emake-annodetail" value="basic,history,waiting" />
      <hlm:makeOption name="--emake-class" value="${ec.build.class}" />
   </hlm:sbsMakeOptions>
   
First user defined make options need to be defined as above, then the default ``<build.system>.make.options``
parameter needs to be overridden in the antcall of user defined config as below:
   
.. code-block:: xml
   
   <antcall target="compile-main" inheritAll="false" inheritRefs="true">
      <reference refid="sbs-ec.fullbuild.options" torefid="sbs-ec.make.options"/>
   </antcall>
   
Here the ``sbs-ec.fullbuild.options`` mapped to ``sbs-ec.make.options`` and used by helium to set
emake options for SBS.
   
Building for different SBS input (advanced users)
--------------------------------------------------

Some examples to build for different sbs input using helium are below:
   
To build using a single thread, the sbs helium variable is:
   
.. code-block:: xml
   
   <hlm:argSet id="sbs.singlethread.var">
      <hlm:arg name="config" value="${sbs.config}" />
      <hlm:arg name="singleJob" value="true" />
   </hlm:argSet>
   
And set ``sbs.var`` to ``sbs.singlethread.var`` as below during <antcall> target to call compile-main:

.. code-block:: xml

   <antcall target="compile-main" inheritAll="false" inheritRefs="true">
      <reference refid="sbs.singlethread.var" torefid="sbs.var"/>
   </antcall>