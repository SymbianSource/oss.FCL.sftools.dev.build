..  ============================================================================ 
    Name        : stage_ats.rst.ftl
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
  module: Testing

=======
Testing
=======

This is a good start for Helium users who want to setup test automation using ATS4. (**ATS3 users**, please `read here`_  .)

.. _`read here`: stage_ats_old.html



.. contents::


  
Helium Test Automation
======================

Helium can be used to auomate testing. For this purpose, test asset must be alligned with the standard guidelines for writing the tests.  

Helium supports several test frameworks including `STIF`_, `TEF`_, RTest, MTF, `SUT`_, QtTest `EUnit`_, TDriver and ASTE. (`Description of test frameworks`_) 

Most of the above mentioned test frameworks share common configuration to setup TA environemnet. However, there are a few exceptions, which are discussed below under the headings of every test framework.



<#if !(ant?keys?seq_contains("sf"))>
.. _`STIF`: http://s60wiki.nokia.com/S60Wiki/STIF
.. _`TEF`: http://s60wiki.nokia.com/S60Wiki/TEF_%28TestExecute_Framework%29
.. _`EUnit`: http://s60wiki.nokia.com/S60Wiki/EUnit
</#if>

.. _`SUT`: http://developer.symbian.org/wiki/index.php/Symbian_Test_Tools#SymbianUnitTest
.. _`Description of test frameworks`: http://developer.symbian.org/wiki/index.php/Symbian_Test_Tools



Prerequisites
-------------

* `Harmonized Test Interface (HTI)`_ needs to be compiled and into the image.
* The reader is expected to already have a working ATS setup in which test cases can be executed.  ATS server names, 
  access rights and authentication etc. is supposed to be already taken care of.

<#if !(ant?keys?seq_contains("sf"))>
.. _`Harmonized Test Interface (HTI)`: http://s60wiki.nokia.com/S60Wiki/HTI
<#else>
.. _`Harmonized Test Interface (HTI)`: http://developer.symbian.org/wiki/index.php/HTI_Tool
</#if>


Setting up a Test Automation Environment with Helium
====================================================

Basic Test Automation step-by-step setup guide. 


Step 0: Structuring Test-source/test-asset
------------------------------------------
Test source usually lives in a component's ``tsrc`` directory.  Test source components are created like any other Symbian SW component; 
there is a ``group`` directory with a ``bld.inf`` file for building, ``.mmp`` files for defining the targets, and so on.

The test generation code expects ``.pkg`` file in the ``group`` directory of test component to be compiled, to get the paths of the files 
(can be data, configuration, initialization, etc) to be installed and where to install on the phone.

**Please note** that not all components have ``tsrc`` and ``group`` directories. For instance, Qt, ASTE and TDriver do not have similar test asset structure as STIF, TEF and other test components. It is recommended to follow the test asset guidelines prior to setting up test automation with Helium. 


Step 1: Setting up system definition file
-----------------------------------------
**System Definition Files supporting layers.sysdef.xml**
 **layers** in ``layers.sysdef.xml`` file and **configuration** in ``build.sysdef.xml`` file (`Structure of System Definition files version 1.4`_).
 
 <#if !(ant?keys?seq_contains("sf"))>
.. _`new API test automation guidelines`: http://s60wiki.nokia.com/S60Wiki/Test_Asset_Guidelines
.. _`Structure of System Definition files version 1.4`: http://delivery.nmp.nokia.com/trac/helium/wiki/SystemDefinitionFiles
</#if>

A template of layer in layers.sysdef.xml for system definition files

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

**System Definition Files version 3.0 (SysDefs3)** (new Helium v.10.79)
 The `structure of System Definition files version 3.0`_ is different than previous versions of system definition files. In SysDefs3, package definition files are used for components specification. Instead of layers naming conventions, filters are used to identify test components and test types, for example: "test, unit_test, !api_test" etc.

<#if !(ant?keys?seq_contains("sf"))>
.. _`structure of System Definition files version 3.0`: http://wikis.in.nokia.com/view/SWManageabilityTeamWiki/PkgdefUse
<#else>
.. _`structure of System Definition files version 3.0`: sysdef3.html
</#if>

