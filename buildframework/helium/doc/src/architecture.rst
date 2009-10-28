###########################
Helium Architecture
###########################

.. index::
  module: Helium Architecture


.. contents::

Introduction
============

.. raw:: html
   :file: helium_overview.html
   
This is a overview of the Helium toolkit and its dependencies as a stack.
   
.. index::
  single: Architectural Principles

Architectural principles
========================

**Favour reusing existing software over writing new code.** There is a lot of useful open-source software available. If the license is sufficiently open it is better to use what exists. Development of new features should check for any existing software that may fulfill some or all of the implementation requirements.

**Favour reusable libraries over standalone scripts.** Object-orientated programming and the development of libraries encourages reusability, reduced maintenance and higher quality.

**Develop unit tests for testing the libraries.** Unit testing is important for regression testing and for agile development within a team. A developer can make changes and have confidence that no functionality has broken by running the unit tests.

**Prefer platform independence.** The selection of tools and the development of libraries and scripts is done in a way that maximises independence from the underlying OS or hardware platform. Where specific dependencies are required they are configurable. Shell commands should be restricted to the set supported by the Unix Utils package on Windows, to ensure compatibility between Linux and Windows.

.. index::
  single: Archtectural References

References
----------

* The Pragmatic Programmer, Andrew Hunt and David Thomas. See the `list of tips`_.

.. _`list of tips` : http://www.pragmaticprogrammer.com/ppbook/extracts/rule_list.html


.. index::
  single: Architectural Practices

Practices
=========

Files created in Ant, Perl, Python or XML syntax must follow the `Style guide <coding_conventions.html>`_.


.. index::
  single: Architectural Configuration

Configuration
=============

XML is recommended for defining configuration files. Ant configuration types and tasks should be used where most logical. If a more structured configuration is needed then a custom XML schema can be defined. Existing schemas should be reused where possible.

(add existing schemas)

.. index::
  single: APIs

APIs 
=========

See the reference API documentation:

* `Helium API`_
* `Java APIs`_
* `Python APIs`_
* `Custom Ant tasks`_

.. _`Helium API` : api/helium/index.html
.. _`Java APIs` : api/java/index.html
.. _`Python APIs` : api/python/index.html
.. _`Custom Ant tasks` : api/ant/index.html


.. index::
  single: Tools and scripts locations

Tools and scripts locations
===========================

All tools used by Helium (which means called by Ant at some point during a build sequence, directly or indirectly) come from one of these locations:

* **Inside /helium/tools**. Content is generally developed or imported by the Helium team and is our responsibility. We strive to test it using unit tests where possible and general build execution. It should follow Helium coding guidelines. This may be libraries closely integrated with Ant, or standalone tools called by Ant like iCreatorDP.
* **Inside /helium/external**. These are tools provided by an external party, which could be open source projects or other teams in Nokia. Updates are the responsibility of the maintainer. Typically Helium developers will import the updates, but if agreed the supplier might also directly make the update. If the content is currently provided as a Synergy project it is desirable to simply use releases of that.
* **Inside /epoc32**. This covers the Symbian toolchain, iMaker, etc. At the point where the tool is needed it should have been exported into /epoc32.
* **Already Installed**. All language runtimes such as Java, Perl and Python.

.. index::
  single: Dependency Diagram

Dependency Diagram
==================

.. image:: images/dependencies.grph.png