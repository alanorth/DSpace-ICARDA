
<!--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

-->

<!--
    Rendering specific to the item display page.

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
    xmlns:jstring="java.lang.String"
    xmlns:rights="http://cosimo.stanford.edu/sdr/metsrights/"
    xmlns:confman="org.dspace.core.ConfigurationManager"
    xmlns:url="http://whatever/java/java.net.URLEncoder"
    exclude-result-prefixes="xalan encoder i18n dri mets dim xlink xsl util jstring rights confman">

    <xsl:output indent="yes"/>

    <xsl:template name="itemSummaryView-DIM">
        <!-- Generate the info about the item from the metadata section -->
        <xsl:apply-templates select="./mets:dmdSec/mets:mdWrap[@OTHERMDTYPE='DIM']/mets:xmlData/dim:dim"
        mode="itemSummaryView-DIM">
            <xsl:with-param name="dspace_item_id" select="substring-after(@OBJEDIT, '/admin/item?itemID=')"/>
            <xsl:with-param name="dspace_item_handle" select="@OBJID"/>
        </xsl:apply-templates>

        <xsl:copy-of select="$SFXLink" />

        <!-- Generate the Creative Commons license information from the file section (DSpace deposit license hidden by default)-->
        <xsl:if test="./mets:fileSec/mets:fileGrp[@USE='CC-LICENSE' or @USE='LICENSE']">
            <div class="license-info table">
                <p>
                    <i18n:text>xmlui.dri2xhtml.METS-1.0.license-text</i18n:text>
                </p>
                <ul class="list-unstyled">
                    <xsl:apply-templates select="./mets:fileSec/mets:fileGrp[@USE='CC-LICENSE' or @USE='LICENSE']" mode="simple"/>
                </ul>
            </div>
        </xsl:if>


    </xsl:template>

    <!-- An item rendered in the detailView pattern, the "full item record" view of a DSpace item in Manakin. -->
    <xsl:template name="itemDetailView-DIM">
        <!-- Output all of the metadata about the item from the metadata section -->
        <xsl:apply-templates select="mets:dmdSec/mets:mdWrap[@OTHERMDTYPE='DIM']/mets:xmlData/dim:dim"
                             mode="itemDetailView-DIM">
            <xsl:with-param name="dspace_item_id" select="substring-after(@OBJEDIT, '/admin/item?itemID=')"/>
            <xsl:with-param name="dspace_item_handle" select="@OBJID"/>
        </xsl:apply-templates>

        <!-- Generate the bitstream information from the file section -->
        <xsl:choose>
            <xsl:when test="./mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL' or @USE='LICENSE']/mets:file">
                <h3><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-head</i18n:text></h3>
                <div class="file-list">
                    <xsl:apply-templates select="./mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL' or @USE='LICENSE' or @USE='CC-LICENSE']">
                        <xsl:with-param name="context" select="."/>
                        <xsl:with-param name="primaryBitstream" select="./mets:structMap[@TYPE='LOGICAL']/mets:div[@TYPE='DSpace Item']/mets:fptr/@FILEID"/>
                    </xsl:apply-templates>
                </div>
            </xsl:when>
            <!-- Special case for handling ORE resource maps stored as DSpace bitstreams -->
            <xsl:when test="./mets:fileSec/mets:fileGrp[@USE='ORE']">
                <xsl:apply-templates select="./mets:fileSec/mets:fileGrp[@USE='ORE']" mode="itemDetailView-DIM" />
            </xsl:when>
            <xsl:otherwise>
                <h2><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-head</i18n:text></h2>
                <table class="ds-table file-list">
                    <tr class="ds-table-header-row">
                        <th><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-file</i18n:text></th>
                        <th><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-size</i18n:text></th>
                        <th><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-format</i18n:text></th>
                        <th><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-view</i18n:text></th>
                    </tr>
                    <tr>
                        <td colspan="4">
                            <p><i18n:text>xmlui.dri2xhtml.METS-1.0.item-no-files</i18n:text></p>
                        </td>
                    </tr>
                </table>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>


    <xsl:template match="dim:dim" mode="itemSummaryView-DIM">
        <xsl:param name="dspace_item_id"/>
        <xsl:param name="dspace_item_handle"/>
        <input type="hidden" name="dspace_item_id" value="{$dspace_item_id}"/>
        <input type="hidden" name="dspace_item_handle" value="{$dspace_item_handle}"/>
        <div class="item-summary-view-metadata">
            <xsl:call-template name="itemSummaryView-DIM-title"/>
            <div class="row">
                <div class="col-sm-4">
                    <div class="row">
                        <div class="col-xs-6 col-sm-12">
                            <xsl:call-template name="itemSummaryView-DIM-thumbnail"/>
                        </div>
                        <div class="col-xs-6 col-sm-12">
                            <xsl:call-template name="itemSummaryView-DIM-file-section"/>
                        </div>
                    </div>
                    <xsl:call-template name="itemSummaryView-DIM-date"/>
                    <xsl:if test="count(dim:field[@mdschema='mel' and @element='impact-factor'][not(@qualifier)]) = 1">
                        <h5>
                            <i18n:text>xmlui.dri2xhtml.METS-1.0.item-impact-factor</i18n:text>:
                            <xsl:value-of select="dim:field[@mdschema='mel' and @element='impact-factor'][not(@qualifier)][1]/node()"/>
                            <xsl:if test="count(dim:field[@mdschema='mel' and @element='date' and @qualifier='year']) = 1">
                                (Year: <xsl:value-of select="dim:field[@mdschema='mel' and @element='date' and @qualifier='year'][1]/node()"/>)
                            </xsl:if>
                        </h5>
                    </xsl:if>
                    <xsl:call-template name="itemSummaryView-DIM-authors"/>
                    <xsl:if test="$ds_item_view_toggle_url != ''">
                        <xsl:call-template name="itemSummaryView-show-full"/>
                    </xsl:if>
                </div>
                <div class="col-sm-8">
                    <xsl:call-template name="itemSummaryView-DIM-citation"/>
                    <xsl:call-template name="itemSummaryView-DIM-abstract"/>
                    <div class="row">
                        <div class="col-sm-8">
                            <xsl:call-template name="itemSummaryView-DIM-URI"/>
                            <xsl:call-template name="itemSummaryView-DIM-DOI"/>
                            <xsl:call-template name="itemSummaryView-collections"/>
                        </div>
                        <div class="col-sm-4" style="text-align: right; margin-top: 10px;">
                            <xsl:call-template name="itemSummaryView-ALTMETRICS"/>
                        </div>
                    </div>
                    <xsl:call-template name="itemSummaryView-DIM-orcids"/>
                    <xsl:call-template name="itemSummaryView-DIM-subject"/>
                    <xsl:call-template name="itemSummaryView-DIM-subject-AGROVOC"/>
                    <div class="partners-list-logos"></div>
                </div>
            </div>
            <div id="item_map" class="item_map">
                <div class="overlay-layer-parent">
                    <div class="overlay-layer">
                        Click to enable
                    </div>
                </div>
                <xsl:for-each select="dim:field[@mdschema = 'cg' and @element='coverage' and @qualifier='country']">
                    <input type="hidden">
                        <xsl:attribute name="value">
                            <xsl:value-of select="./node()"/>
                        </xsl:attribute>
                    </input>
                </xsl:for-each>
            </div>
        </div>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-title">
        <xsl:choose>
            <xsl:when test="count(dim:field[@element='title'][not(@qualifier)]) &gt; 1">
                <h2 class="page-header first-page-header">
                    <xsl:value-of select="dim:field[@element='title'][not(@qualifier)][1]/node()"/>
                </h2>
                <div class="simple-item-view-other">
                    <p class="lead">
                        <xsl:for-each select="dim:field[@element='title'][not(@qualifier)]">
                            <xsl:if test="not(position() = 1)">
                                <xsl:value-of select="./node()"/>
                                <xsl:if test="count(following-sibling::dim:field[@element='title'][not(@qualifier)]) != 0">
                                    <xsl:text>; </xsl:text>
                                    <br/>
                                </xsl:if>
                            </xsl:if>

                        </xsl:for-each>
                    </p>
                </div>
            </xsl:when>
            <xsl:when test="count(dim:field[@element='title'][not(@qualifier)]) = 1">
                <h2 class="page-header first-page-header">
                    <xsl:value-of select="dim:field[@element='title'][not(@qualifier)][1]/node()"/>
                </h2>
            </xsl:when>
            <xsl:otherwise>
                <h2 class="page-header first-page-header">
                    <i18n:text>xmlui.dri2xhtml.METS-1.0.no-title</i18n:text>
                </h2>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-thumbnail">
        <div class="thumbnail">
            <xsl:choose>
                <xsl:when test="//mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL']">
                    <xsl:variable name="src">
                        <xsl:choose>
                            <xsl:when test="/mets:METS/mets:fileSec/mets:fileGrp[@USE='ORIGINAL']/mets:file[@GROUPID=../../mets:fileGrp[@USE='CONTENT']/mets:file[@GROUPID=../../mets:fileGrp[@USE='ORIGINAL']/mets:file/@GROUPID][1]/@GROUPID]">
                                <xsl:value-of
                                        select="/mets:METS/mets:fileSec/mets:fileGrp[@USE='ORIGINAL']/mets:file[@GROUPID=../../mets:fileGrp[@USE='ORIGINAL']/mets:file[@GROUPID=../../mets:fileGrp[@USE='ORIGINAL']/mets:file/@GROUPID][1]/@GROUPID]/mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of
                                        select="//mets:fileSec/mets:fileGrp[@USE='CONTENT']/mets:file/mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <img alt="Thumbnail">
                        <xsl:attribute name="src">
                            <xsl:value-of select="$src"/>
                        </xsl:attribute>
                    </img>
                </xsl:when>

                <xsl:when test="count(dim:field[@element='file' and @qualifier='thumbnail']) = 1">
                    <xsl:variable name="src">
                        <xsl:value-of select="dim:field[@element='file' and @qualifier='thumbnail'][1]/node()"/>
                    </xsl:variable>
                    <img alt="Thumbnail">
                        <xsl:attribute name="src">
                            <xsl:value-of select="$src"/>
                        </xsl:attribute>
                    </img>
                </xsl:when>

                <xsl:otherwise>
                    <img src="/themes/MELSpace/images/nothumb.jpg" />
                </xsl:otherwise>
            </xsl:choose>
        </div>
		<span>
			<xsl:choose>
                <xsl:when test="dim:field[@element='identifier'][not(@qualifier)][last()]">
                    <xsl:element name="a">
                        <xsl:attribute name="class">view-download</xsl:attribute>
                        <xsl:attribute name="href">
                            <xsl:value-of select="dim:field[@element='identifier'][not(@qualifier)][last()]/node()"/>
                        </xsl:attribute>
                        <xsl:element name="i">
                            <xsl:attribute name="class">glyphicon glyphicon-download-alt</xsl:attribute>
                        </xsl:element>
                        View/Open
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="a">
                        <xsl:attribute name="href">
                            <xsl:value-of select="dim:field[@element='identifier'][not(@qualifier)][1]/node()"/>
                        </xsl:attribute>
                        <xsl:choose>
                            <xsl:when test="dim:field[@element='identifier'][not(@qualifier)][1]/node()">
                                View/Open
                            </xsl:when>
                        </xsl:choose>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="dim:field[@mdschema='mel' and @element='contact' and @qualifier='email'][1]/node()!=''">
                <xsl:element name="div">
                    <xsl:attribute name="class">send_cg_contact</xsl:attribute>
                    <xsl:attribute name="data-contact_mail">
                        <xsl:value-of
                                select="dim:field[@mdschema='mel' and @element='contact' and @qualifier='email'][1]/node()"/>
                    </xsl:attribute>
                    <xsl:attribute name="data-contact_domain">
                        <xsl:value-of
                                select="dim:field[@mdschema='mel' and @element='contact' and @qualifier='domain'][1]/node()"/>
                    </xsl:attribute>
                    <xsl:attribute name="style">cursor: pointer;</xsl:attribute>
                    Corresponding Author
                    <xsl:element name="i">
                        <xsl:attribute name="class">glyphicon glyphicon-envelope</xsl:attribute>
                    </xsl:element>
                </xsl:element>
            </xsl:if>
		</span>

    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-citation">
        <xsl:if test="dim:field[@element='identifier' and @qualifier='citation']">
            <div class="simple-item-view-description item-page-field-wrapper table">
                <h5 class="bold"><i18n:text>xmlui.dri2xhtml.METS-1.0.item-citation</i18n:text></h5>
                <div>
                    <xsl:for-each select="dim:field[@element='identifier' and @qualifier='citation']">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <xsl:copy-of select="node()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@element='identifier' and @qualifier='citation']) != 0">
                            <div class="spacer">&#160;</div>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:if test="count(dim:field[@element='identifier' and @qualifier='citation']) &gt; 1">
                        <div class="spacer">&#160;</div>
                    </xsl:if>
                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-abstract">
        <xsl:if test="dim:field[@element='description' and @qualifier='abstract']">
            <div class="simple-item-view-description item-page-field-wrapper table">
                <h5 class="bold"><i18n:text>xmlui.dri2xhtml.METS-1.0.item-abstract</i18n:text></h5>
                <div>
                    <xsl:for-each select="dim:field[@element='description' and @qualifier='abstract']">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <xsl:copy-of select="node()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@element='description' and @qualifier='abstract']) != 0">
                            <div class="spacer">&#160;</div>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:if test="count(dim:field[@element='description' and @qualifier='abstract']) &gt; 1">
                        <div class="spacer">&#160;</div>
                    </xsl:if>
                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-authors">
        <xsl:if test="dim:field[@mdschema='dc' and @element='creator'] or dim:field[@mdschema='dc' and @element='contributor']">
            <div class="simple-item-view-authors item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-authors</i18n:text></h5>
                <xsl:if test="dim:field[@element='creator'][not(@qualifier)]">
                    <xsl:for-each select="dim:field[@element='creator'][not(@qualifier)]">
                        <xsl:call-template name="itemSummaryView-DIM-authors-entry" />
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test="dim:field[@element='contributor'][not(@qualifier)]">
                    <xsl:for-each select="dim:field[@element='contributor'][not(@qualifier)]">
                        <xsl:call-template name="itemSummaryView-DIM-authors-entry" />
                    </xsl:for-each>
                </xsl:if>
            </div>
        </xsl:if>
    </xsl:template>

