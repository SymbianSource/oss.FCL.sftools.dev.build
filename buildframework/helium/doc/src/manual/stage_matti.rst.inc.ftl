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

The set up of parameters is very similar (a few less parameters and it mostly uses ATS values). The main difference is that once the drop file has been uploaded to the ATS server it uses MATTI to perform the tests (the drop file contains the flash files, the ruby tests/sip profiles, data files, sis files and/or parameters file in xml format).

The following parameters are the ones that are not listed in the ATS parameters, all other parameters required are as listed in the ATS section above, which include :hlm-p:`ats.server`, :hlm-p:`ats.email.list`, :hlm-p:`ats.email.format`, :hlm-p:`ats.email.subject`, :hlm-p:`ats.testrun.name`, :hlm-p:`ats.product.name`, :hlm-p:`ats.flashfiles.minlimit`, :hlm-p:`ats.flash.images` and :hlm-p:`ats.upload.enabled`. 

* [must] - must be set by user
* [recommended] - should be set by user but not mandatory
* [allowed] - should **not** be set by user however, it is possible.

.. csv-table:: ATS Ant properties
   :header: "Property name", "Edit status", "Description"
   
    ":hlm-p:`matti.enabled`", "[must]", "Enable MATTI testing to occur, if not present the target :hlm-t:`matti-test` will not run."
    ":hlm-p:`matti.asset.location`", "[must]", "The location of the test asset where  ruby test files, sip profiles, hardware data etc are located."
    ":hlm-p:`matti.test.profiles`", "[must]", "Test profiles to be executed should be mentioned in this comma separated list e.g., 'bat, fute'."
    ":hlm-p:`matti.sierra.enabled`", "[must]", "Mustbe set to 'true' if sierra is engine is to be used. If true .sip files are used otherwise .rb (ruby) files are used to execute tests-"
    ":hlm-p:`matti.test.timeout`", "[must]", "Separate but similar property to ats.test.timeout for matti tests."
    ":hlm-p:`matti.parameters`", "[must]", "Matti test parameters can be given through Matti parameters xml file."
    ":hlm-p:`matti.sis.files`", "[must]", "There are special sis files required to execute with test execution. This is a comma separated list in which several sis files can be deifned in a certain format like '<src file on build area>#<destination to save the file on memory card>#<destination to install the file>' e.g. <x:\dir1\abc.sis#f:\memory1\abc.sis#c:\phonememory\private\abc.sis>"
    ":hlm-p:`matti.sierra.parameters`", "[must]", "Sierra parameters are set using this property. e.g. '--teardown --ordered'"
    ":hlm-p:`matti.template.file`", "[allowed]", "Location of the matti template file."
    

All you need to do is setup the following parameters:

.. code-block:: xml

    <property name="matti.enabled" value="true" />
    <property name="matti.asset.location" value="\\server\share\matti_testcases, x:\dir\matti_testcases," />
    <property name="matti.test.profiles" value="bat, fute" />
    <property name="matti.sierra.enabled" value="true" />
    <property name="matti.test.timeout" value="1200" />
    <property name="matti.parameters" value="x:\dir\mattiparameters\matti_parameters.xml" />
    <property name="matti.sis.files" value="x:\sisfiles\abc.sis#f:\data\abc.sis#C:\abc.sis, x:\sisfiles\xyz.sis#f:\data\xyz.sis#F:\xyz.sis" />
    <property name="matti.sierra.parameters" value="--ordered" />
    <property name="matti.template.file" value="x:\dir\templates\matti_template_2.xml" />
    


In order to upload and view the test run you need to have a valid user ID and password that matches that in your ``.netrc`` file. To create the account open a web browser window and enter the name of the ats.server with /ATS at the end e.g. http://123456:80/ATS. Click on the link in the top right hand corner to create the account. To view the test run once your account is active you need to click on the 'test runs' tab.

To run the tests call the target :hlm-t:`matti-test` (you will need to define the :hlm-p:`build.drive`, :hlm-p:`build.number` and it is best to create the :hlm-p:`core.build.version` on the command line as well if you do not add it to the list of targets run that create the ROM image). e.g.
::

    hlm -Dbuild.number=001 -Dbuild.drive=z: -Dcore.build.version=001 matti-test

If it displays the message 'Matti testdrop created successfully!', script has done what it needs to do. The next thing to check is that the drop file has been uploaded to the ATS server OK. If that is performed successfully then the rest of the testing needs to be performed by the ATS server. There is also a ``test.xml`` file created that contains details needed for debugging any problems that might occur. To determine if the tests have run correctly you need to read the test run details from the server.
