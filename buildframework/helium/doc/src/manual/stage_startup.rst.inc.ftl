<#--
============================================================================ 
Name        : stage_startup.rst.inc.ftl
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
  single: Stage - startup

Stage: Startup
==============

.. index::
  single: Remote builds

Remote builds
-------------

.. index::
  single: Remote build Commands

Remote build Commands
:::::::::::::::::::::

Remote builds are used when a number of build configurations need to be run on several machines from a single work area. For a remote machine to receive the commands, a build manager must login and start the antserver process by running ``c:\apps\antserver\run_ant_server.bat``.

Two commands are supported::

  hlm distribute-work-area

Tars up the work area, copies it to a network location defined by the :hlm-p:`work.area.temp.dir` property, and sends a command to the remote servers to untar the work area. On the remote servers the basedir is deleted before the work area is untarred. ::

  hlm start-remote-builds

Sends commands to start the builds based on the remote builds configuration file entries.


.. index::
  single: Remote build configuration

Remote build configuration
::::::::::::::::::::::::::

The configuration file format defines one or more builds::

  <BuildProcessDefinition>
      <remoteBuilds>
          <build machine="vcbldsrv12" ccmhomedir="${r'$'}{ccm.home.dir}" basedir="${r'$'}{ccm.base.dir}" executable="hlm" dir="${r'$'}{_build.dir}\PRODUCT" args="product-build -Dbuild.number=${r'$'}{build.number} -Dprep.root.dir=d:\"/>
      </remoteBuilds>
  </BuildProcessDefinition>

Each ``<build>`` element has a number of attributes:

machine
  The name of the remote build machine. The commands will only work if an Ant server instance is running, so be careful not to run the server on the local machine!

ccmhomedir
  This should match to the :hlm-p:`ccm.home.dir` property.

basedir
  This defines the directory in which the current work area (under :hlm-p:`ccm.home.dir`) is located.

executable
  The file to be executed when starting a build. Typically this can be left as ``hlm``.

dir
  The directory where the executable should be found and where the command will be run from.

args
  The arguments passed to the executable. These should consist of Ant arguments, as the build is run using Ant. Note that this attribute value is treated in the same way as the line attribute in the Ant ``exec`` task - spaces are interpreted as separating the arguments.

The :hlm-p:`remote.builds.config.file` property defines the location of the configuration file. This should be defined in a team Ant configuration file.


.. Commented out because we will not use this for our releases
   Subcon bootstrap
   ----------------
    
   The subcon edition of Helium does not include any 3rd party libraries due to licensing restrictions.
   Before you start using a copy of helium for the first time you need to call ``hlm-bootstrap.bat``.
    
   Run like this if you get timeout errors and set to the values of your proxy server::
   
     hlm-bootstrap.bat -Dproxy.host=172.16.42.137 -Dproxy.port=8080
    
   Or if you have no proxy server::
    
     hlm-bootstrap.bat -Dproxy.disabled=y
    
   The bootstrap process is:
    
    * Download Ivy jars.
    * Use Ivy to download dependencies.
    * Extract and install dependencies.