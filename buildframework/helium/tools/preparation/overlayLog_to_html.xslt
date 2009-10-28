<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:template match="/commentLog">
        <html>
            <head>
                <title>
                    <xsl:text>Overlay branch summary</xsl:text>
                </title>
            </head>
            <body>
                <h2>
                    <xsl:text>Overlay branch summary</xsl:text>
                </h2>
                <p/>
                <xsl:text>Total number of overlay branches = </xsl:text>
                <xsl:value-of select="count(branchInfo)"/>
                <p/>
                <xsl:apply-templates select="branchInfo"/>
            </body>
        </html>
    </xsl:template>
    <xsl:template match="branchInfo">
        <b>
            <xsl:text>File: </xsl:text>
        </b>
        <xsl:value-of select="@file"/>
        <br/>
        <b>
            <xsl:text>Category: </xsl:text>
        </b>
        <xsl:value-of select="@category"/>
        <br/>
        <b>
            <xsl:text>Error: </xsl:text>
        </b>
        <xsl:value-of select="@error"/>
        <br/>
        <b>
            <xsl:text>Originator: </xsl:text>
        </b>
        <xsl:value-of select="@originator"/>
        <br/>
        <xsl:value-of select="text()"/>
        <p/>
        <p/>
        <p/>
    </xsl:template>
</xsl:stylesheet>
