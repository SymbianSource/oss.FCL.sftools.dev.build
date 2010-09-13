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

.. csv-table:: Ant properties to modify
   :header: "Property", "Description", "Values"

   ":hlm-p:`s60.grace.server`", "UNC path to network drive.", ""
   ":hlm-p:`s60.grace.service`", "Service name.", ""
   ":hlm-p:`s60.grace.product`", "Product name.", ""
   ":hlm-p:`s60.grace.release`", "Regular expression to match release under the product directory.", ""
   ":hlm-p:`s60.grace.revision`", "Regular expresion to match a new build revision", "e.g: (_\d+)?"
   ":hlm-p:`s60.grace.cache`",
   ":hlm-p:`s60.grace.checkmd5.enabled`",
   ":hlm-p:`s60.grace.usetickler`", "Validate the release based on the tickler.", "true, false(default)"

Once configured you can invoke Helium:

    > hlm -Dbuild.number=1 -Dbuild.drive=X: ido-update-build-area-grace

    > dir X:
    ...
    ...

You should then have the latest/mentioned release un-archived under the X: drive.