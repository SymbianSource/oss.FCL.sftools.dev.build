..  ============================================================================ 
    Name        : cruisecontrol.rst
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

CruiseControl Helium Integration
================================

CruiseControl version: 2.8.2

HCC version: 1

How to use CC Helium customizations
-----------------------------------

Checks for modifications made to a Synergy repository. It does this by examining a provided reference project, getting the tasks from all folders in that project, and checking the completion time of those tasks against the last build.

In CruiseControl config.xml:

.. code-block:: xml

   <cruisecontrol>
      <!-- Helium customization. -->
      <plugin name="hlmmodificationset" classname="com.nokia.cruisecontrol.sourcecontrol.HLMSynergy"/>
      ...

How to use Dashboard Helium customizations
------------------------------------------

To enable the Helium build summary widget please use the Helium specific
dashboard configuration file:

set CCDIR=<PATH_TO_CC_HOME>

<HELIUM_CCC_DIR>\cruisecontrol.bat

How to configure the Ant builder
--------------------------------

To prevent log.xml missing exception while running Helium please configure the ant builder this way:

.. code-block:: xml

   <ant .... uselogger="false" showProgress="false"... >
      <!-- Configure the XMLLogger -->
      <listener classname="org.apache.tools.ant.XmlLogger"/>
      <property name="XmlLogger.file" value="${configuration.dir}/log.xml" />
   </ant>
