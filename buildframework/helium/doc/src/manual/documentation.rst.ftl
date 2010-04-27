<#--
============================================================================ 
Name        : documentation.rst.ftl
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
  module: Documentation

###################
Documentation
###################


.. contents::


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

* `Ant Tasks`_

.. _`Ant Tasks`: ../api/ant/index.html

<#if !(ant?keys?seq_contains("sf"))>
Customer APIs
-------------

* `IDO API`_
* `DFS70501 API`_

.. _`IDO API`: ../ido/api/helium/index.html
.. _`DFS70501 API`: ../dfs70501/api/helium/index.html
</#if>

Building custom documentation
=============================

Documentation for any Helium configuration can be built using ``hlm docs``. The paths to RST documentation source directories must be defined using either a property for a single path or a resources element for multiple paths::

    <property name="doc.src.dir" location="basedir_path/docs/src" />
    
    <resources id="textdoc.paths">
        <path>
            <pathelement path="basedir_path/docs/src"/>
            <pathelement path="basedir_path/docs/src2"/>
        </path>
    </resources>



