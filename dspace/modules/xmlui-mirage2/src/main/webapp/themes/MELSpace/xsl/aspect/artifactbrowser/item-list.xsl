<!--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

-->

<!--
    Rendering of a list of items (e.g. in a search or
    browse results page)

    Author: art.lowel at atmire.com
    Author: lieven.droogmans at atmire.com
    Author: ben at atmire.com
    Author: Alexey Maslov

-->

<xsl:stylesheet
    xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
    xmlns:dri="http://di.tamu.edu/DRI/1.0/"
    xmlns:mets="http://www.loc.gov/METS/"
    xmlns:dim="http://www.dspace.org/xmlns/dspace/dim"
    xmlns:xlink="http://www.w3.org/TR/xlink/"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:atom="http://www.w3.org/2005/Atom"
    xmlns:ore="http://www.openarchives.org/ore/terms/"
    xmlns:oreatom="http://www.openarchives.org/ore/atom/"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xalan="http://xml.apache.org/xalan"
    xmlns:encoder="xalan://java.net.URLEncoder"
    xmlns:util="org.dspace.app.xmlui.utils.XSLUtils"
    xmlns:confman="org.dspace.core.ConfigurationManager"
    xmlns:url="http://whatever/java/java.net.URLEncoder"
    exclude-result-prefixes="xalan encoder i18n dri mets dim xlink xsl util confman">

    <xsl:output indent="yes"/>

    <!--these templates are modfied to support the 2 different item list views that
    can be configured with the property 'xmlui.theme.mirage.item-list.emphasis' in dspace.cfg-->

    <xsl:template name="itemSummaryList-DIM">
        <xsl:variable name="itemWithdrawn" select="./mets:dmdSec/mets:mdWrap[@OTHERMDTYPE='DIM']/mets:xmlData/dim:dim/@withdrawn" />

        <xsl:variable name="href">
            <xsl:choose>
                <xsl:when test="$itemWithdrawn">
                    <xsl:value-of select="@OBJEDIT"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@OBJID"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="emphasis" select="confman:getProperty('xmlui.theme.mirage.item-list.emphasis')"/>
        <xsl:choose>
            <xsl:when test="'file' = $emphasis">


                <div class="item-wrapper row">
                    <div class="col-sm-3 hidden-xs">
                        <xsl:apply-templates select="./mets:fileSec" mode="artifact-preview">
                            <xsl:with-param name="href" select="$href"/>
                            <xsl:with-param name="mel_thumbnail" select="./mets:dmdSec/mets:mdWrap[@OTHERMDTYPE='DIM']/mets:xmlData/dim:dim/dim:field[@element='file' and @qualifier='thumbnail']"/>
                        </xsl:apply-templates>
                    </div>

                    <div class="col-sm-9">
                        <xsl:apply-templates select="./mets:dmdSec/mets:mdWrap[@OTHERMDTYPE='DIM']/mets:xmlData/dim:dim"
                                             mode="itemSummaryList-DIM-metadata">
                            <xsl:with-param name="href" select="$href"/>
                        </xsl:apply-templates>
                    </div>

                </div>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="./mets:dmdSec/mets:mdWrap[@OTHERMDTYPE='DIM']/mets:xmlData/dim:dim"
                                     mode="itemSummaryList-DIM-metadata"><xsl:with-param name="href" select="$href"/></xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--handles the rendering of a single item in a list in file mode-->
    <!--handles the rendering of a single item in a list in metadata mode-->
    <xsl:template match="dim:dim" mode="itemSummaryList-DIM-metadata">
        <xsl:param name="href"/>
        <div class="artifact-description">
            <h4 class="artifact-title">
			<span class="element-label">Title: </span>
                <xsl:element name="a">
                    <xsl:attribute name="href">
                        <xsl:value-of select="$href"/>
                    </xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="dim:field[@element='title']">
                            <xsl:value-of select="dim:field[@element='title'][1]/node()"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <i18n:text>xmlui.dri2xhtml.METS-1.0.no-title</i18n:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
                <span class="Z3988">
                    <xsl:attribute name="title">
                        <xsl:call-template name="renderCOinS"/>
                    </xsl:attribute>
                    &#xFEFF; <!-- non-breaking space to force separating the end tag -->
                </span>
            </h4>
            <div class="artifact-info">
                <xsl:call-template name="itemDetailList-DIM-authors" />

                <xsl:text> </xsl:text>
                <xsl:if test="dim:field[@element='date' and @qualifier='issued']">
	                <span class="publisher-date h4">  <small>
	                    <xsl:text>(</xsl:text>
	                    <xsl:if test="dim:field[@element='publisher']">
	                        <span class="publisher">
	                            <xsl:copy-of select="dim:field[@element='publisher']/node()"/>
	                        </span>
	                        <xsl:text>, </xsl:text>
	                    </xsl:if>
	                    <span class="date">
	                        <xsl:value-of select="substring(dim:field[@element='date' and @qualifier='issued']/node(),1,10)"/>
	                    </span>
	                    <xsl:text>)</xsl:text>
                        </small></span>
                </xsl:if>
            </div>
			<div class="artifact-info">
				<span class="element-label">Date: </span>
				<xsl:element name="span">
                    <xsl:choose>
                        <xsl:when test="dim:field[@element='date']">
                            <xsl:value-of select="dim:field[@element='date'][1]/node()"/>
                        </xsl:when>
                        <xsl:otherwise>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
			</div>
			<div class="artifact-info">
				<span class="element-label">Type: </span>
				<xsl:element name="span">
                    <xsl:choose>
                        <xsl:when test="dim:field[@element='type']">
                            <xsl:call-template name="discovery-link">
                                <xsl:with-param name="value" select="dim:field[@element='type'][1]/node()"/>
                                <xsl:with-param name="filtertype" select="'type'"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
			</div>
			<div class="artifact-info">
				<span class="element-label">Status: </span>
				<xsl:element name="span">
                    <xsl:choose>
                        <xsl:when test="dim:field[@element='identifier' and @qualifier='status']">
                            <xsl:value-of select="dim:field[@element='identifier' and @qualifier='status'][1]/node()"/>
                        </xsl:when>
                        <xsl:otherwise>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
			</div>
            <xsl:if test="dim:field[@element = 'description' and @qualifier='abstract']">
                <xsl:variable name="abstract" select="dim:field[@element = 'description' and @qualifier='abstract']/node()"/>
                <div class="artifact-abstract">
                    <xsl:value-of select="util:shortenString($abstract, 220, 10)"/>
                </div>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template name="itemDetailList-DIM">
        <xsl:call-template name="itemSummaryList-DIM"/>
    </xsl:template>


    <xsl:template match="mets:fileSec" mode="artifact-preview">
        <xsl:param name="href"/>
        <xsl:param name="mel_thumbnail"/>
        <div class="thumbnail artifact-preview">
            <a class="image-link" href="{$href}">
                <xsl:choose>
                    <xsl:when test="mets:fileGrp[@USE='THUMBNAIL']">
                        <img class="img-responsive" alt="xmlui.mirage2.item-list.thumbnail" i18n:attr="alt">
                            <xsl:attribute name="src">
                                <xsl:value-of
                                        select="mets:fileGrp[@USE='THUMBNAIL']/mets:file/mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                            </xsl:attribute>
                        </img>
                    </xsl:when>
                    <xsl:when test="$mel_thumbnail">
                        <img class="img-responsive" alt="xmlui.mirage2.item-list.thumbnail" i18n:attr="alt">
                            <xsl:attribute name="src">
                                <xsl:value-of select="$mel_thumbnail[1]/node()"/>
                            </xsl:attribute>
                        </img>
                    </xsl:when>
                    <xsl:otherwise>
                        <img src="/themes/MELSpace/images/nothumb.jpg" alt="xmlui.mirage2.item-list.thumbnail"
                             i18n:attr="alt"/>
                    </xsl:otherwise>
                </xsl:choose>
            </a>
        </div>
    </xsl:template>

    <xsl:template name="itemDetailList-DIM-authors">
        <span class="element-label">
            <i18n:text>xmlui.dri2xhtml.METS-1.0.item-authors</i18n:text>
        </span>
        <span class="author h4">
            <small>
                <xsl:if test="dim:field[@element='creator'][not(@qualifier)]">
                    <xsl:for-each select="dim:field[@element='creator'][not(@qualifier)]">
                        <xsl:call-template name="itemDetailList-DIM-authors-entry" />
                        <xsl:if test="count(following-sibling::dim:field[@element='creator'][not(@qualifier)]) != 0">
                            <xsl:text>; </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test="count(dim:field[@element='creator'][not(@qualifier)]) != 0 and count(dim:field[@element='contributor'][not(@qualifier)]) != 0">
                    <xsl:text>; </xsl:text>
                </xsl:if>
                <xsl:if test="dim:field[@element='contributor'][not(@qualifier)]">
                    <xsl:for-each select="dim:field[@element='contributor'][not(@qualifier)]">
                        <xsl:call-template name="itemDetailList-DIM-authors-entry" />
                        <xsl:if test="count(following-sibling::dim:field[@element='contributor'][not(@qualifier)]) != 0">
                            <xsl:text>; </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
            </small>
        </span>
    </xsl:template>

    <!--    TEMP, to activate when updating CGCore-->
    <!--    <xsl:template name="itemDetailList-DIM-authors">-->
    <!--        <xsl:if test="dim:field[@element='contributor'][@qualifier='author' and descendant::text()] or dim:field[@element='creator' and descendant::text()] or dim:field[@element='contributor' and descendant::text()]">-->
    <!--            <div class="simple-item-view-authors item-page-field-wrapper table">-->
    <!--                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-authors</i18n:text></h5>-->
    <!--                <xsl:choose>-->
    <!--                    <xsl:when test="dim:field[@element='contributor'][@qualifier='author']">-->
    <!--                        <xsl:for-each select="dim:field[@element='contributor'][@qualifier='author']">-->
    <!--                            <xsl:call-template name="itemDetailList-DIM-authors-entry" />-->
    <!--                        </xsl:for-each>-->
    <!--                    </xsl:when>-->
    <!--                    <xsl:when test="dim:field[@element='creator']">-->
    <!--                        <xsl:for-each select="dim:field[@element='creator']">-->
    <!--                            <xsl:call-template name="itemDetailList-DIM-authors-entry" />-->
    <!--                        </xsl:for-each>-->
    <!--                    </xsl:when>-->
    <!--                    <xsl:when test="dim:field[@element='contributor']">-->
    <!--                        <xsl:for-each select="dim:field[@element='contributor']">-->
    <!--                            <xsl:call-template name="itemDetailList-DIM-authors-entry" />-->
    <!--                        </xsl:for-each>-->
    <!--                    </xsl:when>-->
    <!--                    <xsl:otherwise>-->
    <!--                        <i18n:text>xmlui.dri2xhtml.METS-1.0.no-author</i18n:text>-->
    <!--                    </xsl:otherwise>-->
    <!--                </xsl:choose>-->
    <!--            </div>-->
    <!--        </xsl:if>-->
    <!--    </xsl:template>-->
    <xsl:template name="itemDetailList-DIM-authors-entry">
        <xsl:call-template name="discovery-link">
            <xsl:with-param name="value" select="node()"/>
            <xsl:with-param name="filtertype" select="'author'"/>
        </xsl:call-template>
    </xsl:template>

    <!--Helper template that creates a link to the discovery page based on a given node and filtertype to inject into the link-->
    <xsl:template name="discovery-link">
        <xsl:param name="value"/>
        <xsl:param name="filtertype"/>
        <xsl:variable name="filterlink">
            <xsl:value-of select="concat($context-path,'/discover?filtertype=',$filtertype,'&amp;filter_relational_operator=equals&amp;filter=',url:encode($value))"></xsl:value-of>
        </xsl:variable>
        <a target="_blank">
            <xsl:attribute name="href" >
                <xsl:value-of select="$filterlink"/>
            </xsl:attribute>
            <xsl:copy-of select="$value"/>
        </a>
    </xsl:template>
    <!--
        Rendering of a list of items (e.g. in a search or
        browse results page)

        Author: art.lowel at atmire.com
        Author: lieven.droogmans at atmire.com
        Author: ben at atmire.com
        Author: Alexey Maslov

    -->



        <!-- Generate the info about the item from the metadata section -->
        <xsl:template match="dim:dim" mode="itemSummaryList-DIM">
            <xsl:variable name="itemWithdrawn" select="@withdrawn" />
            <div class="artifact-description">
                <div class="artifact-title">
                    <xsl:element name="a">
                        <xsl:attribute name="href">
                            <xsl:choose>
                                <xsl:when test="$itemWithdrawn">
                                    <xsl:value-of select="ancestor::mets:METS/@OBJEDIT" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="ancestor::mets:METS/@OBJID" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:choose>
                            <xsl:when test="dim:field[@element='title']">
                                <xsl:value-of select="dim:field[@element='title'][1]/node()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.no-title</i18n:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:element>
                </div>
                <span class="Z3988">
                    <xsl:attribute name="title">
                        <xsl:call-template name="renderCOinS"/>
                    </xsl:attribute>
                    &#xFEFF; <!-- non-breaking space to force separating the end tag -->
                </span>
                <div class="artifact-info">
                    <span class="author">
                        <xsl:choose>
                            <xsl:when test="dim:field[@element='contributor'][@qualifier='author']">
                                <xsl:for-each select="dim:field[@element='contributor'][@qualifier='author']">
                                    <span>
                                        <xsl:if test="@authority">
                                            <xsl:attribute name="class"><xsl:text>ds-dc_contributor_author-authority</xsl:text></xsl:attribute>
                                        </xsl:if>
                                        <xsl:copy-of select="node()"/>
                                    </span>
                                    <xsl:if test="count(following-sibling::dim:field[@element='contributor'][@qualifier='author']) != 0">
                                        <xsl:text>; </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:when test="dim:field[@element='creator']">
                                <xsl:for-each select="dim:field[@element='creator']">
                                    <xsl:copy-of select="node()"/>
                                    <xsl:if test="count(following-sibling::dim:field[@element='creator']) != 0">
                                        <xsl:text>; </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:when test="dim:field[@element='contributor']">
                                <xsl:for-each select="dim:field[@element='contributor']">
                                    <xsl:copy-of select="node()"/>
                                    <xsl:if test="count(following-sibling::dim:field[@element='contributor']) != 0">
                                        <xsl:text>; </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.no-author</i18n:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </span>
                    <xsl:text> </xsl:text>
                    <xsl:if test="dim:field[@element='date' and @qualifier='issued'] or dim:field[@element='publisher']">
                        <span class="publisher-date">
                            <xsl:text>(</xsl:text>
                            <xsl:if test="dim:field[@element='publisher']">
                                <span class="publisher">
                                    <xsl:copy-of select="dim:field[@element='publisher']/node()"/>
                                </span>
                                <xsl:text>, </xsl:text>
                            </xsl:if>
                            <span class="date">
                                <xsl:value-of select="substring(dim:field[@element='date' and @qualifier='issued']/node(),1,10)"/>
                            </span>
                            <xsl:text>)</xsl:text>
                        </span>
                    </xsl:if>
                </div>
            </div>
        </xsl:template>

</xsl:stylesheet>
