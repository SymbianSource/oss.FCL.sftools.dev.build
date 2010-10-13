..  ============================================================================ 
    Name        : coding_conventions.rst
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

##############################
Coding Conventions
##############################

.. index::
  module: Coding Conventions

.. contents::

Introduction
============

This describes how you should write code for Helium. It covers Ant XML, Java and Python.

.. index::
  single: General Conventions

General conventions
===================

* Changing the working directory should be avoided in any language.

.. index::
  single: Ant Conventions
  
Documentation
=============

Standalone documents like this design document and the user guide are documented in reStructuredText_ format.

__ http://docutils.sourceforge.net/rst.html

Run the ``hlm docs`` command to generate documentation under ``/helium/build/doc``.


.. index::
  single: Index References-creating
  
ReStructuredText documentation
------------------------------

Linking to the API reference
````````````````````````````

It is possible to link to targets, properties and macros in the API documentation using a custom reStructuredText__ role, e.g::

    :hlm-t:`target-name`
    
.. csv-table:: Custom API roles
   :header: "Name", "Links to"

   "``hlm-t``", "Targets"
   "``hlm-p``", "Properties"
   "``hlm-m``", "Macros"
   
   
.. note:: It is **not** possible to link to tasks or anything in the Java documentation. 
   
A section of RST documentation might look like this::

    The :hlm-t:`foo` target requires the :hlm-p:`bar` property to be defined. It uses the :hlm-t:`bazMacro` macro.

Fields from the API elements can also be embedded in the RST documentation using an index-like syntax::

    :hlm-p:`bar[summary]`
    
This would extract the ``summary`` field of the ``bar`` property and insert it into the document. The available fields are:
    
.. csv-table:: API element fields
   :header: "Field", "Description"
   
   "summary", "The first sentence or section of the documentation."
   "documentation", "The whole documentation text."
   "scope", "The visibility scope."
   "defaultValue", "The default value if one is defined. Properties only."
   "type", "The type of the element. Properties only."
   "editable", "Whether definition is required or optional. Properties only."
   "deprecated", "Deprecation message."
    
    