An example template for defining test components in a package definition file.

.. code-block:: xml

      <package id="dummytest" name="dummytest" levels="demo">
        <collection id="test_nested" name="test_nested" level="demo">
        
          <component id="tc1" name="tc1" purpose="development" filter="test, unit_test">
              <unit bldFile="test_nested/tc1/group" mrp="" />
          </component>
          
          <component id="tc2" name="tc2" purpose="development" filter="test">
            <meta rel="testbuild">
              <group name="drop_tc2_and_tc3" /> 
            </meta>
            <unit bldFile="test_nested/tc2/group" mrp="" />
          </component>
          
          <component id="tc3" name="tc3" purpose="development" filter="test">
            <meta rel="testbuild">
              <group name="drop_tc2_and_tc3" /> 
            </meta>
            <unit bldFile="test_nested/tc3/group" mrp="" />
          </component>
          
        </collection>
      </package>


* Filter "test" must be specified for every test component. If it is not specified, the component will not be considered as a test component.
* <meta>/<group> are now used to group test components, it work in the same way as <module>...<module> in sysdef v1.4 works. The components having same group name are grouped together. 
  Separate drop files are created for different groups. In the above example, if only 'test' is selected, then two drop files will be created, one with tc1 and the other one with tc2 and tc3. 


Step 2: Configure ATS Ant properties
---------------------------------------
The properties are categorized as 

* **Common** - Valid for all test frameworks (Table-1).
* **API/Module** - Valid for only API/Module tests like STIF, STF, EUNit etc., and hence, are shared among many test frameworks (Table-2).


Also, the edit status of the properties can be described as

* [must] - must be set by user
* [recommended] - should be set by user but not mandatory
* [allowed] - should **not** be set by user however, it is possible.   

.. csv-table:: Table-1: ATS - Common Properties
   :header: "Property name", "Edit status", "Description"

    ":hlm-p:`ats.server`", "[must]", ":hlm-p:`ats.server[documentation]`"
    ":hlm-p:`ats.drop.location`", "[allowed]", ":hlm-p:`ats.drop.location[documentation]`"
    ":hlm-p:`ats.product.name`", "[must]", ":hlm-p:`ats.product.name[documentation]`"
    ":hlm-p:`ats.email.list`", "[allowed]", ":hlm-p:`ats.email.list[documentation]`"
    ":hlm-p:`ats.report.type`", "[allowed]", ":hlm-p:`ats.report.type[documentation]`"
    ":hlm-p:`ats.flashfiles.minlimit`", "[allowed]", ":hlm-p:`ats.flashfiles.minlimit[documentation]`"
    ":hlm-p:`ats.plan.name`", "[allowed]", ":hlm-p:`ats.plan.name[documentation]`"
    ":hlm-p:`ats.product.hwid`", "[allowed]", ":hlm-p:`ats.product.hwid[documentation]`"
    ":hlm-p:`ats.script.type`", "[allowed]", ":hlm-p:`ats.script.type[documentation]`"
    ":hlm-p:`ats.test.timeout`", "[allowed]", ":hlm-p:`ats.test.timeout[documentation]`"
    ":hlm-p:`ats.testrun.name`", "[allowed]", ":hlm-p:`ats.testrun.name[documentation]`"
    ":hlm-p:`ats.report.location`", "[allowed]", ":hlm-p:`ats.report.location[documentation]`"
    ":hlm-p:`ats.diamonds.signal`", "[allowed]", ":hlm-p:`ats.diamonds.signal[documentation]`"


An example of setting up the common properties as in table-1:

.. code-block:: xml

    <property name="ats.server" value="4fio00105"  />
    <property name="ats.drop.location" location="\\trwsimXX\ATS_TEST_SHARE\" />
    <property name="ats.product.name" value="PRODUCT" />
    <property name="ats.email.list" value="temp.user@company.com; another.email@company.com" />
    <property name="ats.report.type" value="simplelogger" />
    <property name="ats.flashfiles.minlimit" value="2" />
    <property name="ats.plan.name" value="plan" />
    <property name="ats.product.hwid" value="" />
    <property name="ats.script.type" value="runx" />
    <property name="ats.test.timeout" value="60" />
    <property name="ats.testrun.name" value="${r'$'}{build.id}_${r'$'}{ats.product.name}_${r'$'}{major.version}.${r'$'}{minor.version}" />
    <property name="ats.report.location" value="${r'$'}{publish.dir}/${r'$'}{publish.subdir}" />
    <property name="ats.diamonds.signal" value="false" />
    

