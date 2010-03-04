<?xml version="1.0"?>
 <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exslt="http://exslt.org/common"  exclude-result-prefixes="exslt">
	<xsl:output method="xml" indent="yes"/>

<!-- create a stand-alone sysdef from a linked set of fragments -->

<xsl:param name="path">/os/deviceplatformrelease/foundation_system/system_model/system_definition.xml</xsl:param>

<xsl:param name="filter-type">only</xsl:param> <!-- only, has or with -->

<xsl:param name="filter"/> <!-- comma-separated list -->


<xsl:template match="/*">
	<xsl:apply-templates select="." mode="join"/>
</xsl:template>


<xsl:template match="/SystemDefinition[systemModel]">

	<xsl:variable name="f">
		<xsl:element name="filter-{$filter-type}">
			<xsl:call-template name="filter-list">
				<xsl:with-param name="f" select="$filter"/>
			</xsl:call-template>
		</xsl:element>
	</xsl:variable>

<xsl:apply-templates select="." mode="join">
	<xsl:with-param name="filename" select="$path"/>
	<xsl:with-param name="data" select="exslt:node-set($f)/*"/>
</xsl:apply-templates>
</xsl:template>



<xsl:include href="joinsysdef-module.xsl"/>
<xsl:include href="filter-module.xsl"/>

</xsl:stylesheet>	