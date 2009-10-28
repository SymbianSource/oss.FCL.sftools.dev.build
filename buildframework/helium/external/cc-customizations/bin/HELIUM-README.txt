Cruise control Helium Integration
=================================

Cruise Control version: 2.8.2    		
HCC version: 1

Helium additions
----------------
cruisecontrol-bin-2.8.2\HELIUM-README.txt
cruisecontrol-bin-2.8.2\cruisecontrol.bat
cruisecontrol-bin-2.8.2\distribution.policy.S60
cruisecontrol-bin-2.8.2\etc\distribution.policy.S60
cruisecontrol-bin-2.8.2\etc\jetty.xml
cruisecontrol-bin-2.8.2\helium-dashboard-config.xml
cruisecontrol-bin-2.8.2\lib\distribution.policy.S60
cruisecontrol-bin-2.8.2\lib\nokia_helium_cc.jar


    		
How to use CC Helium customizations
-----------------------------------

In config.xml:
----8<----8<----8<----8<----8<----8<----8<----
<cruisecontrol>
	<!-- Helium customization. -->
	<plugin name="xmlmodificationset" classname="com.nokia.cruisecontrol.sourcecontrol.XMLModificationSet"/>
	<plugin name="hlmmodificationset" classname="com.nokia.cruisecontrol.sourcecontrol.HLMSynergy"/>
	...
----8<----8<----8<----8<----8<----8<----8<----

How to use Dashboard Helium customizations
------------------------------------------

To enable the Helium build summary widget please use the Helium specific
dashboard configuration file:
set CCDIR=<PATH_TO_CC_HOME>
<HELIUM_CCC_DIR>\cruisecontrol.bat
    		
How to configure the Ant builder
--------------------------------

To prevent log.xml missing exception while running Helium please configure the ant builder this way:
<ant .... uselogger="false" showProgress="false"... >
   <!-- Configure the XMLLogger -->
   <listener classname="org.apache.tools.ant.XmlLogger"/>
   <property name="XmlLogger.file" value="${configuration.dir}/log.xml" />
</ant>

_______________
The Helium Team
