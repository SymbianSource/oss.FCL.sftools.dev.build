.. index::
  module: Configuring Diamonds

====================
Configuring Diamonds
====================

.. contents::

Introduction
------------
Diamonds is web application that can collect all build related information and categorize
builds. It can represent build information in different metrics. This document describes how
to configure diamonds in helium and minimum set of properties required.

Diamonds Server setup
---------------------
These are the minimum set of properties required in order to start the diamonds. All the properties are
defined automatically with already defined set of properties. The end user would not be required to change
any thing. As these are configured once for different vendors (symbian foundation, nokia, others.)

    <!-- Diamonds server details -->
    
    <property name="diamonds.host" value="diamonds.xxx.com"/>
    <property name="diamonds.port" value="9900"/>


Initialize diamonds
-------------------
`diamonds` target is the initialize target for diamonds logging. Call diamonds target in build target sequence
and this will log the already available data to diamonds and continue to log data onward as soon as they are available.
This is done already in helium build target sequence. So user can ignore this section. Earlier the diamonds
target needs to be called once the build area is initialized, but now this could be called even
before, as the output for diamonds files are generated in the cache location.


Disable diamonds reporting
--------------------------
Diamonds reporting can be skipped by defining the property ``diamonds.enabled`` to false.
e.g.::

    hlm -Ddiamonds.enabled=false 


Diamonds Configuration details
------------------------------
Diamonds configurations are extendable now. The default diamonds configuration is there under
${helium.dir}/config/diamonds_config_default.ant.xml. The configuration is based on ant properties
and references. So if the user wants to add process and report for new information, they can add
the details in their configurations. There are three types of information being provided using the 
configurations and are below.

Properties Required:
====================
Below are the properties requried for processing diamonds. But these are mapped to predifined properties
in helium and no action required for the user. The end user would not be required to change
any thing. As these are configured once for different vendors (symbian foundation, nokia, others.)

    <property name="diamonds.smtp.server" value="${email.smtp.server}" />
    <property name="diamonds.ldap.server" value="${email.ldap.server}" />
    <property name="diamonds.initializer.targetname" value="diamonds" />
    <property name="diamonds.tstamp.format" value="yyyy-MM-dd'T'HH:mm:ss" />
    <property name="diamonds.category" value="${build.family}" />

Stage Configurations:
=====================
Stages are to record information specific to stages. Stage information is used for both logging and
diamonds reporting. The build process needs to define stages clearly and map it with the configurations
as below.

.. code-block:: xml

      <hlm:stage id="get-baseline" startTarget="check-free-space" endTarget="enable-abiv2" />
      <hlm:stage id="get-source" startTarget="do-prep-work-area" endTarget="create-bom" />
      <hlm:stage id="clean-and-prep" startTarget="ido-prep-clean-dfs" endTarget="ido-pre-compile" />
      <hlm:stage id="build" startTarget="ido-build-parallel-dfs" endTarget="compile-ctc" />
      <hlm:stage id="rombuild" startTarget="image-creation" endTarget="image-creation" />
      <hlm:stage id="create-ATS-drop" startTarget="ats-test" endTarget="ats-aste" />        
      <hlm:stage id="post-build" startTarget="image-creation" endTarget="archive" />

The stage configuration provides the information about the stage starting and ending target sequence.
There should be a corresponding stagerecord for each stage, which is to store the log information
for that specific stages, please refer to logging module for more information.

Both the stages / target reporting using messaging type to provide details to be sent to diamonds
reporting. See details in messaging sections for further details.

Currently the diamonds reporting just records the start / end time using the following configuration.

.. code-block:: xml

    <hlm:fmppMessage id="stage.time.message" sourceFile="${diamonds.template-dir}/diamonds_stage.xml.ftl">
        <data expandProperties="yes">
            ant: antProperties()
        </data>
    </hlm:fmppMessage>

The config takes a template to be used to convert, the template is converted using fmpp and all 
the output files are processed and sent to diamonds. All the input to fmpp task could be used here.
The template diamonds_stage.xml.ftl just reports the start / end time. In addition to duration, if 
the user wants to send more information for the stages it could be done by overriding the 
configuration as below and controlling using the user defined template.

.. code-block:: xml

    <hlm:fmppMessage id="stage.time.message" ${diamonds.custom.template.dir}/diamonds_stage_custom.xml.ftl>
        <data expandProperties="yes">
            ant: antProperties()
        </data>
    </hlm:fmppMessage>


Reporting based on target execution:
====================================
If some data needs to be sent at the end of target execution, this can be defined with below configuration.

    <hlm:targetMessage id="diamonds.id" target="diamonds">
        <hlm:fmppMessage sourceFile="${helium.dir}/tools/common/templates/diamonds/tool.xml.ftl" >
            <data expandProperties="yes">
                ant: antProperties()
            </data>
        </hlm:fmppMessage>
    </hlm:targetMessage>