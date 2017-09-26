<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:atom="http://www.w3.org/2005/Atom"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

    <xsl:param name="version_index">1</xsl:param>

    <xsl:output method="text"/>

    <xsl:template match="/atom:feed">
        <xsl:apply-templates select="atom:entry[number($version_index)]"/>
    </xsl:template>

    <xsl:template match="atom:entry">
        <xsl:value-of select="atom:link/@href"/>
    </xsl:template>

</xsl:stylesheet>
