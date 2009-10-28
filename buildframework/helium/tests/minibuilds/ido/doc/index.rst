.. index::
  module:  Minibuild IDO compile configuration

===================================
Minibuild IDO compile configuration
===================================


.. index::
  single:  Minibuild IDO compile configuration - coverage

Coverage
========

* Automatic environment update. 
* IDO specific target (relying on layers.sysdef.xml)


.. index::
  single:  Minibuild IDO compile configuration - setup

Minubuild setup
===============

What is required?
-----------------

* Build machine
* Helium (obviously)


  
.. index::
  single:  Minibuild IDO compile configuration - how to run

How to run the build?
---------------------

The command line to run the build is the following::

   hlm -Dbuild.drive=%BUILD_DRIVE% -Dbuild.number=01 mini-build


You only need to provide the following properties:
* build.drive: location of the build area
* build.number: the build number