.. csv-table:: Table-2: ATS - API/Module properties
   :header: "Property name", "Edit status", "Description"

    ":hlm-p:`ats.target.platform`", "[allowed]", ":hlm-p:`ats.target.platform[documentation]`"
    ":hlm-p:`ats.obey.pkgfiles.rule`", "[allowed]", ":hlm-p:`ats.obey.pkgfiles.rule[documentation]`"
    ":hlm-p:`ats.specific.pkg`", "[allowed]", ":hlm-p:`ats.specific.pkg[documentation]`"
    ":hlm-p:`ats.test.filterset`", "[allowed]", ":hlm-p:`ats.test.filterset[documentation]`"


An example of setting up API/Module testing properties as in table-2:

.. code-block:: xml

    <property name="ats.target.platform" value="armv5 urel" />
    <property name="ats.obey.pkgfiles.rule" value="false" />
    <property name="ats.specific.pkg" value="sanity" />
    <property name="ats.test.filterset" value="sysdef.filters.tests" />

    <hlm:sysdefFilterSet id="sysdef.filters.tests">
        <filter filter="test, " type="has" />
        <config file="bldvariant.hrh" includes="" />
    </hlm:sysdefFilterSet>


Step 3: Configure or select ROM images (Optional)
-------------------------------------------------
Since helium 10 images are picked up using :hlm-p:`ats.product.name` and Imaker iconfig.xml files. Property ``release.images.dir`` is searched for iconfig.xml files, the ones where the product name is part of :hlm-p:`ats.product.name` is used.

You should only build the images for each product you want to include in ats. See `Imaker`_ docs for more info. Eg.

.. _`Imaker`: ../helium-antlib/imaker.html

.. code-block:: xml

    <hlm:imakerconfigurationset id="configname">
        <imakerconfiguration>
            <hlm:product list="${r'$'}{product.list}" ui="true"/>
            <targetset>
                <include name="^core${r'$'}"/>
                <include name="^langpack_01${r'$'}"/>
                <include name="^custvariant_01_tools${r'$'}"/>
                <include name="^udaerase${r'$'}"/>
            </targetset>
            <variableset>
                <variable name="TYPE" value="rnd"/>
            </variableset>
        </imakerconfiguration>
    </hlm:imakerconfigurationset> 


For older products where there are no iconfig.xml, ``reference.ats.flash.images`` is used:

.. code-block:: xml

    <fileset id="reference.ats.flash.images" dir="${r'$'}{release.images.dir}">
        <include name="**/${r'$'}{build.id}*.core.fpsx"/>
        <include name="**/${r'$'}{build.id}*.rofs2.fpsx"/>
        <include name="**/${r'$'}{build.id}*.rofs3.fpsx"/>
    </fileset>


.. Note::
   
   Always declare *Properties* before and *filesets* after importing helium.ant.xml in order to overwrite the default values during the build.


Step 4: Enabling or disabling test automation features
------------------------------------------------------ 
Helium supports a number of test automation features, which are discussed below. These features can be enabled or disabled by switching the values of the following properties to either *true* or *false*.  


