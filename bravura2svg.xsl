<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="3.1">
    
    <xsl:param name="charDeclPath" as="xs:string" select="'dist/data/charDecl.xml'"/>
    <xsl:param name="bravuraMetadataPath" as="xs:string" select="'node_modules/bravura/redist/bravura_metadata.json'"/>
    
    <xsl:output indent="yes" method="xml" encoding="UTF-8"/>
    
    <xsl:variable name="charDecl" as="document-node()?">
        <xsl:if test="doc-available($charDeclPath)">
            <xsl:sequence select="doc($charDeclPath)"/>
        </xsl:if>
    </xsl:variable>
    
    
    <xsl:variable name="bravuraMetadata" as="map(*)?" select="json-doc($bravuraMetadataPath)"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select=".//svg:glyph[starts-with(@glyph-name, 'uni')]"/>
    </xsl:template>
    
    <xsl:template match="svg:glyph">
        <!-- Extract the Unicode Codepoint from the @glyph-name attribute, e.g. "uniE050" -->
        <xsl:variable name="codePoint" select="substring-after(@glyph-name, 'uni')" as="xs:string"/>
        <!-- Lookup the glyph name by codepoint from our TEI file charDecl.xml -->
        <xsl:variable name="glyphName" select="$charDecl//tei:mapping[@type='smufl'][substring(., 3) eq $codePoint]/preceding-sibling::tei:charName => data()" as="xs:string?"/>
        <!-- Lookup the bounding box from the Bravura metadata JSON file by glyphName -->
        <xsl:variable name="glyphBBox" select="$bravuraMetadata?glyphBBoxes?($glyphName)" as="map(*)?"/>
        
        <!-- IFF the bounding box exists create a file for this glyph -->
        <xsl:if test="exists($glyphBBox)">
            <xsl:variable name="offset" select="(($glyphBBox?bBoxSW(1) * 250) => format-number('##'), ($glyphBBox?bBoxNE(2) * 250) => format-number('##'))" as="xs:string+"/>
            <xsl:result-document href="{$codePoint}.svg">
                <xsl:text>&#10;</xsl:text>
                <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd" &gt;</xsl:text>
                <xsl:text>&#10;</xsl:text>
                <xsl:element name="svg" namespace="http://www.w3.org/2000/svg">
                    <xsl:attribute name="version">1.1</xsl:attribute>
                    <xsl:attribute name="width" select="(($glyphBBox?bBoxNE(1) - $glyphBBox?bBoxSW(1)) * 250) => format-number('##.###')"/>
                    <xsl:attribute name="height" select="(($glyphBBox?bBoxNE(2) - $glyphBBox?bBoxSW(2)) * 250) => format-number('##.###')"/>
                    <xsl:comment select="$glyphName"/>
                    <xsl:element name="path" namespace="http://www.w3.org/2000/svg">
                        <xsl:copy select="@d"/>
                        <xsl:attribute name="transform" select="'translate(' || string-join($offset, ', ') || ') scale(1,-1)'"/>
                    </xsl:element>
                </xsl:element>
            </xsl:result-document>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>
