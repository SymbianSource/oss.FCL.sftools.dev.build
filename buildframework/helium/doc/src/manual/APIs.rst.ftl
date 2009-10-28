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
  module: API

###################
API
###################


.. contents::

Introduction
============

This section contains the API to Helium.


.. index::
  single: API

APIs
====

* `Search API`_

.. _`Search API`: ../api/index.html

* `Helium API`_

    The `Helium API`_ specifies all the available Ant_ targets and their 
    required properties.  The API is the number one resource to use when 
    building up a Helium configuration.

.. _`Helium API`: ../api/helium/index.html
.. _Ant: http://ant.apache.org

* `Helium Antlib`_

.. _`Helium Antlib`: ../helium-antlib/index.html

<#if !(ant?keys?seq_contains("sf"))>
* `Python API`_

.. _`Python API`: ../api/python/index.html

* `Java API`_

.. _`Java API`: ../api/java/index.html
</#if>

* `Ant Tasks`_

.. _`Ant Tasks`: ../api/ant/index.html

<#if !(ant?keys?seq_contains("sf"))>
Customer APIs
=============

* `IDO API`_
* `DFS70501 API`_

.. _`IDO API`: ../ido/api/helium/index.html
.. _`DFS70501 API`: ../dfs70501/api/helium/index.html
</#if>