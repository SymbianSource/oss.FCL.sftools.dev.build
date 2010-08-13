<?xml version="1.0"?>
 <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!--Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
	All rights reserved.
	This component and the accompanying materials are made available
	under the terms of the License "Eclipse Public License v1.0"
	which accompanies this distribution, and is available
	at the URL "http://www.eclipse.org/legal/epl-v10.html".

	Initial Contributors:
	Nokia Corporation - initial contribution.
	Contributors:
	Description:
	Create a stand-alone sysdef from a linked set of fragments
-->
 	<xsl:output method="xml" indent="yes"/>
<!--Description:This creates a stand-alone sysdef from a linked set of fragments.
All API metadata will be removed
-->
<!--Input:<sysdef> - (required) The 3.0 formatsystem definition XML file to
		process. This can be a fragment or stand-alone. 
		If there are no linked fragments, this will just convert all
		relative unit paths into absolute paths and embed any linked
		metadata-->

<xsl:param name="path">/os/deviceplatformrelease/foundation_system/system_model/system_definition.xml</xsl:param>
<!-- <path> - The full system model path for this file. Use forward slashes.-->

<xsl:template match="/*">
	<xsl:apply-templates select="." mode="join"/>
</xsl:template>


<xsl:template match="/SystemDefinition[systemModel]">
<xsl:apply-templates select="." mode="join">
	<xsl:with-param name="filename" select="$path"/>
</xsl:apply-templates>
</xsl:template>


<xsl:template match="meta[@rel='Api']" priority="2" mode="meta"/> <!-- ignore these, not needed in system build -->


<xsl:include href="lib/joinsysdef-module.xsl"/>

</xsl:stylesheet>
