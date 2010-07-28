<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exslt="http://exslt.org/common" exclude-result-prefixes="exslt">
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
	Merge two 3.x syntax system definitions
-->

<!--Description:This merges two 3.x syntax system definitions.
It can process two standalone sysdefs or two sysdef fragments which describe
the same system model item.
If the sysdefs are not the same schema, the output will use the highest schema
value of the two.
-->
<!--Input:<sysdef> - (required) The system definition XML file to process in the 3.0 format, and can be a fragment or stand-alone.
	If a fragment, this must be the same rank as the Downstream sysdef-->
<!--Output:<sysdef> - (optional) The system definition XML file to save the output as. If not present it will write to stdout.-->

	<xsl:output method="xml" indent="yes"/>
	<xsl:param name="Downstream">mcl/System_Definition_Template.xml</xsl:param> <!-- <sysdef> - (required) The path to the downstream systef relative to the upstream one (ie the -in sysdef). -->
	<xsl:key name="origin" match="component" use="@origin-model"/>

<xsl:variable name="downstream" select="document($Downstream,.)/SystemDefinition"/>
<xsl:param name="upname">
	<xsl:choose>
		<xsl:when test="$downstream[starts-with(@schema,'2.') or starts-with(@schema,'1.')]">
			<xsl:message terminate="yes">Syntax <xsl:value-of select="@schema"/> not supported</xsl:message>
		</xsl:when>
		<xsl:when test="name($downstream/*)!=name(/SystemDefinition/*)">
			<xsl:message terminate="yes">Can only merge fragments of the same rank</xsl:message>
		</xsl:when>
<!--		<xsl:when test="$downstream[not(systemModel)]">
			<xsl:message terminate="yes">Needs to be a standalone system definition</xsl:message>
		</xsl:when>-->
		<xsl:when test="/SystemDefinition/systemModel/@name=$downstream/systemModel/@name or not(/SystemDefinition/systemModel/@name)">
			<xsl:apply-templates mode="origin-term" select="/*">
				<xsl:with-param name="root">Upstream</xsl:with-param>
			</xsl:apply-templates>
			</xsl:when>
		<xsl:otherwise><xsl:value-of select="/SystemDefinition/systemModel/@name"/></xsl:otherwise>
	</xsl:choose>
</xsl:param>
<!-- [name] - (optional) The name used in the origin-model attribute of any component that comes from the upstream sysdef. Defaults to the name attribute on the systemModel element, or "Upstream"-->

<xsl:param name="downname">
	<xsl:choose>
		<xsl:when test="/SystemDefinition/systemModel/@name=$downstream/systemModel/@name or not($downstream/systemModel/@name)">
			<xsl:apply-templates mode="origin-term" select="$downstream">	
				<xsl:with-param name="root">Downstream</xsl:with-param>
			</xsl:apply-templates>
			</xsl:when>
		<xsl:when test="name($downstream/*)!=name(/SystemDefinition/*)">
			<xsl:message terminate="yes">Can only merge fragments of the same rank</xsl:message>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$downstream/systemModel/@name"/></xsl:otherwise>
	</xsl:choose>
</xsl:param>
<!-- [name] - (optional) The name used in the origin-model attribute of any component that comes from the downstream sysdef. Defaults to the name attribute on the systemModel element, or "Downstream"-->

<xsl:template mode="origin-term" match="*">
	<xsl:param name="root"/>
	<xsl:param name="index"/>
	<xsl:choose>
		<xsl:when test="not(key('origin',concat($root,$index)))">
			<xsl:value-of select="concat($root,$index)"/>
		</xsl:when>
		<xsl:when test="$index=''">
			<xsl:apply-templates mode="origin-term" select=".">	
				<xsl:with-param name="root" select="$root"/>
				<xsl:with-param name="index" select="1"/>
			</xsl:apply-templates>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates mode="origin-term" select=".">	
				<xsl:with-param name="root" select="$root"/>
				<xsl:with-param name="index" select="$index + 1"/>
			</xsl:apply-templates>		
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- choose the greater of the two versions -->
<xsl:template name="compare-versions"><xsl:param name="v1"/><xsl:param name="v2"/>
			<xsl:choose>
				<xsl:when test="$v1=$v2"><xsl:value-of select="$v1"/></xsl:when>
				<xsl:when test="substring-before($v1,'.') &gt; substring-before($v2,'.')"><xsl:value-of select="$v1"/></xsl:when>
				<xsl:when test="substring-before($v1,'.') &lt; substring-before($v2,'.')"><xsl:value-of select="$v2"/></xsl:when>
				<xsl:when test="substring-before(substring-after($v1,'.'),'.') &gt; substring-before(substring-after($v2,'.'),'.')"><xsl:value-of select="$v1"/></xsl:when>
				<xsl:when test="substring-before(substring-after($v1,'.'),'.') &lt; substring-before(substring-after($v2,'.'),'.')"><xsl:value-of select="$v2"/></xsl:when>
				<xsl:when test="substring-after(substring-after($v1,'.'),'.') &gt; substring-after(substring-after($v2,'.'),'.')"><xsl:value-of select="$v1"/></xsl:when>
				<xsl:when test="substring-after(substring-after($v1,'.'),'.') &lt; substring-after(substring-after($v2,'.'),'.')"><xsl:value-of select="$v2"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$v1"/></xsl:otherwise>
			</xsl:choose>
</xsl:template>

<!--  this merge only two files according to the 3.0.x rules. Old syntax not supported. Must be converetd before calling -->



<xsl:template match="/*">
	<xsl:variable name="upmodel">
		<sysdef name="{$upname}"/>
	</xsl:variable>
	<xsl:variable name="downmodel">
		<sysdef name="{$downname}" pathto="{$Downstream}"/>
	</xsl:variable>
	
	<xsl:choose>
		<xsl:when test="function-available('exslt:node-set')">
			<xsl:apply-templates mode="merge-models" select=".">
				<xsl:with-param name="other" select="$downstream"/>
				<xsl:with-param name="up" select="exslt:node-set($upmodel)/sysdef"/>
				<xsl:with-param name="down" select="exslt:node-set($downmodel)/sysdef"/>
			</xsl:apply-templates>
		</xsl:when>
		<xsl:otherwise> <!-- no node set funcion, so don't bother setting the names -->
			<xsl:apply-templates mode="merge-models" select=".">
				<xsl:with-param name="other" select="$downstream"/>
			</xsl:apply-templates> 		
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:include href="lib/path-module.xsl"/>
<xsl:include href="lib/mergesysdef-module.xsl"/>

<xsl:template match="@*[local-name()='proFile' or local-name()='qmakeArgs'  or namespace-uri()='qt']" mode="merge-copy-of">
	<!-- this fixes a xalan-j bug where it changes the namespace in the merged model to just "qt"-->
	<xsl:attribute name="{local-name()}" namespace="http://www.nokia.com/qt">
		<xsl:value-of select="."/>
	</xsl:attribute>
</xsl:template>

</xsl:stylesheet>
