<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:template match="/BuildProcessDefinition/remoteBuilds">
        <project>
            <target>
                <xsl:attribute name="name">do-distribute-work-area</xsl:attribute>
                <parallel>
                    <xsl:apply-templates select="build" mode="workarea"/>
                </parallel>
            </target>
            <target>
                <xsl:attribute name="name">do-start-remote-builds</xsl:attribute>
                <parallel>
                    <daemons>
                        <xsl:apply-templates select="build" mode="remotebuilds"/>
                    </daemons>
                </parallel>
            </target>
        </project>
    </xsl:template>
    <xsl:template match="build" mode="workarea">
        <remoteant>
            <xsl:attribute name="machine"><xsl:value-of select="@machine"/></xsl:attribute>
            <runtarget>
                <xsl:attribute name="target">untar-work-area</xsl:attribute>
                <property>
                    <xsl:attribute name="name">ccm.home.dir</xsl:attribute>
                    <xsl:attribute name="value"><xsl:value-of select="@ccmhomedir"/></xsl:attribute>
                </property>
                <property>
                    <xsl:attribute name="name">ccm.base.dir</xsl:attribute>
                    <xsl:attribute name="value"><xsl:value-of select="@basedir"/></xsl:attribute>
                </property>
                <property>
                    <xsl:attribute name="name">work.area.cache.file</xsl:attribute>
                    <xsl:attribute name="value">${work.area.cache.file}</xsl:attribute>
                </property>
            </runtarget>
        </remoteant>
    </xsl:template>
    <xsl:template match="build" mode="remotebuilds">
        <remoteant>
            <xsl:attribute name="machine"><xsl:value-of select="@machine"/></xsl:attribute>
            <runtarget>
                <xsl:attribute name="target">run-build</xsl:attribute>
                <property>
                    <xsl:attribute name="name">bld-bat-file</xsl:attribute>
                    <xsl:attribute name="value"><xsl:value-of select="@executable"/></xsl:attribute>
                </property>
                <property>
                    <xsl:attribute name="name">bld-bat-dir</xsl:attribute>
                    <xsl:attribute name="value"><xsl:value-of select="@dir"/></xsl:attribute>
                </property>
                <property>
                    <xsl:attribute name="name">args</xsl:attribute>
                    <xsl:attribute name="value"><xsl:value-of select="@args"/></xsl:attribute>
                </property>
            </runtarget>
        </remoteant>
    </xsl:template>
</xsl:stylesheet>
