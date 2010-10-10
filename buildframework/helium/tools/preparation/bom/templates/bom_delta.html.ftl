<#--
============================================================================ 
Name        : bom_delta.html.ftl 
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
<#assign delta = doc.bomDelta>
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE HTML PUBLIC "-//w3c//dtd xhtml 1.0 strict//en"
      "http://www.w3.org/tr/xhtml1/dtd/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>BOM delta for  ${delta.buildTo}</title>
        
        <link rel ="stylesheet" type="text/css" href="stylesheet.css" title="style"/>
        <style type="text/css">
              body{font-family:Verdana; font-size:10pt; line-height:1.1em; padding: 10px 10px; background-color:#E4F0F4;}
              h1{
                font-size:14pt;
                background-color:#3366ff;
                color:#000;                
                margin:0;                
                color:#fff;
                heigth:20pt;
                padding: 5px 15px;
                text-align: center
                border-left:2px solid #5A6FA0;
                border-bottom:2px solid #5A6FA0;
                border-top:2px solid #98A6C6;
                border-right:2px solid #98A6C6;
                
                
               }
              h2{font-size:12pt;}
              h3{
                font-size:14pt;
                color:#00f;
                padding: 20px 15px;
                    margin:0;
               }
              h5{
                font-size:10pt;
                background-color:#8495BA;
                color:#fff;
                heigth:20pt;
                padding: 5px 15px;
                border-left:2px solid #5A6FA0;
                border-bottom:2px solid #5A6FA0;
                border-top:2px solid #98A6C6;
                border-right:2px solid #98A6C6;
                margin:0;
               }
       
        
              p {
                font-size:10pt;
                padding: 0em 1em 1em 1em;
                margin: 0 1em 0.5em 1em;
                border-right:1px solid #5A6FA0;
                border-top:0;
                border-bottom:1px solid #98A6C6;
                border-left:1px solid #98A6C6;
                background-color:#CDE4EB;
                white-space:normal;
              }
       
              .data{color:#00F;}
              .added{color:#24A22D;font-weight:normal; display:block; margin-bottom: 0em;padding-top: 0em;}
              .deleted{color:#F00;font-weight:normal; display:block; margin-bottom: 0em;padding-top: 0em;}
       
              span.items{text-indent:-1em; padding-left: 1em; display:block; word-wrap:normal;}
      
              span.bold{font-weight:bold; display:block; padding: 1em 0;}
              p.maintext{padding-top: 1em;}
              p.logfolder{color:#000;font-weight:bold; padding-top: 1em;}
              p.distrib{font-weight:bold;}
               
              a:link,a:visited{color:#00E;}
        </style>
    </head>
    <body>
        <h1>BOM delta for  ${delta.buildTo}</h1>
        <div id="buildname">
                <h3>Build from ${delta.buildFrom} to ${delta.buildTo} </h3>
          </div>
      
          <div id="foldername">
                   <h5>Task added </h5>
                   <p class="maintext">                   
                   <span class="data">
                   <#list delta.content.task as tasks>
                   <#if tasks.@status == "added">
                       <span class="added"> ${tasks}</span>
                   </#if>
                   </#list>
                   </span>
                   </p>
             </div>
             <div id="foldername">                   
                   <h5>Task removed</h5>
                   <p class="logfolder">
                    <#list delta.content.task as tasks>
                   <#if tasks.@status == "deleted">
                       <span class="deleted"> ${tasks}</span>
                   </#if>
                   </#list>
                   </p>
                </div>   
                <div id="foldername">
                   <h5>Baseline added</h5>
                   <p class="maintext">                   
                   <#list delta.content.baseline as baselines>
                   <#if baselines.@status == "added">
                       <span class="added">${baselines}</span>
                   </#if>
                   </#list>
                   </p>
                </div>   
                <div id="foldername">
                   <h5>Baseline removed</h5>
                   <p class="logfolder">                   
                   <#list delta.content.baseline as baselines>
                   <#if baselines.@status == "deleted">
                       <span class="deleted"> ${baselines}</span>
                   </#if>
                   </#list>                   
               </div>
        
    </body>
</html>


