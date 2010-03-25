<#--
============================================================================ 
Name        : coverity.summary.html.ftl 
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
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
  <head>
  <meta http-equiv="Content-Type" content="text/html;charset=utf-8">
    <title>
      Coverity tool summary information.
    </title>
    <style type="text/css">
        body{font-family:Verdana; font-size:8pt; line-height:1.1em; padding: 10px 10px; background-color:#F8F8F2;}
        h1{
          font-size:14pt;
          color:#000;
          padding: 20px 15px;
          margin:0;
         }
        h2 {
          font-size:10pt;
          margin: 1em 0;
        }
        h5{
          font-size:10pt;
          text-align:center;
          background-color:#4682B4;
          color:"black";
          heigth:20pt;
          padding: 5px 15px;
          
         }
        .data{color:#00F;font-family:Verdana; font-size:10pt;color:"black";}
        span.items{text-indent:-1em; padding-left: 1em; display:block; word-wrap:normal;}

        span.bold{font-weight:bold; display:block; padding: 1em 0;}
        p.maintext{padding-top: 1em;}
        p.logfolder{color:#000;font-weight:bold; padding-top: 1em;}
        p.distrib{font-weight:bold;}
 
 
        a:link,a:visited{color:#00E;}
        
    </style>
  </head>
  <body>
        <div id="coveritysummary">
            <h5>Coverity Summary</h5>
                <#assign htmlString = covsummary?replace("["," ")>
                <#assign htmlString = htmlString?replace("]"," ")>
                <#list htmlString?split(",") as line>
                    <#if line?starts_with("   ")>
                        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;${line}<br />
                    <#elseif !line?contains("cov-analyze")>
                        ${line}<br />
                    </#if>
                </#list>
        </div>
        </br>
    </body>
</html>