.. csv-table:: Table-3: ATS - Switches/enablers
   :header: "Property name", "Edit status", "Description"

    ":hlm-p:`ats.enabled`", "[allowed]", ":hlm-p:`ats.enabled[documentation]`"
    ":hlm-p:`ats4.enabled`", "[allowed]", ":hlm-p:`ats4.enabled[documentation]`"
    ":hlm-p:`ats.stf.enabled`", "[allowed]", ":hlm-p:`ats.stf..enabled[documentation]`"
    ":hlm-p:`aste.enabled`", "[allowed]", ":hlm-p:`aste.enabled[documentation]`"
    ":hlm-p:`ats.ctc.enabled`", "[allowed]", ":hlm-p:`ats.ctc.enabled[documentation]`"
    ":hlm-p:`ats.trace.enabled`", "[allowed]", ":hlm-p:`ats.trace.enabled[documentation]`"
    ":hlm-p:`ats.emulator.enable`", "[allowed]", ":hlm-p:`ats.emulator.enable[documentation]`"
    ":hlm-p:`ats.singledrop.enabled`", "[allowed]", ":hlm-p:`ats.singledrop.enabled[documentation]`"
    ":hlm-p:`ats.multiset.enabled`", "[allowed]", ":hlm-p:`ats.multiset.enabled[documentation]`"
    ":hlm-p:`ats.delta.enabled`", "[allowed]", ":hlm-p:`ats.delta.enabled[documentation]`"
    ":hlm-p:`ats.java.importer.enabled`", "[allowed]", ":hlm-p:`ats.java.importer.enabled[documentation]`"
    ":hlm-p:`ats.tdriver.enabled`", "[allowed]", ":hlm-p:`ats.tdriver.enabled[documentation]`"


For example:

.. code-block:: xml

    <property name="ats.enabled" value="true" />


Supported Test Frameworks
=========================
In this section only Helium specific properties, targets or other related issues are discussed to configure the following test frameworks. However, as mentioned earlier, there are test asset guidelines to setup test components for different test frameworks.  

ASTE
----
* ASTE tests can be enabled by setting :hlm-p:`aste.enabled` (see table-3).
* `SW Test Asset`_ location and type of test should be known as a prerequisite.
* To configure the ASTE tests, aste specific properties are required in addition to those in table-1 

<#if !(ant?keys?seq_contains("sf"))>
.. _`SW Test Asset`: http://s60wiki.nokia.com/S60Wiki/MC_SW_Test_Asset_documentation
</#if>

.. csv-table:: Table: ATS - ASTE properties
   :header: "Property name", "Edit status", "Description"
   
    ":hlm-p:`ats.aste.testasset.location`", "[must]", ":hlm-p:`ats.aste.testasset.location[documentation]`"
    ":hlm-p:`ats.aste.software.release`", "[must]", ":hlm-p:`ats.aste.software.release[documentation]`"
    ":hlm-p:`ats.aste.software.version`", "[must]", ":hlm-p:`ats.aste.software.version[documentation]`"
    ":hlm-p:`ats.aste.testasset.caseids`", "[recommended]", ":hlm-p:`ats.aste.testasset.caseids[documentation]`"
    ":hlm-p:`ats.aste.language`", "[recommended]", ":hlm-p:`ats.aste.language[documentation]`"
    ":hlm-p:`ats.aste.test.type`", "[recommended]", ":hlm-p:`ats.aste.test.type[documentation]`"
    ":hlm-p:`ats.aste.plan.name`", "[recommended]", ":hlm-p:`ats.aste.plan.name[documentation]`"
    ":hlm-p:`ats.aste.testrun.name`", "[recommended]", ":hlm-p:`ats.aste.testrun.name[documentation]`"
    ":hlm-p:`ats.aste.email.list`", "[recommended]", ":hlm-p:`ats.aste.email.list[documentation]`"


An example of setting up ASTE properties:
    
.. code-block:: xml
    
    <property name="ats.aste.testasset.location" value="" />
    <property name="ats.aste.software.release" value="SPP 51.32" />
    <property name="ats.aste.software.version" value="W810" />
    <property name="ats.aste.testasset.caseids" value="100,101,102,104,106," />
    <property name="ats.aste.language" value="English" />
    <property name="ats.aste.test.type" value="smoke" />
    <property name="ats.aste.plan.name" value="plan" />
    <property name="ats.aste.testrun.name" value="${r'$'}{build.id}_${r'$'}{ats.product.name}_${r'$'}{major.version}.${r'$'}{minor.version}" />
    <property name="ats.aste.email.list" value="temp.user@company.com; another.email@company.com" /> 


EUnit
-----
* Test framework is selected if there is a library ``eunit.lib`` in the ``.mmp`` file of a test component
* Following EUnit specific properties are required in addition to those in table-1 and table-2.