Creating Index References
`````````````````````````

In order to get things in the index you have to manually add the following code to the ``.rst`` files: ::
 
  .. index::
     module: file heading (the text in the 1st heading at the top of the page) gets added to index as module

put this text at the top of the file::

  .. index::
    single: heading text

put this just above a heading. This gets added to the index as a normal indexed link.

If you replace 'single' with 'pair' it puts 2 enteries in the index:::
 
  .. index::
     pair: iname1; ename2

In the index it becomes iname1 with ename2 below it and indented (in the 'i' section) and also ename2 with iname1 
below it and indented (in the 'e' section)

The index directive needs blank lines either side of it.

Ant conventions
======================

These conventions are applicable to all Ant XML script files.

API documentation
-----------------

The Helium API documentation is generated directly from the Ant source files. Additional documentation for Ant objects (properties, targets, macros, etc) and special markup is defined in a similar style to JavaDoc, following these conventions:

* Additional documentation is written as XML comments.
* Typically the preceeding comment for an Ant object is assumed to relate to that object. A comment can be definitively noted as a Ant documentation comment by adding a ``*`` character at the start.
* The text format of the documentation can be formatted in MediaWiki_ format.
* The first sentence of the comment is taken as the summary for short text fields. The rest of the text is the full documentation.
* Specific metadata tags are defined using ``@``. Each tag should be on a newline and all tags should be after the general documentation paragraphs::

    <!--* comment text
    
    @scope private
    -->
    
.. _MediaWiki: http://www.mediawiki.org/wiki/Help:Formatting

* A number of tags are supported:

.. csv-table:: Ant comment tags
   :header: "Tag", "Applies to", "Description"

   "scope", "All elements", "The scope or visibility of the element. Valid values are ``public`` (default), ``protected`` and ``private``."
   "editable", "All types", "Indicates whether the property must be defined or not. Valid values are ``required`` and ``optional``. ``required`` means it must be defined for the related feature to work. The user must define it if there is no default value, i.e. it is not already defined in Helium."
   "type", "Properties", "The type of the property value. Valid values are ``string`` (default), ``integer``, ``boolean``."
   "deprecated", "All elements", "Documents that the element is deprecated and may be removed in a future release. The text should describe what to use instead."

* Some properties (and other types) are only defined by the user, so there is no default declaration inside Helium. These can be documented completely within a comment::

    <!--* @property name.of.property
    This property must be defined by the user.
    
    @scope public
    @editable required
    @type integer
    -->
    
Projects
````````

* Project comments must have the ``*`` character in order to avoid assuming that the copyright comment block is project documentation::
  
    <!--* comment text -->

* A project can be defined as a member of a package in this way::

    <!-- @package framework -->
    
    
.. index::
  single: XML Indentations

XML indentation
---------------

* Indents are 4 spaces. Tabs should not be used.
* The XML element structure should be consistently indented.

.. index::
  single: File Names

File names
----------

* Ant files intended to be called by a ``bld.bat`` should be named ``build.xml`` (the default name Ant looks for).
* All other Ant files should end with "``.ant.xml``".

.. index::
  single: File Organisation

File organisation
-----------------

* ``helium.ant.xml`` is the root Ant file under ``/helium`` that includes all the other Ant files.
* ``helium.ant.xml`` should only include top-level build stage Ant files, e.g. ``preparation.ant.xml``. Within each build stage directory, further Ant files should be included by that build stage file. This reduces frequent edits to ``helium.ant.xml``.

.. index::
  single: Targets

Targets
-----------

* Target names are a mix of lowercase letters and numbers and the '-' character.
* Configuration files needed as input to external scripts/tools are not defined as arguments using any kind of hardcoded path (absolute or relative). Rather an Ant property should define the path to the file and that property value is used as the argument in the call to the tool.
* Ant properties are used in preference (where the option exists) to external environment variables (that start with ``env.``).
* Targets can be marked as deprecated by adding one optional tag ``<deprecated> value </deprecated>`` in the comment tag top of the target area.
* Targets can be marked as private by adding ``Private:`` in the comment tag top of the target area.

.. index::
  single: Properties

.. _properties_label:

Properties
----------

* Properties are named using lowercase words separated by the '.' character.
* Values should not have any dependencies on the location of the ``helium`` project. Based on the ``HELIUM_HOME`` setting, the project could be anywhere, so paths should not assume it to be relative to any other location.
* Properties can be marked as deprecated in the data model by adding one optional tag ``<deprecated>``.

.. csv-table:: Property naming conventions
   :header: "Rule", "Description"
   
   "File paths", "Property name should end with ``.file``"
   "Directory paths", "Property name should end with ``.dir``. The ``location`` attribute is recommended over ``value``. No trailing slashes are required. Paths should use other properties such as ``build.drive`` to be flexible. Forward slashes should be used, unless backslashes are specifically needed."
   "Value list", "Property name should end with ``.list``."

Ant tasks
---------

There are two preferred ways to implement an Ant task:

* A pure Java Task subclass.
* A ``<scriptdef>`` task using Jython.

In general these guidelines should be noted:

* Use short, descriptive task names that fit with the Ant naming style. All custom tasks should be under the ``hlm:`` namespace.
* Avoid referencing property values directly inside the task implementation. Data values should typically be passed as attributes.
* Do not put large chuck Jython code inside Ant side, make sure the functional part of the code is unit-tested.

Implement using tasks when the functionality may be used in more than one place or it will help the design and maintenance to provide a well-defined interface for that function.

Scripts
-------

A script allows more flexible code than is provided by the standard tasks while not being as formalized as a new custom task. There are two preferred ways to implement embedded scripts:

* A ``<script>`` task using Jython.
* A ``<hlm:python>`` task using embedded Python code. This typically does not allow much interaction with the Ant process.

Here properties can be accessed directly but it is good practice to only reference them in the embedded code. If the functionality is significant create separate Python libraries as needed and call them from the embedded script, e.g::

    <hlm:python>
    import mycode
    mycode.dostuff(r'${prop.1}')
    </hlm:python>
    
    <script language="jython">
    import mycode
    value = mycode.dostuff(project.getProperty('prop.1'))
    project.setProperty('xyz', value)
    </script>
    
Use a script when prototyping or a more specialized operation is needed in only one place. Embedded scripts should generally be kept as short as possible.

.. index::
  single: Java conventions

Java conventions
================

.. index::
  single: Ant Task Documentions

Ant task documentation
----------------------

* Javadoc comment of a Ant task class should include the Ant-specific tag ``@ant.task``. It accepts three "attributes": ``name``, ``category`` and ``ignored``. When ``ignored=true``, the class will not be included in the documentation. For example::
    
    /**
     * Code Sample for Ant Task class Comments
     * @ant.task name="copy" category="filesystem"
     * @ant.task ignored="true"
     */
    public class Copy

* The task properties documentation is extracted from the property getter/setter methods. The tags are ``@ant.required`` and ``@ant.not-required`` which indicate if the property is required or not required. For example::

    /**
     * Code Sample for Ant Task property Comments
     * @ant.required 
     * Default is false.
     */
    public void setOverwrite(boolean overwrite){ 
        this.forceOverwrite = overwrite;
    }

All custom tasks should be commented in this way.

.. index::
  single: File Execution

File execution
==============

File execution should not depend on the extension of the file. The appropriate executable should be used to run the script, e.g::

    python foo.py
    
not::

    foo.py


.. index::
  single: Documentation conventions

Documentation conventions
=========================

Standalone documents are written in reStructuredText_ format.

.. _reStructuredText : http://docutils.sourceforge.net/rst.html


.. index::
  single: Python conventions

Python conventions
=========================

Specific conventions
--------------------

Python Code Indentation
```````````````````````

