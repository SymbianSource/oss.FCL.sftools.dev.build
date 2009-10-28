.. index::
  module:  Minibuild iMaker configuration

===================================
Minibuild iMaker configuration
===================================


.. index::
  single:  Minibuild iMaker configuration - coverage

Coverage
========

* Automatic environment update. 
* Testing latest version of iMaker (from svn).


.. index::
  single:  Minibuild iMaker configuration - Setup

Minubuild setup
===============

What is required?
-----------------

* Build machine
* Helium (obviously)


  
.. index::
  single:  Minibuild iMaker configuration - how to run

How to run the build?
---------------------

The command line to run the build is the following::

   hlm -Dbuild.drive=%BUILD_DRIVE% -Dbuild.number=01 mini-build


You only need to provide the following properties:
* build.drive: location of the build area
* build.number: the build number