.. csv-table:: Table: ATS - ASTE properties
   :header: "Property name", "Edit status", "Description"
   
    ":hlm-p:`eunit.test.package`", "[allowed]", ":hlm-p:`eunit.test.package[documentation]`"
    ":hlm-p:`eunitexerunner.flags`", "[allowed]", ":hlm-p:`eunitexerunner.flags[documentation]`"


An example of setting up ASTE properties as in the above table:
    
.. code-block:: xml
    
    <property name="eunit.test.package" value="" />
    <property name="eunitexerunner.flags" value="/E S60AppEnv /R Off" /> 


MTF
---
* The test framework is selected if there is a library ``testframeworkclient.lib`` in the ``.mmp`` file of a test component
* There is no MTF specific configuration for Helium in addition to those in table-1 and table-2.


QtTest
------
* The test framework is selected if there is a library ``QtTest.lib`` in the ``.mmp`` file of a test component
* There are several ``.PKG`` files created after executing ``qmake``, but only one is selected based on a set target platform. See (:hlm-p:`ats.target.platform`) description in table-2.
* Properties in table-1 and table-2 should also be configured.


RTest
-----
* The test framework is selected if there is a library ``euser.lib`` and a comment ``//RTEST``in the ``.mmp`` file of a test component.
* There is no RTest specific configuration for Helium in addition to those in table-1 and table-2.
  

STF
---
* The test framework is selected if there is ``ModuleName=TEFTESTMODULE`` in ``.ini`` file of a component.
* There is no STF specific configuration for Helium in addition to those in table-1 and table-2.
* To enable STF for ATS set, :hlm-p:`ats.stf.enabled` (see table-3). By default this is not enabled.


STIF
----
* The test framework is selected if there is a library ``stiftestinterface.lib`` in the ``.mmp`` file of a test component
* There is no STIF specific configuration for Helium in addition to those in table-1 and table-2.


SUT
---
* The test framework is selected if there is a library ``symbianunittestfw.lib`` in the ``.mmp`` file of a test component
* There is no SUT specific configuration for Helium in addition to those in table-1 and table-2.


TEF
---
* The test framework is selected if there is a library ``testframeworkclient.lib`` in the ``.mmp`` file of a test component
* There is no TEF specific configuration for Helium in addition to those in table-1 and table-2.


TDriver
-------
* TDriver tests can be enabled by setting :hlm-p:`ats.tdriver.enabled` (see table-3).
* TDriver Test Asset location should be known as a prerequisite.
* Following TDriver specific properties are required in addition to those in table-1.
 

.. csv-table:: Table: ATS Ant properties
   :header: "Property name", "Edit status", "Description"
   
    ":hlm-p:`ats.tdriver.enabled`", "[must]", ":hlm-p:`ats.tdriver.enabled[documentation]`"
    ":hlm-p:`tdriver.asset.location`", "[must]", ":hlm-p:`tdriver.asset.location[documentation]`"
    ":hlm-p:`tdriver.test.profiles`", "[must]", ":hlm-p:`tdriver.test.profiles[documentation]`"
    ":hlm-p:`tdriver.tdrunner.enabled`", "[must]", ":hlm-p:`tdriver.tdrunner.enabled[documentation]`"
    ":hlm-p:`tdriver.test.timeout`", "[must]", ":hlm-p:`tdriver.test.timeout[documentation]`"
    ":hlm-p:`tdriver.parameters`", "[must]", ":hlm-p:`tdriver.parameters[documentation]`"
    ":hlm-p:`tdriver.sis.files`", "[must]", ":hlm-p:`tdriver.sis.files[documentation]`"
    ":hlm-p:`tdriver.tdrunner.parameters`", "[must]", ":hlm-p:`tdriver.tdrunner.parameters[documentation]`"
    ":hlm-p:`tdriver.template.file`", "[allowed]", ":hlm-p:`tdriver.template.file[documentation]`"
    

An example of setting up TDriver properties:

.. code-block:: xml

    <property name="ats.tdriver.enabled" value="true" />
    <property name="tdriver.asset.location" value="\\server\share\tdriver_testcases, x:\dir\tdriver_testcases," />
    <property name="tdriver.test.profiles" value="bat, fute" />
    <property name="tdriver.tdrunner.enabled" value="true" />
    <property name="tdriver.test.timeout" value="1200" />
    <property name="tdriver.parameters" value="x:\dir\tdriverparameters\tdriver_parameters.xml" />
    <property name="tdriver.sis.files" value="x:\sisfiles\abc.sis#f:\data\abc.sis#C:\abc.sis, x:\sisfiles\xyz.sis#f:\data\xyz.sis#F:\xyz.sis" />
    <property name="tdriver.tdrunner.parameters" value="--ordered" />
    <property name="tdriver.template.file" value="x:\dir\templates\tdriver_template_2.xml" />


* To execute the tests, :hlm-t:`tdriver-test` target should be called.
* To create custom templates for TDriver, read `Instructions for creating TDriver custom template`_.


.. _`Instructions for creating TDriver custom template`: tdriver_template_instructions.html



Test Automation Features
========================

CTC (Code Coverage)
-------------------

* To enable ctc for ATS set, :hlm-p:`ats.ctc.enabled` (see table-3).
* To compile components for CTC see `configure CTC for SBS`_ 

.. _`configure CTC for SBS`: ../helium-antlib/sbsctc.html

* Once ATS tests have finished results for CTC will be shown in Diamonds.
* The following are optional CTC properties

.. csv-table:: Table: ATS Ant properties
   :header: "Property name", "Edit status", "Description"
   
    "``ctc.instrument.type``", "[allowed]", "Sets the instrument type"
    "``ctc.build.options``", "[allowed]", "Enables optional extra arguments for CTC, after importing a parent ant file."


For example,

.. code-block:: xml
    
    <property name="ctc.instrument.type" value="m" />

    <import file="../../build.xml" />
    
    <hlm:argSet id="ctc.build.options">
        <arg line="-C OPT_ADD_COMPILE+-DCTC_NO_START_CTCMAN" />
    </hlm:argSet>

Or

.. code-block:: xml

    <hlm:argSet id="ctc.build.options">
        <arg line='-C "EXCLUDE+*\sf\os\xyz\*,*\tools\xyz\*"'/>
    </hlm:argSet>


See `more information on code coverage`_.

<#if !(ant?keys?seq_contains("sf"))>
.. _`more information on code coverage`: http://s60wiki.nokia.com/S60Wiki/CTC
<#else>
.. _`more information on code coverage`: http://developer.symbian.org/wiki/index.php/Testing_Guidelines_for_Package_Releases#Code_coverage
</#if>



Customized test XML files
-------------------------

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

The files must be in the directory 'custom' under the 'tsrc' or 'group' folder to be processed. 

The files need to be proper XML snippets that fit to their place. In case of an error an error is logged and a comment inserted to the generated XML file.

A postaction section customization file (prepostaction.xml or postpostaction.xml) could look like this

.. code-block:: xml

   <action>
        <type>RunProcessAction</type>
        <parameters>
            <parameter value="java" name="command"/>
            <parameter value="-version" name="parameters"/>
        </parameters>
   </action>

The ``prestep_custom.xml`` can be used to flash and unstall something custom.

.. code-block:: xml

   <task>
      <type>FileUploadTask</type>
      <parameters>
          <parameter name="src" value="Nokia_Energy_Profiler_1_1.sisx"/>
          <parameter name="dst" value="c:\data\Nokia_Energy_Profiler_1_1.sisx"/>
          <parameter name="reboot-retry-count" value="1"/>
          <parameter name="retry-count" value="1"/>
      </parameters>
  </task>



And then the  ``prerun_custom.xml`` can be used to execute a task.

.. code-block:: xml

   <task>
        <type>NonTestExecuteTask</type>
        <parameters>
            <parameter value="true" name="local"/>
            <parameter value="daemon.exe" name="file"/>
            <parameter value="test.cfg" name="parameters"/>
            <parameter value="true" name="async"/>
            <parameter value="my_daemon" name="pid"/>
        </parameters>
   </task>