* Indents are 4 spaces. Tabs should not be used.


Documentation
`````````````

* Docstrings are written in reStructuredText_ format, according to `PEP 257 - Docstring Conventions`_. Documentation is extracted using Epydoc_, so the reStructuredText tags that Epydoc recognises are used.

.. _`PEP 257 - Docstring Conventions` : http://www.python.org/dev/peps/pep-0257/
.. _Epydoc : http://epydoc.sourceforge.net/


Unit testing
````````````

* Unit tests are written for each Python module.
* They should follow the Nose_ testing framework conventions.
* The test suite is run by calling ``bld test``.

.. _Nose : http://somethingaboutorange.com/mrl/projects/nose/


Lint 
````

* Always check your code with pylint_ before checking it in.
* Aim for pylint_ score >= 8.

.. _pylint: http://www.logilab.org/857


Reference coding standards
--------------------------

These reference standards are used for all conventions not covered above.

* `PEP 8 - Style Guide for Python Code`_.
* `Twisted Coding Standard`_ (but with a grain of salt):

.. _`PEP 8 - Style Guide for Python Code` : http://www.python.org/dev/peps/pep-0008/
.. _`Twisted Coding Standard` : http://twistedmatrix.com/documents/current/core/development/policy/coding-standard.html


.. index::
  single: Quality Checklist

Quality checklist
=================

'''Python'''

* All modules have a single description line in the module comment.

.. index::
  single: Bad Word Scanner configuration

Bad Word Scanner configuration
==============================

This section will probably only ever be used by a helium contributor:

Bad word scanner scans the helium code for the words that should not be in the helium source code. You need to include the bad words
in a .cvs file and scan the directory of the source code. Bad words include Nokia product names, competitors product names etc.

Run the following command ::

    hlm check-bad-words