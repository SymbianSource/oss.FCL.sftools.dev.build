<xsl:stylesheet  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
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
	Validate a system definition file/files and output results as plain text
-->
	<xsl:output method="text"/>
	<xsl:include href="lib/test-model.xsl"/>
	<xsl:param name="level" select="3"/>  <!--<1/2/3> - (optional) The detail of the error messages. 1  = Errors only. 2 = Errors and Warnings. 3 = Notes as well (the default) -->
	<xsl:param name="path-errors" select="0"/> <!--1 - (optional) If present, it will check to see if unit paths follow the coding standards-->


<!--Description:Validates a system definition file or files and outputs the result as plain text
-->
<!--Input:<sysdef> - (required) The system definition XML or Model XML file to process. Sysdefs must be in the 3.0 format, and can be a fragment or stand-alone.-->
<!--Output:<log> - (optional) The file to write the error log to. If not present it will write to stdout.-->


<xsl:template name="Section"><xsl:param name="text"/><xsl:param name="sub"/>
<xsl:text>&#xa;&#xa;</xsl:text>
<xsl:value-of select="$text"/>
<xsl:if test="$sub!=''"> (<xsl:value-of select="$sub"/>)</xsl:if>
</xsl:template>


<xsl:template name="Note"><xsl:param name="text"/><xsl:param name="sub"/>
<xsl:if test="$level &gt;= 3">
<xsl:text>&#xa;Note: </xsl:text>
<xsl:value-of select="$text"/>
<xsl:if test="$sub!=''"> (<xsl:value-of select="$sub"/>)</xsl:if>
</xsl:if>
</xsl:template>

<xsl:template name="Warning"><xsl:param name="text"/><xsl:param name="sub"/>
<xsl:if test="$level &gt;= 2">
<xsl:text>&#xa;Warning: </xsl:text>
<xsl:value-of select="$text"/>
<xsl:if test="$sub!=''"> (<xsl:value-of select="$sub"/>)</xsl:if>
</xsl:if>
</xsl:template>

<xsl:template name="Error"><xsl:param name="text"/><xsl:param name="sub"/>
<xsl:text>&#xa;Error: </xsl:text>
<xsl:value-of select="$text"/>
<xsl:if test="$sub!=''"> (<xsl:value-of select="$sub"/>)</xsl:if>
</xsl:template>

</xsl:stylesheet>