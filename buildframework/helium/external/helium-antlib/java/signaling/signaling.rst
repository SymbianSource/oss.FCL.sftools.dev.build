=====================
Configuring Signaling
=====================

Helium signaling framework offers you a simplest way to control 
failures on build flow, and provides you an easy way to get reporting on
some crucial steps of your build.


The configuration
-----------------

The signaling configuration is divided on three parts:

   * the signalListenerConfig: defines the signal
   * the signalInput: defines what to do when a signal is raised
   * the notifierList: defines a set of notifiers

signalListenerConfig
....................

This part of the configuration is not targeted to be overridden by the build manager.

The following example defines a custom signal named as **customSignal**.
The default configuration must reference a default signalInput configuration using a nested inputRef element,
so the signaling framework knows how to behave when a signal is raised.

.. code-block:: xml

    <hlm:signalListenerConfig id="customSignal" target="target-name" message="target-name triggered a signal">
        <signalNotifierInput>
            <signalInput refid="signalInputId" />
            <notifierInput file="some/file/to/notify.html" />
        </signalNotifierInput>
        <hlm:targetCondition>
            </available file="some-file.txt" />
        </hlm:targetCondition>
    </hlm:signalListenerConfig>
 
A signal will then be triggered each time the **target-name** completed. The signalInput will then defined how it should be handled.

Other way to trigger a signal is by using the signal task:
 
.. code-block:: xml

    <hlm:signal name="customSignal" result="1">
        <signalNotifierInput>
            <signalInput refid="signalInputId" />
            <notifierInput file="some/file/to/notify.html" />
        </signalNotifierInput>
    </hlm:signal>
    

signalInput
...........

This Ant type defines what a signal should do when it is raised. The failbuild attribute defines
if a build failure should be:

    * failing the build now (value: now)
    * deferred at the end of the build (value: defer)
    * ignored (value: never)
   
Then the configuration will accept a reference to a notifierList using the notifierListRef element.

Example of configurations

.. code-block:: xml

    <hlm:signalInput id="customSignalInput" failbuild="now">
        <hlm:notifierListRef refid="customNotifier" />
    </hlm:signalInput>
  
This will run all notifier from the customNotifier configuration then fail the build.

.. code-block:: xml

    <hlm:signalInput id="customSignalInput" failbuild="defer"/>

This will defer the failure at the end of the build, no notifier will be run.

notifierList
............

The notifierList Ant type allows the user to configure a set of Notifier (e.g Email, execute task):

The following example configures a notifier list that will send an email and run few echo task to print
some information.

.. code-block:: xml

    <hlm:notifierList id="customNotifier">
        <hlm:emailNotifier templateSrc="${helium.dir}/tools/common/templates/log/email_new.html.ftl"
                           title="[signal] ${signal.name}" smtp="smtp.server.address"
                           ldap="ldap://ldap.server.address:389"
                           notifyWhen="always"/>
        <hlm:executeTaskNotifier>
            <echo>defaultSignalAlwaysNotifier: Signal: ${signal.name}</echo>
            <echo>defaultSignalAlwaysNotifier: Status: ${signal.status}</echo>
        </hlm:executeTaskNotifier>
    </hlm:notifierList>

Detailed documentation of the notifier interface could be found `here <../../helium-antlib/index.html>`_.


Example: configuring compileSignal
----------------------------------

In this example we will configure the compileSignal to behave this way:

   * send an email to additional users e.g: user@foo.com, user@bar.com
   * defer the build failure.

You configuration should contains (e.g build.xml)

.. code-block:: xml

   <?xml version="1.0"?>
   <project name="mybuild">
      ...
      <import file="${helium.dir}/helium.ant.xml"/>
      ...
      
      <hlm:notifierList id="myCustomNotifierList">
          <hlm:emailNotifier templateSrc="${helium.dir}/tools/common/templates/log/email_new.html.ftl"
                title="[signal] My build goes wrong: ${signal.name}"
                smtp="${email.smtp.server}"
                ldap="${email.ldap.server}"
                notifyWhen="fail"
                additionalrecipients="user@foo.com,user@bar.com"/>
      </hlm:notifierList>
      
      <hlm:signalInput id="compileSignalInput" failbuild="defer">
         <hlm:notifierListRef refid="myCustomNotifierList" />
      </hlm:signalInput>

   </project>

   
A custom notifierList has been created with **myCustomNotifierList** as reference ID. It defines
a emailNotifier which uses the default email template under Helium (${helium.dir}/tools/common/templates/log/email_new.html.ftl).
It also set the title of you email to be "[signal] My build goes wrong: ${signal.name}" (signal.name property will be replace by the signal name raised).
**notifyWhen** attribute will make the notifier to send a notification only on build failure.
Finally the two additional email addresses will be set using the **additionalrecipients** attribute. 

We then need to link the signal configuration and our custom the notifier list. The signalInput element is use to achieve that. 
It must be defined using the same reference ID (see reference overriding howto) as the one in the Helium configuration, the naming convention for this is: **<signal_name>Input**.
Its **failbuild** attribute is set to **defer** which will configure the build to keepgoing, and fail at the end of the build flow.
Finally an embedded notifierListRef element will reference our custom notifier list: **myCustomNotifierList**.

While failing the signaling framework will execute all notifier defined and then store internally the build failure so it can raise it again at the end of the execution.
    

Example: Report specific errors not included by default
-------------------------------------------------------

Target prep-work-area has extra log extraction added and output xml is read by a new signal.

.. code-block:: xml

   <hlm:signalInput id="prepWorkAreaSignalInputWarn" failbuild="defer">
       <hlm:notifierListRef refid="defaultSignalFailNotifier" />
   </hlm:signalInput>
   
   <hlm:signalListenerConfig id="prepWorkAreaSignalWarn" target="prep-work-area" message="Warnings happened during Preparing Work Area">
        <signalNotifierInput>
            <signalInput refid="prepWorkAreaSignalInputWarn" />
            <notifierInput file="${build.log.dir}/${build.id}_ccm_get_input.log2.xml" />
        </signalNotifierInput>
       <hlm:targetCondition> 
           <hlm:hasSeverity severity="error" file="${build.log.dir}/${build.id}_ccm_get_input.log2.xml"/>
       </hlm:targetCondition>
   </hlm:signalListenerConfig>

   <target name="prep-work-area" depends="ccmgetinput.prep-work-area">
       <hlm:logextract file="${prep.log.dir}/${build.id}_ccm_get_input.log" outputfile="${build.log.dir}/${build.id}_ccm_get_input.log2.xml">
           <recordfilterset>
               <recordfilter category="error" regexp=".*Explicitly specified but not included" />
           </recordfilterset>
       </hlm:logextract>
   </target>