<!--    TEMP, to activate when updating CGCore-->
<!--    <xsl:template name="itemSummaryView-DIM-authors">-->
<!--        <xsl:if test="dim:field[@element='contributor'][@qualifier='author' and descendant::text()] or dim:field[@element='creator' and descendant::text()] or dim:field[@element='contributor' and descendant::text()]">-->
<!--            <div class="simple-item-view-authors item-page-field-wrapper table">-->
<!--                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-authors</i18n:text></h5>-->
<!--                <xsl:choose>-->
<!--                    <xsl:when test="dim:field[@element='contributor'][@qualifier='author']">-->
<!--                        <xsl:for-each select="dim:field[@element='contributor'][@qualifier='author']">-->
<!--                            <xsl:call-template name="itemSummaryView-DIM-authors-entry" />-->
<!--                        </xsl:for-each>-->
<!--                    </xsl:when>-->
<!--                    <xsl:when test="dim:field[@element='creator']">-->
<!--                        <xsl:for-each select="dim:field[@element='creator']">-->
<!--                            <xsl:call-template name="itemSummaryView-DIM-authors-entry" />-->
<!--                        </xsl:for-each>-->
<!--                    </xsl:when>-->
<!--                    <xsl:when test="dim:field[@element='contributor']">-->
<!--                        <xsl:for-each select="dim:field[@element='contributor']">-->
<!--                            <xsl:call-template name="itemSummaryView-DIM-authors-entry" />-->
<!--                        </xsl:for-each>-->
<!--                    </xsl:when>-->
<!--                    <xsl:otherwise>-->
<!--                        <i18n:text>xmlui.dri2xhtml.METS-1.0.no-author</i18n:text>-->
<!--                    </xsl:otherwise>-->
<!--                </xsl:choose>-->
<!--            </div>-->
<!--        </xsl:if>-->
<!--    </xsl:template>-->

    <xsl:template name="itemSummaryView-DIM-authors-entry">
        <div>
            <xsl:call-template name="discovery-link">
                <xsl:with-param name="value" select="node()"/>
                <xsl:with-param name="filtertype" select="'author'"/>
            </xsl:call-template>
        </div>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-orcids">
        <xsl:if test="dim:field[@mdschema='cg' and @element='creator'][@qualifier='id' and descendant::text()]">
            <div class="simple-item-view-authors item-page-field-wrapper table">
                <h5 class="bold"><i18n:text>xmlui.dri2xhtml.METS-1.0.item-orcid</i18n:text></h5>

                <xsl:for-each select="dim:field[@mdschema='cg' and @element='creator'][@qualifier='id']">
                    <xsl:call-template name="itemSummaryView-DIM-orcids-entry" />
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-orcids-entry">
        <!-- extract and strip orcid from cg.creator.id and build profile link -->
        <xsl:variable name="orcid-link" select="concat('https://orcid.org/', normalize-space(substring-after(node(), ':')))"/>
        <!-- extract and strip author name from cg.creator.id -->
        <xsl:variable name="orcid-name" select="normalize-space(substring-before(node(), ':'))"/>

        <div>
            <xsl:attribute name="class"><xsl:text>ds-cg_creator_orcid</xsl:text></xsl:attribute>

            <xsl:value-of select="$orcid-name"/>

            <a>
                <xsl:attribute name="target">_blank</xsl:attribute>
                <xsl:attribute name="rel">noopener</xsl:attribute>

                <xsl:attribute name="href">
                    <xsl:value-of select="$orcid-link"/>
                </xsl:attribute>

                <span>
                    <xsl:attribute name="class">ai ai-orcid</xsl:attribute>
                    <xsl:attribute name="aria-hidden">true</xsl:attribute>
                </span>

                <xsl:value-of select="$orcid-link"/>
            </a>
        </div>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-URI">
        <xsl:if test="dim:field[@element='identifier' and @qualifier='uri' and descendant::text()]">
            <div class="simple-item-view-uri item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-uri</i18n:text></h5>
                <span>
                    <xsl:for-each select="dim:field[@element='identifier' and @qualifier='uri']">
                        <a>
                            <xsl:attribute name="href">
                                <xsl:copy-of select="./node()"/>
                            </xsl:attribute>
                            <xsl:copy-of select="./node()"/>
                        </a>
                        <xsl:if test="count(following-sibling::dim:field[@element='identifier' and @qualifier='uri']) != 0">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-DOI">
        <xsl:if test="dim:field[@element='identifier' and @qualifier='doi' and descendant::text()]">
            <div class="simple-item-view-uri item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-doi</i18n:text></h5>
                <span>
                    <xsl:for-each select="dim:field[@element='identifier' and @qualifier='doi']">
                        <a>
                            <xsl:attribute name="href">
                                <xsl:copy-of select="./node()"/>
                            </xsl:attribute>
                            <xsl:copy-of select="./node()"/>
                        </a>
                        <xsl:if test="count(following-sibling::dim:field[@element='identifier' and @qualifier='doi']) != 0">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-date">
        <xsl:if test="dim:field[@element='date' and @qualifier='issued' and descendant::text()]">
            <div class="simple-item-view-date word-break item-page-field-wrapper table">
                <h5>
                    <i18n:text>xmlui.dri2xhtml.METS-1.0.item-date</i18n:text>
                </h5>
                <xsl:for-each select="dim:field[@element='date' and @qualifier='issued']">
                    <xsl:copy-of select="substring(./node(),1,10)"/>
                    <xsl:if test="count(following-sibling::dim:field[@element='date' and @qualifier='issued']) != 0">
                        <br/>
                    </xsl:if>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-show-full">
        <div class="simple-item-view-show-full item-page-field-wrapper table">
            <h5>
                <i18n:text>xmlui.mirage2.itemSummaryView.MetaData</i18n:text>
            </h5>
            <a>
                <xsl:attribute name="href"><xsl:value-of select="$ds_item_view_toggle_url"/></xsl:attribute>
                <i18n:text>xmlui.ArtifactBrowser.ItemViewer.show_full</i18n:text>
            </a>
			<br/><br/>
			<xsl:value-of select="dim:field[@element='identifier' and @qualifier='status'][1]/node()"/>
            <br/>
            <xsl:if test="dim:field[@mdschema = 'mel' and @element='licence' and @qualifier='image'][1]/node()!=''">
                <xsl:variable name="src">
                    <xsl:value-of select="dim:field[@mdschema = 'mel' and @element='licence' and @qualifier='image'][1]/node()"/>
                </xsl:variable>
                <img alt="status">
                    <xsl:attribute name="src">
                        <xsl:value-of select="$src"/>
                    </xsl:attribute>
                </img>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template name="itemSummaryView-collections">
        <xsl:if test="$document//dri:referenceSet[@id='aspect.artifactbrowser.ItemViewer.referenceSet.collection-viewer']">
            <div class="simple-item-view-collections item-page-field-wrapper table">
                <h5>
                    <i18n:text>xmlui.mirage2.itemSummaryView.Collections</i18n:text>
                </h5>
                <xsl:apply-templates select="$document//dri:referenceSet[@id='aspect.artifactbrowser.ItemViewer.referenceSet.collection-viewer']/dri:reference"/>
            </div>
            <div class="partners-list item-page-field-wrapper table">
                 <div class="values">
                 <xsl:for-each select="dim:field[@mdschema = 'mel' and @element='partner' and @qualifier='id']">
                      <input type="hidden">
                          <xsl:attribute name="value">
                             <xsl:value-of select="./node()"/>
                          </xsl:attribute>
                      </input>
                 </xsl:for-each>
                 </div>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-ALTMETRICS">
        <xsl:if test="dim:field[@element='identifier' and @qualifier='uri' and descendant::text()]">
            <div class="altmetric-embed" data-link-target="_blank" data-badge-type="medium-donut"
                 data-badge-popover="top" data-hide-less-than="1">
                <xsl:attribute name="data-handle">
                    <xsl:value-of
                            select="substring-after(dim:field[@element='identifier' and @qualifier='uri'][1]/node(),'hdl.handle.net/')"/>
                </xsl:attribute>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-subject">
        <xsl:if test="dim:field[@element='subject' and not(@qualifier)]">
            <div class="simple-item-view-description item-page-field-wrapper table">
                <h5 class="bold"><i18n:text>xmlui.dri2xhtml.METS-1.0.item-subjects</i18n:text></h5>
                <div>
                    <xsl:for-each select="dim:field[@element='subject' and not(@qualifier)]">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <xsl:call-template name="discovery-link">
                                    <xsl:with-param name="filtertype" select="'subject'"/>
                                    <xsl:with-param name="value" select="node()"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@element='subject' and not(@qualifier)]) != 0">
                            <xsl:text>; </xsl:text>
                        </xsl:if>
                    </xsl:for-each>

                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-subject-AGROVOC">
        <xsl:if test="dim:field[@mdschema='mel' and @element='subject' and @qualifier='agrovoc']">
            <div class="simple-item-view-description item-page-field-wrapper table">
                <h5 class="bold"><i18n:text>xmlui.dri2xhtml.METS-1.0.item-agrovoc-terms</i18n:text></h5>
                <div>
                    <xsl:for-each select="dim:field[@mdschema='mel' and @element='subject' and @qualifier='agrovoc']">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <!-- extract and strip keyword from mel.keywor.agrovoc -->
                                <xsl:variable name="agrovoc-keyword" select="normalize-space(substring-before(node(), '|'))"/>
                                <!-- extract and strip AGROVOC link from mel.keywor.agrovoc -->
                                <xsl:variable name="agrovoc-link" select="normalize-space(substring-after(node(), '|'))"/>

                                <xsl:call-template name="discovery-link">
                                    <xsl:with-param name="value" select="$agrovoc-keyword"/>
                                    <xsl:with-param name="filtertype" select="'subject'"/>
                                </xsl:call-template>
                                <a target="_blank">
                                    <xsl:attribute name="href" >
                                        <xsl:value-of select="$agrovoc-link"/>
                                    </xsl:attribute>
                                    <img class="agrovoc-image" src="/themes/MELSpace/images/AGROVOC-logo.gif" />
                                </a>

                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@mdschema='mel' and @element='subject' and @qualifier='agrovoc']) != 0">
                            <xsl:text>; </xsl:text>
                        </xsl:if>
                    </xsl:for-each>

                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-file-section">
        <xsl:choose>
            <xsl:when test="//mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL' or @USE='LICENSE']/mets:file">
                <div class="item-page-field-wrapper table word-break">
                    <h5>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-viewOpen</i18n:text>
                    </h5>

                    <xsl:variable name="label-1">
                            <xsl:choose>
                                <xsl:when test="confman:getProperty('mirage2.item-view.bitstream.href.label.1')">
                                    <xsl:value-of select="confman:getProperty('mirage2.item-view.bitstream.href.label.1')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>label</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                    </xsl:variable>

                    <xsl:variable name="label-2">
                            <xsl:choose>
                                <xsl:when test="confman:getProperty('mirage2.item-view.bitstream.href.label.2')">
                                    <xsl:value-of select="confman:getProperty('mirage2.item-view.bitstream.href.label.2')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>title</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                    </xsl:variable>

                    <xsl:for-each select="//mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL' or @USE='LICENSE']/mets:file">
                        <xsl:call-template name="itemSummaryView-DIM-file-section-entry">
                            <xsl:with-param name="href" select="mets:FLocat[@LOCTYPE='URL']/@xlink:href" />
                            <xsl:with-param name="mimetype" select="@MIMETYPE" />
                            <xsl:with-param name="label-1" select="$label-1" />
                            <xsl:with-param name="label-2" select="$label-2" />
                            <xsl:with-param name="title" select="mets:FLocat[@LOCTYPE='URL']/@xlink:title" />
                            <xsl:with-param name="label" select="mets:FLocat[@LOCTYPE='URL']/@xlink:label" />
                            <xsl:with-param name="size" select="@SIZE" />
                        </xsl:call-template>
                    </xsl:for-each>
                </div>
            </xsl:when>
            <!-- Special case for handling ORE resource maps stored as DSpace bitstreams -->
            <xsl:when test="//mets:fileSec/mets:fileGrp[@USE='ORE']">
                <xsl:apply-templates select="//mets:fileSec/mets:fileGrp[@USE='ORE']" mode="itemSummaryView-DIM" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-file-section-entry">
        <xsl:param name="href" />
        <xsl:param name="mimetype" />
        <xsl:param name="label-1" />
        <xsl:param name="label-2" />
        <xsl:param name="title" />
        <xsl:param name="label" />
        <xsl:param name="size" />
        <div>
            <a>
                <xsl:attribute name="href">
                    <xsl:value-of select="$href"/>
                </xsl:attribute>
                <xsl:call-template name="getFileIcon">
                    <xsl:with-param name="mimetype">
                        <xsl:value-of select="substring-before($mimetype,'/')"/>
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="substring-after($mimetype,'/')"/>
                    </xsl:with-param>
                </xsl:call-template>
                <xsl:choose>
                    <xsl:when test="contains($label-1, 'label') and string-length($label)!=0">
                        <xsl:value-of select="$label"/>
                    </xsl:when>
                    <xsl:when test="contains($label-1, 'title') and string-length($title)!=0">
                        <xsl:value-of select="$title"/>
                    </xsl:when>
                    <xsl:when test="contains($label-2, 'label') and string-length($label)!=0">
                        <xsl:value-of select="$label"/>
                    </xsl:when>
                    <xsl:when test="contains($label-2, 'title') and string-length($title)!=0">
                        <xsl:value-of select="$title"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="getFileTypeDesc">
                            <xsl:with-param name="mimetype">
                                <xsl:value-of select="substring-before($mimetype,'/')"/>
                                <xsl:text>/</xsl:text>
                                <xsl:choose>
                                    <xsl:when test="contains($mimetype,';')">
                                        <xsl:value-of select="substring-before(substring-after($mimetype,'/'),';')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="substring-after($mimetype,'/')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> (</xsl:text>
                <xsl:choose>
                    <xsl:when test="$size &lt; 1024">
                        <xsl:value-of select="$size"/>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-bytes</i18n:text>
                    </xsl:when>
                    <xsl:when test="$size &lt; 1024 * 1024">
                        <xsl:value-of select="substring(string($size div 1024),1,5)"/>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-kilobytes</i18n:text>
                    </xsl:when>
                    <xsl:when test="$size &lt; 1024 * 1024 * 1024">
                        <xsl:value-of select="substring(string($size div (1024 * 1024)),1,5)"/>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-megabytes</i18n:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring(string($size div (1024 * 1024 * 1024)),1,5)"/>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-gigabytes</i18n:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>)</xsl:text>
            </a>
        </div>
    </xsl:template>

    <xsl:template match="dim:dim" mode="itemDetailView-DIM">
        <xsl:param name="dspace_item_id"/>
        <xsl:param name="dspace_item_handle"/>
        <input type="hidden" name="dspace_item_id" value="{$dspace_item_id}"/>
        <input type="hidden" name="dspace_item_handle" value="{$dspace_item_handle}"/>
        <xsl:call-template name="itemSummaryView-DIM-title"/>
        <div class="ds-table-responsive">
            <table class="ds-includeSet-table detailtable table table-striped table-hover">
                <xsl:apply-templates mode="itemDetailView-DIM"/>
            </table>
        </div>

        <span class="Z3988">
            <xsl:attribute name="title">
                 <xsl:call-template name="renderCOinS"/>
            </xsl:attribute>
            &#xFEFF; <!-- non-breaking space to force separating the end tag -->
        </span>
        <xsl:copy-of select="$SFXLink" />
    </xsl:template>

    <xsl:template match="dim:field" mode="itemDetailView-DIM">
        <xsl:if test="not((./@mdschema = 'mel' and ./@element = 'ISO3166/MA') or (./@mdschema = 'mel' and ./@element = 'ISO3166-1/ALFA3') or (./@mdschema = 'mel' and ./@element = 'iso3166-1/Numeric') or (./@mdschema = 'mel' and ./@element = 'partner' and ./@qualifier = 'id') or (./@mdschema = 'mel' and ./@element = 'file' and ./@qualifier = 'thumbnail') or (./@mdschema = 'mel' and ./@element = 'date' and ./@qualifier = 'year') or (./@mdschema = 'mel' and ./@element = 'licence' and ./@qualifier = 'image') or (./@mdschema = 'mel' and ./@element = 'contact' and ./@qualifier = 'email') or (./@mdschema = 'mel' and ./@element = 'contact' and ./@qualifier = 'domain') or (./@mdschema = 'mel' and ./@element = 'subject' and ./@qualifier = 'agrovoc'))">
            <xsl:variable name="elementValue" select="./node()"/>
            <xsl:if test="$elementValue != ''">
                <tr>
                    <xsl:attribute name="class">
                        <xsl:text>ds-table-row </xsl:text>
                        <xsl:if test="(position() div 2 mod 2 = 0)">even</xsl:if>
                        <xsl:if test="(position() div 2 mod 2 = 1)">odd</xsl:if>
                    </xsl:attribute>
                    <td class="label-cell">
                        <xsl:value-of select="./@mdschema"/>
                        <xsl:text>.</xsl:text>
                        <xsl:value-of select="./@element"/>
                        <xsl:if test="./@qualifier">
                            <xsl:text>.</xsl:text>
                            <xsl:value-of select="./@qualifier"/>
                        </xsl:if>
                    </td>

                    <td class="word-break">
                        <xsl:copy-of select="./node()"/>
                    </td>
                    <td>
                        <xsl:value-of select="./@language"/>
                    </td>
                </tr>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- don't render the item-view-toggle automatically in the summary view, only when it gets called -->
    <xsl:template match="dri:p[contains(@rend , 'item-view-toggle') and
        (preceding-sibling::dri:referenceSet[@type = 'summaryView'] or following-sibling::dri:referenceSet[@type = 'summaryView'])]">
    </xsl:template>

    <!-- don't render the head on the item view page -->
    <xsl:template match="dri:div[@n='item-view']/dri:head" priority="5">
    </xsl:template>

   <xsl:template match="mets:fileGrp[@USE='CONTENT']">
        <xsl:param name="context"/>
        <xsl:param name="primaryBitstream" select="-1"/>
            <xsl:choose>
                <!-- If one exists and it's of text/html MIME type, only display the primary bitstream -->
                <xsl:when test="mets:file[@ID=$primaryBitstream]/@MIMETYPE='text/html'">
                    <xsl:apply-templates select="mets:file[@ID=$primaryBitstream]">
                        <xsl:with-param name="context" select="$context"/>
                    </xsl:apply-templates>
                </xsl:when>
                <!-- Otherwise, iterate over and display all of them -->
                <xsl:otherwise>
                    <xsl:apply-templates select="mets:file">
                     	<!--Do not sort any more bitstream order can be changed-->
                        <xsl:with-param name="context" select="$context"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
    </xsl:template>

   <xsl:template match="mets:fileGrp[@USE='LICENSE']">
        <xsl:param name="context"/>
        <xsl:param name="primaryBitstream" select="-1"/>
            <xsl:apply-templates select="mets:file">
                        <xsl:with-param name="context" select="$context"/>
            </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="mets:file">
        <xsl:param name="context" select="."/>
        <div class="file-wrapper row">
            <div class="col-xs-6 col-sm-3">
                <div class="thumbnail">
                    <a class="image-link">
                        <xsl:attribute name="href">
                            <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                        </xsl:attribute>
                        <xsl:choose>
                            <xsl:when test="$context/mets:fileSec/mets:fileGrp[@USE='ORIGINAL']/
                        mets:file[@GROUPID=current()/@GROUPID]">
                                <img alt="Thumbnail">
                                    <xsl:attribute name="src">
                                        <xsl:value-of select="$context/mets:fileSec/mets:fileGrp[@USE='ORIGINAL']/
                                    mets:file[@GROUPID=current()/@GROUPID]/mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                                    </xsl:attribute>
                                </img>
                            </xsl:when>
                            <xsl:otherwise>
                                <img alt="Thumbnail">
                                    <xsl:attribute name="data-src">
                                        <xsl:text>holder.js/100%x</xsl:text>
                                        <xsl:value-of select="$thumbnail.maxheight"/>
                                        <xsl:text>/text:No Thumbnail</xsl:text>
                                    </xsl:attribute>
                                </img>
                            </xsl:otherwise>
                        </xsl:choose>
                    </a>
                </div>
            </div>

            <div class="col-xs-6 col-sm-7">
                <dl class="file-metadata dl-horizontal">
                    <dt>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-name</i18n:text>
                        <xsl:text>:</xsl:text>
                    </dt>
                    <dd class="word-break">
                        <xsl:attribute name="title">
                            <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:title"/>
                        </xsl:attribute>
                        <xsl:value-of select="util:shortenString(mets:FLocat[@LOCTYPE='URL']/@xlink:title, 30, 5)"/>
                    </dd>
                <!-- File size always comes in bytes and thus needs conversion -->
                    <dt>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-size</i18n:text>
                        <xsl:text>:</xsl:text>
                    </dt>
                    <dd class="word-break">
                        <xsl:choose>
                            <xsl:when test="@SIZE &lt; 1024">
                                <xsl:value-of select="@SIZE"/>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.size-bytes</i18n:text>
                            </xsl:when>
                            <xsl:when test="@SIZE &lt; 1024 * 1024">
                                <xsl:value-of select="substring(string(@SIZE div 1024),1,5)"/>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.size-kilobytes</i18n:text>
                            </xsl:when>
                            <xsl:when test="@SIZE &lt; 1024 * 1024 * 1024">
                                <xsl:value-of select="substring(string(@SIZE div (1024 * 1024)),1,5)"/>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.size-megabytes</i18n:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="substring(string(@SIZE div (1024 * 1024 * 1024)),1,5)"/>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.size-gigabytes</i18n:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </dd>
                <!-- Lookup File Type description in local messages.xml based on MIME Type.
         In the original DSpace, this would get resolved to an application via
         the Bitstream Registry, but we are constrained by the capabilities of METS
         and can't really pass that info through. -->
                    <dt>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-format</i18n:text>
                        <xsl:text>:</xsl:text>
                    </dt>
                    <dd class="word-break">
                        <xsl:call-template name="getFileTypeDesc">
                            <xsl:with-param name="mimetype">
                                <xsl:value-of select="substring-before(@MIMETYPE,'/')"/>
                                <xsl:text>/</xsl:text>
                                <xsl:choose>
                                    <xsl:when test="contains(@MIMETYPE,';')">
                                <xsl:value-of select="substring-before(substring-after(@MIMETYPE,'/'),';')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="substring-after(@MIMETYPE,'/')"/>
                                    </xsl:otherwise>
                                </xsl:choose>

                            </xsl:with-param>
                        </xsl:call-template>
                    </dd>
                <!-- Display the contents of 'Description' only if bitstream contains a description -->
                <xsl:if test="mets:FLocat[@LOCTYPE='URL']/@xlink:label != ''">
                        <dt>
                            <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-description</i18n:text>
                            <xsl:text>:</xsl:text>
                        </dt>
                        <dd class="word-break">
                            <xsl:attribute name="title">
                                <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:label"/>
                            </xsl:attribute>
                            <xsl:value-of select="util:shortenString(mets:FLocat[@LOCTYPE='URL']/@xlink:label, 30, 5)"/>
                        </dd>
                </xsl:if>
                </dl>
            </div>

            <div class="file-link col-xs-6 col-xs-offset-6 col-sm-2 col-sm-offset-0">
                <xsl:choose>
                    <xsl:when test="@ADMID">
                        <xsl:call-template name="display-rights"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="view-open"/>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
        </div>

