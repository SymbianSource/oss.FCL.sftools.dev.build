<#--
============================================================================ 
Name        : 
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
<!DOCTYPE HTML PUBLIC "-//w3c//dtd xhtml 1.0 strict//en"
      "http://www.w3.org/tr/xhtml1/dtd/xhtml1-strict.dtd">
<html>
<body>

<style>
div a.atext, div a.ahead {color:#000; text-decoration:  none;display:block;padding:3px 0px}
a.atext          { font-weight: bold; font-family: arial; font-size:small; color:black; text-decoration: none}
a.ahead          {text-align: right; line-height: 90%}
.table          { border-width: 0px 0px 0px 0px}
.tdbody         { padding-left: .4em; padding-right: .4em; line- height: 90%; text-align: center; vertical-align: middle height:  1.7em; }
.tdleftside     { padding-left: .25em; text-align: left; border- width: 2px 0px 2px 2px; vertical-align: middle; }
.tdrightside    { padding-left: .25em; padding-right: .25em; text- align: center; vertical-align: middle; }
.tdhead         { padding-right: .5em; border-width: 0px 0px 0px  0px; text-align: right; vertical-align: middle; }
</style>

<table class="table" border="1" width="80%" bordercolor="#c0c0c0" cellpadding="0" cellspacing="0">

<#list doc.helium.layer as layer>
    <tr>
        <td class="tdhead" colspan="2"
        onmouseover="this.bgColor='#F8D583'; style.cursor='pointer'" 
        onmouseout="this.bgColor='#FFFFFF'">${layer.name}</td>
        <td style="border-width: 0px 0px 0px 0px;" colspan="1">
            <table class="table" width="100%" bgcolor="#eeeeee" cellpadding="4px" cellspacing="1px">
            <#list layer.row as row>
                <tr>
                <#list row.component as component>
                    <td class="tdbody" bgcolor="${layer.colour}"
                      onmouseover="this.bgColor='#F8D583'; style.cursor='pointer'" 
                      onmouseout="this.bgColor='${layer.colour}'"><a href="" class="atext">${component}</a></td>
                </#list>
                </tr>
            </#list>
            </table>
        </td>
    </tr>
</#list>

</table>

</body>
</html>
