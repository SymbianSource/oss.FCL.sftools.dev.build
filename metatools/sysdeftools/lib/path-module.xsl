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
	XSLT module which contains named templates which process file paths
-->

 <xsl:template name="lastbefore"><xsl:param name="string"/><xsl:param name="substr" select="'/'"/>
        <xsl:if test="contains($string,$substr)">
                <xsl:value-of select="substring-before($string,$substr)"/>
                <xsl:if test="contains(substring-after($string,$substr),$substr)">
	                <xsl:value-of select="$substr"/>
	              </xsl:if>
        <xsl:call-template name="lastbefore">
                <xsl:with-param name="string" select="substring-after($string,$substr)"/>
                <xsl:with-param name="substr" select="$substr"/>
        </xsl:call-template>
        </xsl:if>
</xsl:template>

 <xsl:template name="joinpath"><xsl:param name="file"/><xsl:param name="rel"/>
	<xsl:choose>
		<xsl:when test="(contains($rel,'://') and not(contains(substring-before($rel,'://'),'/'))) or starts-with($rel,'/')"> <!-- absolute URI or absolute path-->
			<xsl:value-of select="$rel"/>
		</xsl:when>
		<xsl:otherwise> <!-- relative link -->
			<xsl:call-template name="reducepath">
				<xsl:with-param name="file">
					<xsl:call-template name="lastbefore">
						<xsl:with-param name="string" select="$file"/>
					</xsl:call-template>
					<xsl:text>/</xsl:text>
					<xsl:value-of select="$rel"/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:otherwise>
	</xsl:choose>
 </xsl:template>

<xsl:template name="reducepath"><xsl:param name="file"/>
	<xsl:call-template name="reducedotdotpath">
    	<xsl:with-param name="file">
			<xsl:call-template name="reducedotpath">
		    	<xsl:with-param name="file" select="$file"/>
		    </xsl:call-template>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>

<xsl:template name="reducedotdotpath"><xsl:param name="file"/>
	<xsl:variable name="pre">
		<xsl:call-template name="lastbefore">
			    <xsl:with-param name="string" select="substring-before($file,'/../')"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="starts-with($file,'../')">
			<xsl:text>../</xsl:text>
			<xsl:call-template name="reducedotdotpath">
        		<xsl:with-param name="file" select="substring($file,4)"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="contains($file,'/../') and $pre='' and not(starts-with($file,'/'))"> <!-- if file is a relative path and the dotdots go up to the top dir, don't start with a slash -->
			<xsl:call-template name="reducepath">
        		<xsl:with-param name="file" select="substring-after($file,'/../')"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="contains($file,'/../')">
			<xsl:call-template name="reducepath">
        		<xsl:with-param name="file" select="concat($pre,'/',substring-after($file,'/../'))"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$file"/></xsl:otherwise>
	</xsl:choose>
 </xsl:template>

<xsl:template name="reducedotpath"><xsl:param name="file"/>
	<xsl:choose>	
		<xsl:when test="starts-with($file,'./')">
			<xsl:call-template name="reducedotpath">
        		<xsl:with-param name="file" select="substring($file,3)"/>
			</xsl:call-template>
		</xsl:when>

		<xsl:when test="contains($file,'/./')">
			<xsl:call-template name="reducepath">
        		<xsl:with-param name="file">
	                <xsl:value-of select="substring-before($file,'/./')"/>
			        <xsl:text>/</xsl:text>
					<xsl:value-of select="substring-after($file,'/./')"/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="substring($file,string-length($file) - 1) = '/.'">
           <xsl:value-of select="substring($file,1,string-length($file) - 2)"/>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$file"/></xsl:otherwise>
	</xsl:choose>
 </xsl:template>

</xsl:stylesheet>
