<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:jxml="http://www.xmlsh.org/jxml"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output indent="yes" encoding="UTF-8" method="xml"/>
    
    <xsl:param name="ranges"/>
    <xsl:param name="classes"/>
    <xsl:param name="glyphnames"/>
    <xsl:param name="current.version"/>
    
    <xsl:key name="glyphs" match="jxml:member" use="normalize-space(@name)"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:encodingDesc">
        <xsl:copy>
            <xsl:for-each select="doc($ranges)/jxml:object/jxml:member">
                <xsl:call-template name="charDecl"/>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:revisionDesc">
        <xsl:copy>
            <xsl:call-template name="create-change-entry"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="charDecl">
        <xsl:element name="charDecl">
            <xsl:element name="desc">
                <xsl:value-of select="normalize-space(.//jxml:member[@name='description'])"/>
            </xsl:element>
            <xsl:for-each select=".//jxml:member[@name='glyphs']/jxml:array/jxml:string">
                <xsl:call-template name="char"/>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="char">
        <xsl:variable name="glyph" select="key('glyphs', normalize-space(.), doc($glyphnames))"></xsl:variable>
        <xsl:element name="char">
            <!-- glyph names with a leading digit get an underscore prefix -->
            <xsl:attribute name="xml:id" select="
                if(matches($glyph/normalize-space(@name), '^\d')) then concat('_', $glyph/normalize-space(@name))
                else $glyph/normalize-space(@name)"/>
            <xsl:element name="charName">
                <xsl:value-of select="$glyph//jxml:member[@name='description']/normalize-space(jxml:string)"/>
            </xsl:element>
            <xsl:element name="mapping">
                <xsl:attribute name="type" select="'smufl'"/>
                <xsl:value-of select="$glyph//jxml:member[@name='codepoint']/normalize-space(jxml:string)"/>
            </xsl:element>
            <xsl:if test="$glyph//jxml:member[@name='alternateCodepoint']">
                <xsl:element name="mapping">
                    <xsl:attribute name="type" select="'standard'"/>
                    <xsl:value-of select="$glyph//jxml:member[@name='alternateCodepoint']/normalize-space(jxml:string)"/>
                </xsl:element>
            </xsl:if>
            <xsl:call-template name="classes"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="classes">
        <xsl:variable name="glyphName" select="normalize-space(.)"/>
        <xsl:variable name="classNames" select="doc($classes)/jxml:object/jxml:member[.//jxml:string/normalize-space() = $glyphName]"/>
        <xsl:if test="$classNames">
            <xsl:element name="note">
                <xsl:element name="list">
                    <xsl:element name="head">Classes</xsl:element>
                    <xsl:for-each select="$classNames">
                        <xsl:element name="item">
                            <xsl:value-of select="normalize-space(@name)"/>
                        </xsl:element>
                    </xsl:for-each>
                </xsl:element>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="create-change-entry">
        <xsl:element name="change">
            <xsl:attribute name="when" select="current-date()"/>
            <xsl:value-of select="concat('Automated transformation to version ', $current.version)"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>