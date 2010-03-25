.. index::
  module: Coverity Prevent Tool.

========================
Coverity Prevent Tool
========================

.. contents::

This document describes requirements and how to run coverity prevent tool with sbs builds using helium. 

Introduction
-----------------
- Coverity Prevent analyzes source code to find defects early in the development cycle, reducing the risks associated with coding. Included with Prevent are workflow tools that track and manage defects from initial discovery through final resolution.
- With high precision, Coverity Prevent analyzes source code and detects critical software defects in the following categories:

    * Quality
    
        Coverity Prevent detects bugs at compile-time that can cause run-time crashes. For example: memory leaks, use-after-free errors, and illegal pointer accesses.
        
    * Security 
    
        Early during development, Coverity Prevent can detect the security vulnerabilities that hackers can exploit and help you eliminate serious problems, such as denial of service, data or memory corruption, and privilege escalation. Vulnerabilities detected can include buffer overruns, integer overflows, format string errors, and SQL injection attacks.
        
    * Concurrency 
    
        Coverity Prevent can detect errors in multi-threaded programs that, given the complexity of concurrent programming, can be extremely difficult to track down or reproduce. Detected defects include potential deadlocks or misuse of locks.
        
Implmentation
-----------------

- Coverity command can be run using the <hlm:coverity> task.
- Coverity task will validate is the command passed to task is starts with "cov-" and then it will run the command.
- Coverity command options can passed through the datatypes "<hlm:coverityoptions>" or "<hlm:arg>".
- Below example shows how parameters can be passed to coverity command.

   
.. code-block:: xml
        
        <hlm:coverity command="cov-link" dir="${build.drive}/">
            <hlm:arg name="--dir" value="${coverity.inter.dir}"/>
            <hlm:arg name="--collect" value=""/>
            <hlm:arg name="-of" value="${coverity.link.dir}/all.link"/>
        </hlm:coverity >
        
.. code-block:: xml
        
        <hlm:coverityoptions id="coverity.analyze.options">
            <hlm:arg name="--dir" value="${coverity.analyze.dir}"/>
            <hlm:arg name="--all" value=""/>
            <hlm:arg name="--symbian" value=""/>
            <hlm:arg name="--append" value=""/>
            <hlm:arg name="--enable-callgraph-metrics" value=""/>
        </hlm:coverityoptions>
        
        <hlm:coverity command="cov-analyze" dir="${build.drive}/">
            <hlm:coverityoptions refid="coverity.analyze.options"/>
        </hlm:coverity >






