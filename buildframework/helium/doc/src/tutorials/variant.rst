.. index::
  module: Variant creation tutorial

################################
Legacy Variant creation tutorial
################################

This section describes the configuration required to create a variants and UDA, this should be read along with the :ref:`localisation-label`:
sections else where.

Variant Creation
-----------------

This section aims to describe the creation of Customer Variants using Helium.  


The variant team should configure their variant using the following template:
 
   variation (configurable location)
      operator_xx_51
         data
            ibys
            cenreps
            rscs
         variation
            rss rebuilt using binary variation (like spp psw folder)
         config
            hlm.bat
            build.xml (mini-configuration referencing product release one)
            customer_rom_config.xml (external configuration to define the variant image)



Keep in mind that with MultiROFS nothing will get exported by image creation, ibys and content will be directly
referenced from the variant location: data directory and variant root will be added to the ROM creation include path.
           

You can configure your variant build environment with the following template files:


* build.xml:

.. code-block:: xml

   <?xml version="1.0" encoding="utf-8" ?> 
   <project name="customer_variants" basedir="/mc/mc_build/mc_5132_build/all">
       <dirname property="customer_variants.basedir" file="${ant.file.customer_variants}" />
       <!-- Product you are generating the variant for -->
       <property name="product.list" value="PRODUCT" /> 
       <!-- Specifying the variant config that should be used. -->
       <property name="PRODUCT.customer.roms.config" location="${customer_variants.basedir}/customer_rom_config.xml" />
       <!-- Specifying our rom image creation group: should be always the same -->
       <property name="customer.makefile.target" value="vt_customer_variants" /> 
       <!-- Referencing the build configuration -->
       <import file="/mc/mc_build/mc_5132_build/all/build.xml" /> 
   </project>
 
 
* customer_rom_config.xml:

.. code-block:: xml

   <?xml version="1.0" encoding="UTF-8" ?> 
   <config name="vt_customer_variants" abstract="true">
      <set name="customer.type" value="operatorcountry" /> 
      <set name="variation.dir" value="\variation" /> 
      <set name="image.type" value="prd" /> 
   
      <!--  Your variant config --> 
      <config type="customer">
         <set name="customer.id" value="151" /> 
         <set name="customer.revision" value="2" /> 
         <set name="description" value="" /> 
         <set name="compatible.languagepack" value="03" /> 
      </config>
   </config>
   

What is happening when generating the Customer Variant?
The customer file will be included by the platform configuration and be included by the XInclude mechanism.
This currently means that the platform has to explicitly add the include information. But we will try to remove that dependence in the future.

UDA creation 
-------------

The main concept of this section is to explain how the Variant Team should use Helium to handle UDA creation.
First of all the UDA environment is split in 2 different parts: the content and the config::

   + uda_delivery      
      + uda_content
         + common
            - content.zip
         + application1
            - file1.zip
            - file2.zip
         + application2
            - file.zip

      + config
         - hlm.bat
         - build.xml
         - uda_rom_config.xml (standalone configuration)

     
* The content must contain subdirectories that represents different kind of features which store them as zip files. 
  All the zip files under that folder will be unzipped when generating the UDA.
* The configuration is a standalone Helium configuration that would be used to configure the UDA creation.


Example of configuration:

* build.xml

.. code-block:: xml

  <?xml version="1.0" encoding="UTF-8" ?> 
    <project basedir=".">
    <property environment="env" /> 
    <property name="product.list" value="PRODUCT" /> 
    <property name="build.drive" value="Z:" /> 
    <property name="rombuild.config.file" location="uda_rom_config.xml" /> 
    <property name="product.name" value="PRODUCT" /> 
    <property name="major.version" value="0" /> 
    <property name="minor.version" value="0" /> 
    <import file="${helium.dir}/helium.ant.xml" /> 
  </project>
  
* uda_rom_config.xml

.. code-block:: xml
 
   <?xml version="1.0" encoding="UTF-8" ?> 
   <build xmlns:xi="http://www.w3.org/2001/XInclude">
   <config name="PRODUCT" abstract="true">
      <set name="ui.platform" value="mc5132" /> 
      <set name="version.product.name" value="N00" /> 
      <set name="rom.output.dir" value="${build.output.dir}" /> 
      <set name="uda.output.dir" value="${rom.output.dir}${uda.image.path}" /> 
      
      <!--  Template relative paths  --> 
      <set name="uda.image.path" value="release_flash_images/${image.type}/user_data/${image.type}/${uda.id}_${description}" /> 

      <!--  Template names  --> 
      <set name="uda.image.name" value="${rombuild.id}_${uda.id}.${uda.revision}_${image.type}" /> 

      <!--  Template publish paths (used for flash config files generation) --> 
      <set name="uda.publish.dir" value="${rom.publish.dir}${uda.image.path}" /> 
      <set name="uda.template" value="${version.product.name} (${uda.id})" /> 
      
      <!--  Do not build target in parallel by default --> 
      <set name="build.parallel" value="false" /> 
      <set name="image.type" value="prd" /> 
      <!--  Driving iMaker configuration generation --> 
      <set name="output.makefile.filename" value="${rombuild.makefile.name}" /> 
      <set name="main.makefile.template" value="${helium.dir}\tools\rombuild\generic_templates\main.mk" /> 
      <set name="uda.makefile.template" value="${helium.dir}\tools\rombuild\generic_templates\vt_uda.mk" /> 
      <set name="winimage.tool" value="${build.drive}/winimage.exe" /> 
      <set name="uda.content.dir" value="/uda_PRODUCT/content" /> 
      
      <!-- Group of UDA to be built -->
      <config name="uda_roms" abstract="true">
      
         <!-- Defining a UDA -->
         <config type="uda">
            <set name="uda.id" value="111" /> 
            <set name="uda.revision" value="0" /> 
            <set name="uda.content" value="common,snakes" /> 
         </config>


      </config>
   </config>
   </build>
   
.. csv-table:: Property descriptions
   :header: "Property", "Description"

   "``uda.id``", "Defines the uda identification number"
   "``uda.revision``", "Defines the revision number for the version string"
   "``uda.content``", "Comma separated list that defines the UDA content"
   "``uda.content.dir``", "Location of the content subdirectories"
   "``uda.template``", "Template that defines the how to generate the version string"
   "``uda.image.path``", "Template that defines where to generated the UDA"
   "``uda.image.name``", "Template that defines how to name the UDA"
 
