<?xml version="1.0"?>

<xsl:stylesheet
    version="1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xlink="http://www.w3.org/1999/xlink" >
  <xsl:output method="text" />
  <xsl:param name="src" select="undefined" />

  <xsl:template match="@*|node()" >
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="xs:schema" >
    <xsl:text># NAME:              custom
# URL:               </xsl:text>
    <xsl:value-of select="$src" />
    <xsl:text>

</xsl:text>
    <xsl:apply-templates />
  </xsl:template>
  
  <xsl:template match="xs:element" >
    <xsl:value-of select="@name" />
    <xsl:text>
</xsl:text>
  </xsl:template>
</xsl:stylesheet> 
