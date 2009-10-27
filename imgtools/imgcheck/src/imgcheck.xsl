<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!--
 Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
 All rights reserved.
 This component and the accompanying materials are made available
 under the terms of the License "Eclipse Public License v1.0"
 which accompanies this distribution, and is available
 at the URL "http://www.eclipse.org/legal/epl-v10.html".

 Initial Contributors:
 Nokia Corporation - initial contribution.

 Contributors:

 Description: 

-->

	<xsl:template match="/">
		<HTML>
			<HEAD>
			<TITLE>Image Checker Result</TITLE>
			<h2>Image Checker Result</h2>
			</HEAD>
			<BODY>
				<xsl:apply-templates/>
			</BODY>
		</HTML>
	</xsl:template>
	<xsl:template match="comment">
	<xsl:variable name="command" select="@comment"/>
	<xsl:for-each select="Image">
		<TEXT><B>Image Name : </B></TEXT>
		<xsl:value-of select="@name"/><br></br><br></br>
		<TABLE width="800" border='1' bgcolor="AliceBlue"  align="center">
			<tr bgcolor="Green">
				<th>S.No.</th>
				<th>Executable</th>
				<th>Attribute</th>
				<th>Value</th>
				<xsl:if test="contains($command, '-n') = false">
					<th>Status</th>
				</xsl:if>
			</tr>
			<xsl:for-each select="Executable">
				<tr>
					<td><xsl:value-of select="@SNo"/></td>
					<td><A NAME="{@name}"><xsl:value-of select="@name"/></A></td>
				</tr>
				<xsl:for-each select="Dependency">
				<tr>
						<td/>
						<td/>
						<td>Dependency</td>
						<xsl:choose>
							<xsl:when test="@status = 'Available'">
								<td><A HREF="#{@name}"><xsl:value-of select="@name"/></A></td>
							</xsl:when>
							<xsl:when test="@name = 'unknown'">
								<td><A HREF="#{@name}"><xsl:value-of select="@name"/></A></td>
							</xsl:when>
							<xsl:otherwise>
								<td><xsl:value-of select="@name"/></td>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:if test="contains($command, '-n') = false">
							<xsl:choose>
								<xsl:when test="@status != 'Missing'">
									<td><font color="Green"><xsl:value-of select="@status"/></font></td>
								</xsl:when>
								<xsl:otherwise>
									<td><font color="Red"><xsl:value-of select="@status"/></font></td>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:if>
				</tr>
				</xsl:for-each>
				<xsl:for-each select="SID">
				<tr>
					<td/>
					<td/>
					<td>SID</td>
					<td><xsl:value-of select ="@val"/></td>
					<xsl:if test="contains($command, '-n') = false">
						<td>
							<xsl:if test="@status = 'Unique'">
								<font color="Green"><xsl:value-of select="@status"/></font>
							</xsl:if>
							<xsl:if test="@status = 'Duplicate'">
								<font color="Red"><xsl:value-of select="@status"/></font>
							</xsl:if>
							<xsl:if test="@status = 'Unique(alias)'">
								<font color="Green"><xsl:value-of select="@status"/></font>
							</xsl:if>
						</td>
					</xsl:if>
				</tr>
				</xsl:for-each>
				<xsl:for-each select="VID">
				<tr>
					<td/>
					<td/>
					<td>VID</td>
					<td><xsl:value-of select ="@val"/></td>
					<xsl:if test="contains($command, '-n') = false">
						<td>
							<xsl:if test="@status = 'Valid'">
								<font color="Green"><xsl:value-of select="@status"/></font>
							</xsl:if>
							<xsl:if test="@status = 'Invalid'">
								<font color="Red"><xsl:value-of select="@status"/></font>
							</xsl:if>
						</td>
					</xsl:if>
				</tr>
				</xsl:for-each>
				<xsl:for-each select="DBG">
				<tr>
					<td/>
					<td/>
					<td>Debug flag</td>
					<td><xsl:value-of select ="@name"/></td>
					<xsl:if test="contains($command, '-n') = false">
						<td>
						<xsl:if test="@status = 'Matching'">
								<font color="Green"><xsl:value-of select="@status"/></font>
							</xsl:if>
						<xsl:if test="@status = 'Not Matching'">
								<font color="Red"><xsl:value-of select="@status"/></font>
							</xsl:if>
						</td>
					</xsl:if>
				</tr>
				</xsl:for-each>
			</xsl:for-each>
		</TABLE>
		<br></br>
	</xsl:for-each>
	</xsl:template>
	<xsl:template match="Note">
		<TEXT><B>Note : </B></TEXT>
		<font color="blue"><A NAME="{@name}"><xsl:value-of select="@name"/></A><xsl:value-of select="@Note"/></font><br></br><br></br>
	</xsl:template>
</xsl:stylesheet>
