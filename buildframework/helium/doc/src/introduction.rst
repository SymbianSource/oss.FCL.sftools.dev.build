###################
Helium Introduction
###################

.. index::
  module:  Introduction

.. contents::

.. index::
  single:  Introduction

Introduction
=============

This is the user guide and technical description for Helium, an ANT based build framework used to build S60 based products.
This documentation describes how to configure and use the Helium build framework from the point of view of an IDO integrator,
a build manager, a helium contributor and subcon user.

Helium contains all you need in order to create a work area, a build area, perform the compilation, link, create localised 
variants, submit build information to Diamonds (used for statistical analysis), create Data Packages, 
zip the files to create a release and much more. The aim is for helium to be used by every build and release team working on
S60 products within Nokia. It is also used by some Subcons as part of the tool set given to them to allow subcons to build parts
of the S60 code.

Before you start reading about Helium it is very advisable that you are familiar with ANT_ and how it works so  
click on this `ANT link`_ if you are not familiar with ANT_.

.. _ANT link: http://ant.apache.org/
.. _ANT: http://ant.apache.org/

Ant makes great use of XML_ files for its configuration so if you are unfamiliar with XML_ files it is recommended that you read the 
information at the XML_ link.

.. _XML: http://www.w3.org/XML/

There are various parts of this documentation that are only of interest to certain users (in particular the Helium integrator), 
it is hoped that eventually there will 
be separate contents lists for the different users, but for the time being this is not possible, so bare with us.
 

NOTE: for best viewing you should use Windows Internet Explorer 7.0 or newer as version 6.0 has some problems with display of the
navigation bar and contents list.


.. index::
  single:  Vision

Vision
=========

The Helium vision is to fulfill the following demands:

 * A "common unified toolset".
 * Easy to use and configure for all different builds.
   
   * Fully automated builds.
   * Verbose and clear messages.
 
 * Light.
 * Simple things should be easy to do, complex things should be possible.

.. index::
  single:  Background
  
Background
============

Helium was developed from a need to reduce "reinventing the wheel" for build tools. It was based on the mc_tools project which had the same goal within the former MC organization.

.. index::
  single:  Why Ant?
  
Why Ant?
==========

Helium is fundamentally based on Apache ANT_. Why was ANT_ chosen when there were many other similar frameworks inside Nokia,
such as sbt, isis_build and TrombiBuild. The main reason is that while the other toolkits were developed inside Nokia,
ANT_ is an open source tool from Apache, based on relatively simple XML_ files that define the build steps. 
Through leveraging the power of open source Helium has integrated a large amount of functionality that would have taken
much longer to develop in-house, as well as benefit from existing, high-quality documentation.

