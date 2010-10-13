<#--
============================================================================ 
Name        : stage_preparation.rst.inc.ftl
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
  single: Stage - Preparation

Stage: Preparation
==================

At the start of preparation a new directory is created for the build and subst'ed to ``build.drive``. If a directory with this name already exists, it is renamed to have a current timestamp on the end.

.. index::
  single: How to prepare the build area

How to prepare the build area
-----------------------------

Helium supports the creation of an environment based on a release store in a network drive. The main requirement from that release is to publish release metadata with the content.

.. csv-table:: Ant properties to modify for Helium 11 and older
   :header: "Property", "Description", "Values"

   ":hlm-p:`s60.grace.server`", ":hlm-p:`s60.grace.server[summary]`", ":hlm-p:`s60.grace.server[defaultValue]`"
   ":hlm-p:`s60.grace.service`", ":hlm-p:`s60.grace.service[summary]`", ":hlm-p:`s60.grace.service[defaultValue]`"
   ":hlm-p:`s60.grace.product`", ":hlm-p:`s60.grace.product[summary]`", ":hlm-p:`s60.grace.product[defaultValue]`"
   ":hlm-p:`s60.grace.release`", ":hlm-p:`s60.grace.release[summary]`", ":hlm-p:`s60.grace.product[defaultValue]`"
   ":hlm-p:`s60.grace.revision`", ":hlm-p:`s60.grace.revision[summary]`", ":hlm-p:`s60.grace.revision[defaultValue]`"
   ":hlm-p:`s60.grace.cache`", ":hlm-p:`s60.grace.cache[summary]`", ":hlm-p:`s60.grace.cache[defaultValue]`"
   ":hlm-p:`s60.grace.checkmd5.enabled`", ":hlm-p:`s60.grace.checkmd5.enabled[summary]`", ":hlm-p:`s60.grace.checkmd5.enabled[defaultValue]`"
   ":hlm-p:`s60.grace.usetickler`", ":hlm-p:`s60.grace.usetickler[summary]`", ":hlm-p:`s60.grace.usetickler[defaultValue]`"


.. csv-table:: Ant properties to modify for Helium 12
   :header: "Property", "Description", "Values"

   ":hlm-p:`download.release.server`", ":hlm-p:`download.release.server[summary]`", ":hlm-p:`download.release.server[defaultValue]`"
   ":hlm-p:`download.release.service`", ":hlm-p:`download.release.service[summary]`", ":hlm-p:`download.release.service[defaultValue]`"
   ":hlm-p:`download.release.product`", ":hlm-p:`download.release.product[summary]`", ":hlm-p:`download.release.product[defaultValue]`"
   ":hlm-p:`download.release.regex`", ":hlm-p:`download.release.regex[summary]`", ":hlm-p:`download.release.regex[defaultValue]`"
   ":hlm-p:`download.release.revision`", ":hlm-p:`download.release.revision[summary]`", ":hlm-p:`download.release.revision[defaultValue]`"
   ":hlm-p:`download.release.cache`", ":hlm-p:`download.release.cache[summary]`", ":hlm-p:`download.release.cache[defaultValue]`"
   ":hlm-p:`download.release.checkmd5.enabled`", ":hlm-p:`download.release.checkmd5.enabled[summary]`", ":hlm-p:`download.release.checkmd5.enabled[defaultValue]`"
   ":hlm-p:`download.release.usetickler`", ":hlm-p:`download.release.usetickler[summary]`", ":hlm-p:`download.release.usetickler[defaultValue]`"

Once configured you can invoke Helium::

    hlm -Dbuild.number=1 -Dbuild.drive=X: ido-update-build-area

You should then have the latest release extracted to the X: drive.

<#if !ant?keys?seq_contains("sf")>
.. include:: stage_nokia_preparation.rst.inc
</#if>