<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="3.1">
    
    <xsl:output indent="yes" encoding="UTF-8" method="xml"/>
    
    <xsl:param name="ranges"/>
    <xsl:param name="classes"/>
    <xsl:param name="glyphnames"/>
    <xsl:param name="current.version"/>
    <xsl:param name="image.server"/>
    <xsl:param name="bravura.version"/>
    <xsl:param name="smufl.version"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:sourceDesc">
        <xsl:copy>
            <xsl:element name="p">
                Born digital, created with SMuFL-Browser version
                <xsl:element name="num">
                    <xsl:attribute name="type" select="'smufl-browser-version'"/>
                    <xsl:value-of select="$current.version"/>
                </xsl:element>
                on
                <xsl:element name="date">
                    <xsl:value-of select="current-dateTime()"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="p">
                Based upon SMuFL version
                <xsl:element name="num">
                    <xsl:attribute name="type" select="'smufl-version'"/>
                    <xsl:value-of select="$smufl.version"/>
                </xsl:element>
                and Bravura version 
                <xsl:element name="num">
                    <xsl:attribute name="type" select="'bravura-version'"/>
                    <xsl:value-of select="$bravura.version"/>
                </xsl:element>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:encodingDesc">
        <xsl:copy>
            <xsl:for-each select="json-doc($ranges)?*">
                <xsl:sort select=".?description"/>
                <xsl:call-template name="charDecl"/>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:revisionDesc"/>
    
    <xsl:template name="charDecl">
        <xsl:element name="charDecl">
            <xsl:element name="desc">
                <xsl:value-of select="normalize-space(.?description)"/>
            </xsl:element>
            <xsl:for-each select=".?glyphs?*">
                <xsl:call-template name="char"/>
            </xsl:for-each>
            <xsl:if test="count(.?glyphs) eq 0">
                <!-- Provide an empty char to make the resulting file valid … -->
                <xsl:element name="char"/>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="char">
        <xsl:variable name="glyphName" select="normalize-space(.)"/>
        <xsl:variable name="glyph" select="json-doc($glyphnames)?($glyphName)"/>
        <xsl:element name="char">
            <!-- glyph names with a leading digit get an underscore prefix -->
            <xsl:attribute name="xml:id" select="concat('_', $glyphName)"/>
            <xsl:element name="charName">
                <xsl:value-of select="$glyphName"/>
            </xsl:element>
            <xsl:element name="desc">
                <xsl:value-of select="$glyph?description => normalize-space()"/>
            </xsl:element>
            <xsl:element name="mapping">
                <xsl:attribute name="type" select="'smufl'"/>
                <xsl:value-of select="$glyph?codepoint => normalize-space()"/>
            </xsl:element>
            <xsl:variable name="alternateCodepoint" select="$glyph?alternateCodepoint => normalize-space()"/>
            <xsl:if test="$alternateCodepoint">
                <xsl:element name="mapping">
                    <xsl:attribute name="type" select="'standard'"/>
                    <xsl:choose>
                        <xsl:when test="starts-with($alternateCodepoint, 'U+')">
                            <xsl:value-of select="$alternateCodepoint"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat('U+', $alternateCodepoint)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
            </xsl:if>
            <xsl:if test="not(contains($glyphName, 'Unused'))">
                <!-- A dirty hack to exclude those 4 accSagittalUnused* glyphs which only exist in the metadata files but not in the Bravura font -->
                <xsl:element name="graphic">
                    <xsl:attribute name="url" select="concat($image.server, substring-after($glyph?codepoint => normalize-space(), 'U+'), '.png')"/>
                </xsl:element>
            </xsl:if>
            <xsl:call-template name="classes"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="classes">
        <xsl:variable name="glyphName" select="normalize-space(.)"/>
        <xsl:variable name="classesMap" select="json-doc($classes)" as="map(*)"/>
        <xsl:variable name="classNames" select="for $class in map:keys($classesMap) return if($classesMap?($class)?* = $glyphName) then normalize-space($class) else ()"/>
        <xsl:if test="count($classNames) gt 0">
            <xsl:element name="note">
                <xsl:element name="list">
                    <xsl:element name="head">Classes</xsl:element>
                    <xsl:for-each select="$classNames">
                        <xsl:sort/>
                        <xsl:element name="item">
                            <xsl:value-of select="."/>
                        </xsl:element>
                    </xsl:for-each>
                </xsl:element>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:function name="tei:extract-version-number">
        <xsl:param name="url" as="xs:string"/>
        <xsl:analyze-string select="$url" regex="(\d+\.\d+)">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
</xsl:stylesheet>