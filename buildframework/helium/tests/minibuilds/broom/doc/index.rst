.. index::
  module:  Minibuild Broom configuration

===============================
Minibuild Broom configuration
===============================


.. index::
  single:  Minibuild Broom coverage

Coverage
========

* delete-folders-from-list

.. index::
  single:  Minibuild Broom Setup

Minubuild setup
===============

What is required?
-----------------

* Build machine
* Build Area with a valid S60 environment (eg. PF5250)
* Helium (obviously)



  
.. index::
  single:  Minibuild Broom coverage - how to run

How to run the build?
---------------------

The command line to run the build is the following::

   hlm -Dbuild.drive=%BUILD_DRIVE% -Dbuild.number=01 mini-build


You only need to provide the following properties:
* build.drive: location of the build area
* build.number: the build number


