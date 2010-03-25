==========================================
Configuring Signaling: Create a new signal
==========================================

This document will help you implementing a new signal in your configuration.  

Use case
--------
You have one target named **custom-action** which
should generate an artifact in some know location, and you would like the build to continue as far 
as possible even if that artifact is missing, but being informed during the build it is not going as expected. 


Base configuration
------------------

The following code snippet will be the base configuration for this exercise.   

build.xml

.. code-block:: xml

   <?xml version="1.0" ?>
   <project name="config" default="test" xmlns:hlm="http://www.nokia.com/helium"> 
      <property environment="env"/>
      <import file="${helium.dir}/helium_preinclude.ant.xml"/>

      <!-- Location of the artifact -->    
      <property name="artifact" location="artifact.txt"/>
            
      <import file="${helium.dir}/helium.ant.xml"/>

      <!-- The target -->
      <target name="custom-action">
         <delete failonerror="false" file="${artifact}"/>
         <if>
            <istrue value="${create.artifact}"/>
            <then>
               <echo file="${artifact}">My artifact</echo>
            </then>
         </if>
      </target>
      
      <target name="custom-dummy">
        <echo message="Dummy action"/>
      </target>
   
   </project>   



To declare a new signal to the framework you need to define a new signalListenerConfig reference.
You also need to create a signalInput configuration to define your signal behaviour.

.. code-block:: xml
 
   <hlm:signalInput id="customActionSignalInput" failbuild="defer"/>
   
   <hlm:signalListenerConfig id="customActionSignal" target="custom-action" message="custom-action target ended.">
      <signalNotifierInput>
          <signalInput refid="customActionSignalInput" />
          <notifierInput file="${artifact}" />
      </signalNotifierInput>
      <hlm:targetCondition>
         <not><available file="${artifact}"/></not>            
      </hlm:targetCondition>
   </hlm:signalListenerConfig>


The signalListenerConfig defines which target to listen and raise signal for. The target name is defined through the **target** attribute.
Then the nested **targetCondition** element is used to configure how the signal should be triggered.
This element accepts any nested `Ant conditions <http://ant.apache.org/manual/CoreTasks/conditions.html>`_.
In this case the signal will get raised only if the file is not present after the execution of the **custom-action** target.

The framework then uses the defined signalInput from the signalNotifierInput configuration to know how to behave when the signal is raised. In the previous example it will
simply keep running and fail the build at the end. Then files defined by the nested notifierInput will be passed to the notifier.

The execution of the **custom-action custom-dummy** build sequence will happen entirely even if the artifact is not 
created properly, then fail the build mentioning the faulty target::

   > hlm custom-action custom-dummy
   Internal data listening enabled.
   Buildfile: build.xml
        [echo]  Using build drive X:
   
   custom-action:
   18:21:14,503  INFO - Signal customActionSignal will be deferred.
   
   custom-dummy:
        [echo] Dummy action
   
   BUILD FAILED
   customActionSignal: custom-action target ended. : custom-action
   
   
   Total time: 2 seconds


If you enable the artifact creation then the build will proceed successfully::

   >hlm custom-action custom-dummy -Dcreate.artifact=true
   Internal data listening enabled.
   Buildfile: build.xml
        [echo]  Using build drive X:
   
   custom-action:
   
   custom-dummy:
        [echo] Dummy action
   
   BUILD SUCCESSFUL
   Total time: 2 seconds

   
