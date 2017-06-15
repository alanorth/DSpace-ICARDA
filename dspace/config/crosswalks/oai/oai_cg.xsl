<?xml version="1.0" encoding="UTF-8" ?>
<!-- 


    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/
	Developed by DSpace @ Lyncode <dspace@lyncode.com>
	
	> http://www.openarchives.org/OAI/2.0/oai_dc.xsd

 -->
<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:doc="http://www.lyncode.com/xoai"
	version="1.0">
	<xsl:output omit-xml-declaration="yes" method="xml" indent="yes" />
	
	<xsl:template match="/">
		<oai_cg:cg xmlns:oai_cg="http://www.openarchives.org/OAI/2.0/oai_cg/" 
			xmlns:cg="http://purl.org/dc/elements/1.1/" 
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
			xsi:schemaLocation="http://drylandsystems.cgiar.org/documents/cg-terms/ https://repo.mel.cgiar.org/themes/Mirage2/oai_cg.xsd">
			<!-- cg.contact -->
			<xsl:for-each select="doc:metadata/doc:element[@name='cg']/doc:element[@name='contact']">
				<cg:contact><xsl:value-of select="." /></cg:contact>
			</xsl:for-each>
			<!-- dc.contact.* -->
			<xsl:for-each select="doc:metadata/doc:element[@name='cg']/doc:element[@name='contact']">
				<cg:contact><xsl:value-of select="." /></cg:contact>
			</xsl:for-each>
		</oai_cg:cg>
	</xsl:template>
</xsl:stylesheet>
