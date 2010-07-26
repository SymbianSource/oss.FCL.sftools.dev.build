<#--
============================================================================ 
Name        : stage_matti.rst.inc.ftl
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

.. csv-table:: ATS Ant properties
   :header: "Property name", "Edit status", "Description"
   
    ":hlm-p:`matti.scripts`", "[must]", "The location of the test scrips as ruby test files i.e. .rb files."
    ":hlm-p:`enabled.matti`", "[must]", "Enable MATTI testing to occur, if not present the target :hlm-t:`matti-test` will not run."
    ":hlm-p:`template.file`", "[must]", "Location of the matti template file."
    ":hlm-p:`ats.sis.images.dir`", "[recommended]", "Location of the the SIS installation files needed to flash to the phone (if required and present)."
    ":hlm-p:`ats.script.type`", "[must]", "Always set to import, this means the MATTI server will retrieve the tests."
    ":hlm-p:`ats.image.type`", "[must]", "Image type whether Engineering English or localised."
    ":hlm-p:`ats.flashfiles.minlimit`", "[must]", "Minimum number of flash files required in to add to the drop file."
    ":hlm-p:`tsrc.data.dir`", "[recommended]", "Test source code data directory. only required for testing the Ant MATTI code."
    ":hlm-p:`ta.flag.list`", "[recommended]", "TA flag list."
    

All you need to do is setup the following parameters:

.. code-block:: xml

    <property name="enabled.matti" value="true" />
    <property name="matti.scripts" value="${r'$'}{helium.dir}/tests/data/matti" />
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

In order to upload and view the test run you need to have a valid user ID and password that matches that in your ``.netrc`` file. To create the account open a web browser window and enter the name of the ats.server with /ATS at the end e.g. http://123456:80/ATS. Click on the link in the top right hand corner to create the account. To view the test run once your account is active you need to click on the 'test runs' tab.

To run the tests call the target :hlm-t:`matti-test` (you will need to define the :hlm-p:`build.drive`, :hlm-p:`build.number` and it is best to create the :hlm-p:`core.build.version` on the command line as well if you do not add it to the list of targets run that create the ROM image). e.g.
::

    hlm -Dbuild.number=001 -Dbuild.drive=z: -Dcore.build.version=001 matti-test

If it displays the message 'Testdrop created!' with the file name then the ``MATTIDrops.py`` script has done what it needs to do. The next thing to check is that the drop file has been uploaded to the ATS server OK. If that is performed successfully then the rest of the testing needs to be performed by the ATS server. There is also a ``test.xml`` file created that contains details needed for debugging any problems that might occur. To determine if the tests have run correctly you need to read the test run details from the server.