</xsl:template>

    <xsl:template name="view-open">
        <a>
            <xsl:attribute name="href">
                <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
            </xsl:attribute>
            <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-viewOpen</i18n:text>
        </a>
    </xsl:template>

    <xsl:template name="display-rights">
        <xsl:variable name="file_id" select="jstring:replaceAll(jstring:replaceAll(string(@ADMID), '_METSRIGHTS', ''), 'rightsMD_', '')"/>
        <xsl:variable name="rights_declaration" select="../../../mets:amdSec/mets:rightsMD[@ID = concat('rightsMD_', $file_id, '_METSRIGHTS')]/mets:mdWrap/mets:xmlData/rights:RightsDeclarationMD"/>
        <xsl:variable name="rights_context" select="$rights_declaration/rights:Context"/>
        <xsl:variable name="users">
            <xsl:for-each select="$rights_declaration/*">
                <xsl:value-of select="rights:UserName"/>
                <xsl:choose>
                    <xsl:when test="rights:UserName/@USERTYPE = 'GROUP'">
                       <xsl:text> (group)</xsl:text>
                    </xsl:when>
                    <xsl:when test="rights:UserName/@USERTYPE = 'INDIVIDUAL'">
                       <xsl:text> (individual)</xsl:text>
                    </xsl:when>
                </xsl:choose>
                <xsl:if test="position() != last()">, </xsl:if>
            </xsl:for-each>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="not ($rights_context/@CONTEXTCLASS = 'GENERAL PUBLIC') and ($rights_context/rights:Permissions/@DISPLAY = 'true')">
                <a href="{mets:FLocat[@LOCTYPE='URL']/@xlink:href}">
                    <img width="64" height="64" src="{concat($theme-path,'/images/Crystal_Clear_action_lock3_64px.png')}" title="Read access available for {$users}"/>
                    <!-- icon source: http://commons.wikimedia.org/wiki/File:Crystal_Clear_action_lock3.png -->
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="view-open"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="getFileIcon">
        <xsl:param name="mimetype"/>
            <i aria-hidden="true">
                <xsl:attribute name="class">
                <xsl:text>glyphicon </xsl:text>
                <xsl:choose>
                    <xsl:when test="contains(mets:FLocat[@LOCTYPE='URL']/@xlink:href,'isAllowed=n')">
                        <xsl:text> glyphicon-lock</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> glyphicon-file</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                </xsl:attribute>
            </i>
        <xsl:text> </xsl:text>
    </xsl:template>

    <!-- Generate the license information from the file section -->
    <xsl:template match="mets:fileGrp[@USE='CC-LICENSE']" mode="simple">
        <li><a href="{mets:file/mets:FLocat[@xlink:title='license_text']/@xlink:href}"><i18n:text>xmlui.dri2xhtml.structural.link_cc</i18n:text></a></li>
    </xsl:template>

    <!-- Generate the license information from the file section -->
    <xsl:template match="mets:fileGrp[@USE='LICENSE']" mode="simple">
        <li><a href="{mets:file/mets:FLocat[@xlink:title='license.txt']/@xlink:href}"><i18n:text>xmlui.dri2xhtml.structural.link_original_license</i18n:text></a></li>
    </xsl:template>

    <!--
    File Type Mapping template

    This maps format MIME Types to human friendly File Type descriptions.
    Essentially, it looks for a corresponding 'key' in your messages.xml of this
    format: xmlui.dri2xhtml.mimetype.{MIME Type}

    (e.g.) <message key="xmlui.dri2xhtml.mimetype.application/pdf">PDF</message>

    If a key is found, the translated value is displayed as the File Type (e.g. PDF)
    If a key is NOT found, the MIME Type is displayed by default (e.g. application/pdf)
    -->
    <xsl:template name="getFileTypeDesc">
        <xsl:param name="mimetype"/>

        <!--Build full key name for MIME type (format: xmlui.dri2xhtml.mimetype.{MIME type})-->
        <xsl:variable name="mimetype-key">xmlui.dri2xhtml.mimetype.<xsl:value-of select='$mimetype'/></xsl:variable>

        <!--Lookup the MIME Type's key in messages.xml language file.  If not found, just display MIME Type-->
        <i18n:text i18n:key="{$mimetype-key}"><xsl:value-of select="$mimetype"/></i18n:text>
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
</xsl:stylesheet>
