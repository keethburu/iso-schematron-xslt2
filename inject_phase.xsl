<xsl:stylesheet xmlns:dg="http://www.degruyter.com/namespace" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:letex="http://www.le-tex.de/namespace" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dgs="http://www.degruyter.com/namespace/schematron-annotation" xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs xd sch" version="2.0">
    <xsl:output indent="yes"/>
    <xsl:param name="phase2inject" as="xs:string" select="'foo'"/>
    <xsl:template match="sch:schema">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <dgs:phases/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="sch:phase"/>
    <xsl:template match="dgs:phases">
        <sch:phase id="phase_{$phase2inject}">
            <sch:active pattern="{$phase2inject}"/>
        </sch:phase>
    </xsl:template>
</xsl:stylesheet>