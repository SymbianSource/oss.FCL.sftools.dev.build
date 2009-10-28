<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!-- 
============================================================================ 
Name        : helium_data_model.xml 
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
<!--

This describes the allowed values for some of the fields:

property:
- editStatus: [must, recommended, allowed, discouraged, never] 
  type: [string, boolean, integer]

-->
<xsl:output method="xml" indent="yes"/>

<xsl:template match="/">
    <heliumDataModel xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="..\tools\common\schema\helium_data_model.xsd">
        <xsl:copy-of select="//property"/>
        <xsl:copy-of select="//group"/>
    </heliumDataModel>
</xsl:template>
</xsl:stylesheet> 