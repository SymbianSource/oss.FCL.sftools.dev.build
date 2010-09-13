<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:param name="usage"/>

<xsl:template match="node()|@*"><xsl:copy-of select="."/></xsl:template>
<xsl:template match="/*">
	<xsl:apply-templates select="." mode="desc"/>

	<xsl:variable name="in">
		<xsl:call-template name="input"/>
	</xsl:variable>
	<xsl:variable name="out">
		<xsl:call-template name="output"/>
	</xsl:variable>

	<xsl:if test="$usage != ''">
		<xsl:text>&#xa;usage: </xsl:text><xsl:value-of select="$usage"/>
	</xsl:if>
	<xsl:if test="$usage != '' and contains($out,'&gt;')"> [<xsl:value-of select="substring-before($out,'&gt;')"/>&gt;]  [params ...] <xsl:value-of select="substring-before($in,'&gt;')"/>&gt;</xsl:if>
		<xsl:choose>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xml.apache.org/xalan-c' ">
The input file must be last. Other arguments can be in any order. 
Parameters are case-sensitive. Text parameter values must be in single quotes.
</xsl:when>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xml.apache.org/xalan-j' ">
Arguments can be in any order. 
Parameters are case-sensitive.
</xsl:when>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xmlsoft.org/XSLT/' ">
The input file must be last. Other arguments can be in any order. 
Parameters are case-sensitive.
</xsl:when>
		</xsl:choose>

	<xsl:text>&#xa;&#9;</xsl:text>
		<xsl:call-template name="input"/>
	<xsl:text>&#xa;&#9;</xsl:text>
		<xsl:call-template name="output"/>
	<xsl:apply-templates select="." mode="params"/>
</xsl:template>


<xsl:template match="/*" mode="desc">
	<xsl:value-of select="substring-after(comment()[starts-with(.,'Description:')],':')"/>
	<xsl:apply-templates select="document(xsl:import/@href | xsl:include/@href,.)/*" mode="desc"/>
</xsl:template>

<xsl:template match="/*" mode="params">
	<xsl:for-each select="xsl:param">
		<xsl:text>&#xa;&#9;</xsl:text>
		<xsl:choose>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xml.apache.org/xalan-c' ">
				<xsl:text>-p </xsl:text>			
			</xsl:when>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xml.apache.org/xalan-j' ">
				<xsl:text>-param </xsl:text>			
			</xsl:when>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xmlsoft.org/XSLT/' ">
				<xsl:text>--string-param </xsl:text>			
			</xsl:when>
		</xsl:choose>
		<xsl:value-of select="concat(@name,' ')"/>
		<xsl:for-each select="following-sibling::node()[self::* or self::comment()][1]">
			<xsl:if test="self::comment()">
			<xsl:value-of select="."/>
			</xsl:if>
		</xsl:for-each>
		<xsl:text>&#xa;</xsl:text>
		<xsl:if test="not(*) and normalize-space(.)!='' ">&#9;&#9;Defaults to <xsl:choose>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xml.apache.org/xalan-c' ">'<xsl:value-of select="."/>'</xsl:when>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xml.apache.org/xalan-j' ">"<xsl:value-of select="."/>"</xsl:when>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xmlsoft.org/XSLT/' ">"<xsl:value-of select="."/>"</xsl:when>
		</xsl:choose></xsl:if>
	</xsl:for-each>
	<xsl:apply-templates select="document(xsl:import/@href | xsl:include/@href,.)/*" mode="params"/>
</xsl:template>


<xsl:template name="string"><xsl:param name="look">Description</xsl:param>
	<xsl:variable name="s">
		<xsl:value-of select="substring-after(comment()[starts-with(.,concat($look,':'))],':')"/>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$s != ''"><xsl:value-of select="$s"/></xsl:when>
		<xsl:otherwise>
			<xsl:for-each select="document(xsl:import/@href | xsl:include/@href,.)/*">
				<xsl:call-template name="string">
					<xsl:with-param name="look" select="$look"/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="input">
	<xsl:variable name="p">
		<xsl:call-template name="string">
			<xsl:with-param name="look" select="'Input'"/>
		</xsl:call-template>
	</xsl:variable>
		<xsl:choose>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xml.apache.org/xalan-c' "/>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xmlsoft.org/XSLT/' "/>
			<xsl:when test="system-property('xsl:vendor-url') = 'http://xml.apache.org/xalan-j' ">
				<xsl:text>-in </xsl:text>			
			</xsl:when>
		</xsl:choose>
	<xsl:if test="$p =''  ">&lt;xml&gt; - (required) The input XML file</xsl:if>
	<xsl:if test="$p !=''  "><xsl:value-of select="$p"/></xsl:if>
	<xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template name="output">
	<xsl:variable name="p">
		<xsl:call-template name="string">
			<xsl:with-param name="look" select="'Output'"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="system-property('xsl:vendor-url') = 'http://xml.apache.org/xalan-c' ">
			<xsl:text>-o </xsl:text>			
		</xsl:when>
		<xsl:when test="system-property('xsl:vendor-url') = 'http://xml.apache.org/xalan-j' ">
			<xsl:text>-out </xsl:text>			
		</xsl:when>
		<xsl:when test="system-property('xsl:vendor-url') = 'http://xmlsoft.org/XSLT/' ">
			<xsl:text>-o </xsl:text>			
		</xsl:when>
	</xsl:choose>
	<xsl:if test="$p =''  ">&lt;file&gt; - (optional) The <xsl:value-of select="xsl:output/@method"/> file to save the output as. If not present it will write to stdout.</xsl:if>
	<xsl:if test="$p !=''  "><xsl:value-of select="$p"/></xsl:if>
	<xsl:text>&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
