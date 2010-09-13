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
	Create a stand-alone sysdef from a linked set of fragments, paring down to just a set of items of the desired rank.
-->
 	<xsl:output method="xml" indent="yes"/>

<!--Description:This pares the generated sysdef down to just a set of items of the desired
rank. In other words, you provide a list of IDs to keep and a system model
rank (layer, package, collection, component). 
Every item of that rank in the sysdef will be removed except those in the list
of IDs.
Primary use cases of this would be to extract a single layer, or to select a
specific set of packages.

-->
<xsl:param name="pare"/>		
	<!--<list> - (required) A comma-separated list of IDs in the literal from as the document they appear in (ie same namespace prefix) -->

<xsl:param name="rank">package</xsl:param>
	<!--<rank> = the rank item to pare down. This will remove any item of that rank EXCEPT those in $pare -->

<xsl:variable name="pare-list" select="concat(',',translate(normalize-space($pare),' ',','),',')"/> <!-- accept spaces in pare. Pad with commas to make computing easier -->

<xsl:include href="joinsysdef.xsl"/>  

<xsl:template match="/SystemDefinition[systemModel]">
	<xsl:apply-templates select="." mode="join">
		<xsl:with-param name="filename" select="$path"/>
		<xsl:with-param name="data" select="current()"/> <!-- just has to be non-empty -->
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="*" mode="filter"> <!-- use this to strip out the unwanted items -->
	<xsl:param name="item" />
	<xsl:if test="$rank=name($item) and not(contains($pare-list,concat(',',$item/@id,',')))">hide</xsl:if>
</xsl:template>

</xsl:stylesheet>