**Note:** The users is expected to check the generated test.xml manually, as there is no validation. Invalid XML input files will be disregarded and a comment will be inserted to the generated XML file.


Custom templates/drops
----------------------
* If you need to send a static drop to ATS then you can call the target :hlm-t:`ats-custom-drop`.
* An example template is in helium/tools/testing/ats/templates/ats4_naviengine_template.xml
* Then set a property to your own template, as follows.

.. code-block:: xml

    <property name="ats.custom.template" value="path/to/mytemplate.xml" />


Overriding XML values
---------------------
* Set the property ``ats.config.file`` to the location of the config file.

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


Delta testing
-------------


Multiset support
----------------
* Enable the feature by setting property :hlm-p:`ats.multiset.enabled` to ``true``.
* If enabled, a 'set' in test.xml, is used for each pkg file in a component, this allows tests to run in parallel on several devices.

ROM Bootup Tests
----------------
* ROM images can be tested on ATS by executing target ":hlm-t:`ats-bootup-test`". This feature is useful to test whther the created ROM images boot-up a device or not . 
* To enable this feature, set a property ":hlm-p:`ats.bootuptest.enabled`" (see table-3) 
* In addition to enable the feature, properties in the table-1 are also required.
    

Single/Multiple test drops creation
-----------------------------------
* It is mentioned earlier in Step 1, that components can be grouped together.
* During automation, separate TestDrops are created based on these groups.
* This grouping can be neglected and a single test drop can be created by setting a property :hlm-p:`ats.singledrop.enabled` By default the value is 'false'. For example, 


.. code-block:: xml
    
    <property name="ats.singledrop.enabled" value="true" />
    


Skip uploading test drops
-------------------------
* ``ats-test`` target can only create a drop file, and does not send the drop (or package) to ATS server.
* To use the feature, set the following property to ``flase``.

.. code-block:: xml

    <property name="ats.upload.enabled" value="false" />


<#if !(ant?keys?seq_contains("sf"))>

Support for multiple products (ROM images)
------------------------------------------

See: `Instructions for setting up  multiple roms and executing specific tests`_.

.. _`Instructions for setting up  multiple roms and executing specific tests`: http://helium.nmp.nokia.com/doc/ido/romandtest.html


</#if>


Testing with Winscw Emulator
----------------------------
* If enabled, ``ats-test`` target creates a zip of build area instead of images for use by emulator on ATS server.
* Set a property as follows.

.. code-block:: xml

    <property name="ats.emulator.enable" value="true" />


<#if !(ant?keys?seq_contains("sf"))>

Tracing
-------
* Currently there isn't a single standard method of doing tracing in Symbian Platform. 
* Application, middleware, driver and kernel developers have used different methods for instrumenting their code. Due to the different methods used, it is inherently difficult to get a coherent overview of the whole platform when debugging and testing sw.
* Current implementation of Tracing in Helium is based on the instruction given `here`_.
* Tracing can be enabled by setting :hlm-p:`ats.trace.enabled` to ``true`` (see table-3).

.. _`here`: http://s60wiki.nokia.com/S60Wiki/Tracing

</#if>


Troubleshooting TA
==================

.. csv-table:: Table: Trouble shooting test automation
   :header: "Type", "Description", "Possible solution"
   
    "Error", "'*<path>*' not found", "Either the PKG file does not exist or incorrect filename."
    "Error", "No test modules found in '*<path>*'", "This error is raised when there is no test components available. Check that your components are in the SystemDefinition files, and that the filters are set accordingly to the test asset documentation and that the components actually exists in the asset." 
    "Error", "'*<path>*' - test source not found", "Path in the bld.inf file is either incorrect or the component does not exist."
    "Error", "Not enough flash files: # defined, # needed", "Check property :hlm-p:`ats.flashfiles.minlimit`. Selected ROM images files # is lesser than the required no. of files. This error can also be eliminated by reducing the value of the property."
    "Error", "'CPP failed: '<command>' in: '*<path>*'", "Check the path and/or the file. There can be broken path in the file or mising directives and macros."
    "Error", "*<path>* - test sets are empty", "missing/invalid deirectives and/or project macros. The .mmp file ca be missing."
    
    
