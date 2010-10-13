..  ============================================================================ 
    Name        : running.rst
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

This is the manual for Helium, an Ant-based build framework used to build Symbian Devices products. This documentation describes how to configure and use the Helium build framework from the point of view of an IDO integrator, a build manager, a helium contributor and subcon user.

Helium contains all you need in order to create a work area, a build area, perform the compilation, link, create localised variants, submit build information to Diamonds (used for statistical analysis), create Data Packages, zip the files to create a release and much more. The aim is for helium to be used by every build and release team working on Symbian products within Nokia. It is also used by some Subcons as part of the tool set given to them to allow subcons to build parts
of the S60 code.

It is recommended to read the Ant_ documentation before learning about Helium. An understanding of XML_ is also needed as Ant_ is configured using an XML_ format.

.. _Ant: http://ant.apache.org/
.. _XML: http://www.w3.org/XML/

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

Helium is fundamentally based on Apache Ant_. Why was Ant_ chosen when there were many other similar frameworks inside Nokia,
such as sbt, isis_build and TrombiBuild. The main reason is that while the other toolkits were developed inside Nokia,
Ant_ is an open source tool from Apache, based on relatively simple XML_ files that define the build steps. 
Through leveraging the power of open source Helium has integrated a large amount of functionality that would have taken
much longer to develop in-house, as well as benefit from existing, high-quality documentation.

