<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="text" encoding="iso-8859-1"/>
	<xsl:variable name="newline" select="'&#10;'" />
	<xsl:param name="separator" />

	<xsl:template match="/">
		<xsl:apply-templates select="//div[@class='real']/div[starts-with(@class, 'appInfo')]" />
	</xsl:template>

	<xsl:template match="div">
		<xsl:value-of select="normalize-space(div[2]/div[1]/a)" />
		<xsl:value-of select="$separator" />
		<xsl:value-of select="translate(normalize-space(div[1]/div[1]/span[1]),',','')" />
		<xsl:value-of select="$newline" />
	</xsl:template>

</xsl:stylesheet>
