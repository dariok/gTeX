<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	exclude-result-prefixes="tei" version="3.0">
	<!-- Gemeinsame templates importieren. Dies betrifft: text(), @*, ptr, rs, term -->
	<xsl:import href="tei-common-tex.xsl"/>
	<xsl:output method="text" encoding="UTF-8"/>
	
	<xsl:param name="orig" select="false()" />
	
	<xsl:param name="dir">.</xsl:param>
	
	<xsl:template match="tei:teiHeader">
		<xsl:apply-templates select="tei:fileDesc/tei:titleStmt" />
	</xsl:template>
	<xsl:template match="tei:titleStmt">
		<xsl:apply-templates select="tei:title" />
		<xsl:text>
\author{</xsl:text>
		<xsl:apply-templates select="tei:author" />
		<xsl:text>}</xsl:text>
		<xsl:text>
\maketitle
</xsl:text>
	</xsl:template>
	<xsl:template match="tei:titleStmt/tei:title">
		<xsl:choose>
			<xsl:when test="@type = 'main'">
				<xsl:text>
\title{</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>
\subtitle{</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates />
		<xsl:text>}</xsl:text>
	</xsl:template>
	<xsl:template match="tei:titleStmt/tei:author">
		<xsl:if test="preceding-sibling::tei:author">
			<xsl:text>\and </xsl:text>
		</xsl:if>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="tei:add[not(ancestor::tei:note[@place = 'margin']
			or ancestor::tei:list[not(@rend = 'inline')]
			or parent::tei:rdg)]">
		<xsl:choose>
			<xsl:when test="(count(text()) &gt; 1 or contains(text()[1], ' '))
				and not(parent::tei:lem)">
				<xsl:apply-templates select="." mode="fnText"/>
				<xsl:apply-templates select="node()[not(self::tei:note[@type = 'comment'])]"/>
				<xsl:text>\habBodyFootmarkA{</xsl:text>
				<xsl:call-template name="makeID">
					<xsl:with-param name="targetElement" select="."/>
				</xsl:call-template>
				<xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:when test="count(tei:*) = 1 and tei:del">
				<xsl:apply-templates select="." mode="fnText"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="node()[not(self::tei:note[@type = 'comment'])]"/>
				<xsl:apply-templates select="." mode="fnText"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template
		match="tei:add[(ancestor::tei:note[@place = 'margin'] or ancestor::tei:list[not(@rend = 'inline')])
			and not(parent::tei:rdg)]">
		<xsl:variable name="mark" select="if (ancestor::tei:note[@place = 'margin']) then 'Margin' else 'Body'" />
		<xsl:if test="matches(., '\s')">
			<xsl:value-of select="'\hab' || $mark || 'FootmarkA{'" />
			<xsl:call-template name="makeID"/>
			<xsl:text>}</xsl:text>
		</xsl:if>
		<xsl:apply-templates />
		<xsl:value-of select="'\hab' || $mark || 'FootmarkA{'" />
		<xsl:call-template name="makeID"/>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:add" mode="fnText">
		<xsl:if test="ends-with(preceding-sibling::node()[1], '.') or ends-with(preceding-sibling::node()[1], ',')">
			<xsl:text>\kern-0.4pt</xsl:text>
		</xsl:if>
		<xsl:text>\footnotetextA</xsl:text>
		<xsl:if test="count(text()) &gt; 1 or contains(., ' ')">
			<xsl:text>[1]</xsl:text>
		</xsl:if>
		<xsl:text>
    {</xsl:text>
		<xsl:apply-templates select="." mode="fn" />
		<xsl:text>}</xsl:text>
		<xsl:if test="starts-with(following-sibling::node()[1][self::text()], ',')
			or starts-with(following-sibling::node()[1][self::text()], '.')
			or following-sibling::node()[1][self::tei:w] = ','">
			<xsl:text>\kern-0.4pt</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:add" mode="fn">
		<xsl:if test="((ancestor::tei:note[@place] or ancestor::tei:list) and not(ancestor::tei:app))
			or matches(., '\s')">
			<xsl:call-template name="makeLabel" />
		</xsl:if>
		<xsl:apply-templates select="@place" />
		<xsl:apply-templates select="@hand" />
		<xsl:choose>
			<xsl:when test="parent::tei:subst and ancestor::tei:rdg">
				<xsl:text>korr. aus: </xsl:text>
				<xsl:apply-templates select="parent::tei:subst/tei:del" mode="fn" />
			</xsl:when>
			<xsl:when test="parent::tei:subst and parent::*/tei:del = ''">
				<xsl:text>im Wort korr.</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:subst and not(@*)">
				<xsl:text>im Wort korr. aus: </xsl:text>
				<xsl:apply-templates select="parent::tei:subst/tei:del" mode="fn" />
			</xsl:when>
			<xsl:when test="parent::tei:subst and ancestor::tei:lem">
				<xsl:text>für gestr.: </xsl:text>
				<xsl:apply-templates select="parent::tei:subst/tei:del" mode="fn" />
			</xsl:when>
			<xsl:when test="parent::tei:subst">
				<xsl:text>für gestr.: </xsl:text>
				<xsl:apply-templates select="parent::tei:subst/tei:del" mode="fn" />
			</xsl:when>
		</xsl:choose>
		<xsl:if test="not(ancestor::tei:app)">
			<xsl:text>.</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- nicht in den bekannten Ausnahmen Marginalie, Liste, opener oder closer; 2016-10-28 DK -->
	<xsl:template match="tei:app[not(ancestor::tei:note[@place = 'margin']
    or ancestor::tei:titlePart[@rendition])]">
		<xsl:choose>
			<xsl:when test="tei:lem">
				<xsl:choose>
					<!-- contains → matches für alle Whitespaces; 2016-05-09 DK -->
					<!--<xsl:when test="tei:lem/tei:subst and matches(tei:lem//tei:add, '.*\s.*')">
						<xsl:apply-templates select="." mode="fnText"/>
						<xsl:apply-templates select="tei:lem/tei:add"/>
						<xsl:text>\habBodyFootmarkA{</xsl:text>
						<xsl:call-template name="makeID">
							<xsl:with-param name="targetElement" select="."/>
						</xsl:call-template>
						<xsl:text>}</xsl:text>
					</xsl:when>-->
					<xsl:when test="tei:lem/tei:subst">
						<xsl:apply-templates select="tei:lem//tei:add/node()" />
						<xsl:apply-templates select="." mode="fnText" />
					</xsl:when>
					<xsl:when test="matches(tei:lem[not(tei:subst)], '.*\s.*')">
						<xsl:apply-templates select="." mode="fnText"/>
						<xsl:apply-templates select="tei:lem"/>
						<xsl:text>\habBodyFootmarkA{</xsl:text>
						<xsl:call-template name="makeID">
							<xsl:with-param name="targetElement" select="."/>
						</xsl:call-template>
						<xsl:text>}</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="tei:lem"/>
						<xsl:apply-templates select="." mode="fnText"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="fnText"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- neu 2016-10-28 DK -->
	<xsl:template match="tei:app[ancestor::tei:note[@place = 'margin']
    or ancestor::tei:titlePart[@rendition]]">
		<xsl:variable name="mark" select="if (ancestor::tei:note[@place = 'margin']) then 'Margin' else 'Body'" />
		<xsl:if test="matches(tei:lem, '.*\s.*')">
			<xsl:value-of select="'\hab' || $mark || 'FootmarkA{'" />
			<xsl:call-template name="makeID">
				<xsl:with-param name="targetElement" select="."/>
			</xsl:call-template>
			<xsl:text>}</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="tei:lem"/>
		<xsl:value-of select="'\hab' || $mark || 'FootmarkA{'" />
		<xsl:call-template name="makeID"/>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:app" mode="fnText">
		<xsl:if test="ends-with(preceding-sibling::node()[1], '.') or ends-with(preceding-sibling::node()[1], ',')">
			<xsl:text>\kern-0.4pt</xsl:text>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="tei:lem/tei:subst and matches(tei:lem//tei:add, '.*\s.*')">
				<xsl:text>\footnotetextA[1]
    {</xsl:text>
			</xsl:when>
			<xsl:when test="matches(tei:lem[not(tei:subst)], '.*\s.*')">
				<xsl:text>\footnotetextA[1]
    {</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:sic"/>
			<xsl:otherwise>
				<xsl:text>\footnotetextA
    {</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates select="." mode="fn" />
		<xsl:text>}</xsl:text>
		<xsl:if test="starts-with(following-sibling::node()[1][self::text()], ',')
			or starts-with(following-sibling::node()[1][self::text()], '.')
			or following-sibling::node()[1][self::tei:w] = ','">
			<xsl:text>\kern-0.4pt</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:app" mode="fn">
		<xsl:if test="ancestor::tei:note[@place = 'margin'] or matches(tei:lem, '(\s)') or ancestor::tei:opener
			or ancestor::tei:closer or ancestor::tei:item[parent::tei:list[not(@rend or @rend = 'inline')]]
			or @xml:id">
			<xsl:call-template name="makeLabel">
				<xsl:with-param name="targetElement" select="."/>
			</xsl:call-template>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="tei:lem/@resp">
				<xsl:text>konj. für </xsl:text>
			</xsl:when>
			<xsl:when test="tei:lem/tei:subst">
				<xsl:apply-templates select="tei:lem//tei:add" mode="fn" />
				<xsl:text> </xsl:text>
				<xsl:apply-templates select="tei:lem/@wit" />
				<xsl:text>; </xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="tei:lem/@wit"/>
				<xsl:text>; </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates select="tei:rdg" mode="fnText" />
		<xsl:if test="tei:note[@type = 'comment']">
			<xsl:text> – </xsl:text>
			<xsl:apply-templates select="tei:note"/>
		</xsl:if>
		<xsl:text>.</xsl:text>
	</xsl:template>
	
	<!-- neu 2016-12-12 DK -->
	<xsl:template match="tei:rdg" mode="fnText">
		<xsl:choose>
			<xsl:when test="normalize-space() = '' and not(tei:del or tei:add)">
				<xsl:text>fehlt </xsl:text>
				<xsl:apply-templates select="@wit" />
			</xsl:when>
			<xsl:when test="tei:del">
				<xsl:text>in </xsl:text>
				<xsl:apply-templates select="@wit" />
				<xsl:text> </xsl:text>
				<xsl:apply-templates select="tei:del/@rend" />
				<xsl:text>gestr.: </xsl:text>
				<xsl:apply-templates select="tei:del" mode="fn" />
			</xsl:when>
			<xsl:when test="tei:subst">
				<xsl:text>in </xsl:text>
				<xsl:apply-templates select="@wit" />
				<xsl:text> </xsl:text>
				<xsl:choose>
					<xsl:when test="tei:subst/tei:add = preceding-sibling::tei:lem">
						<xsl:text>korr. aus: </xsl:text>
						<xsl:apply-templates select="tei:subst/tei:del" mode="fn" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>korr. zu: </xsl:text>
						<xsl:apply-templates select="tei:subst/tei:add/node()" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="tei:add = preceding-sibling::tei:lem">
				<xsl:apply-templates select="tei:add" mode="fn"/>
			</xsl:when>
			<xsl:when test="tei:add">
				<xsl:text>\textit{</xsl:text>
				<xsl:apply-templates select="tei:add/node()" />
				<xsl:text>} </xsl:text>
				<xsl:apply-templates select="tei:add/@place" />
				<xsl:apply-templates select="tei:add/@hand" />
				<xsl:apply-templates select="@wit" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>\textit{</xsl:text>
				<xsl:apply-templates />
				<xsl:text>} </xsl:text>
				<xsl:apply-templates select="@wit" />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates select="tei:note" />
		<xsl:if test="following-sibling::*">
			<xsl:text>; </xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- die Ausnahmen explizit; 2016-10-28 DK -->
	<xsl:template match="tei:choice[not(ancestor::tei:note[@place = 'margin'])]">
		<xsl:choose>
			<xsl:when test="(count(tei:corr/text()) &gt; 1 and not(tei:corr/tei:lb))
				or contains(tei:corr/text()[1], ' ')">
				<xsl:apply-templates select="." mode="fnText"/>
				<xsl:apply-templates select="tei:ref"/>
				<xsl:apply-templates select="tei:ex"/>
				<xsl:apply-templates select="tei:expan"/>
				<!-- nur corr[not(@type)] ausgeben für mehrfache Korrekturen an einer Stelle; 2016-03-23 DK -->
				<xsl:apply-templates select="tei:corr[not(@type)]"/>
				<xsl:text>\textsuperscript{\aalph{</xsl:text>
				<xsl:call-template name="makeID">
					<xsl:with-param name="targetElement" select="."/>
				</xsl:call-template>
				<xsl:text>}}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="tei:ref"/>
				<xsl:apply-templates select="tei:ex"/>
				<xsl:apply-templates select="tei:expan"/>
				<xsl:apply-templates select="tei:corr"/>
				<xsl:apply-templates select="." mode="fnText"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- nur choice und die üblichen Ausnahmen; 2016-10-28 DK -->
	<xsl:template match="tei:choice[ancestor::tei:note[@place = 'margin']]">
		<xsl:variable name="mark" select="if (ancestor::tei:note[@place = 'margin']) then 'Margin' else 'Body'" />
		<xsl:if test="matches(tei:corr, '.*\s.*')">
			<xsl:value-of select="'\hab' || $mark || 'FootmarkA{'" />
			<xsl:call-template name="makeID">
				<xsl:with-param name="targetElement" select="."/>
			</xsl:call-template>
			<xsl:text>}</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="tei:ref"/>
		<xsl:apply-templates select="tei:ex"/>
		<xsl:apply-templates select="tei:expan"/>
		<xsl:apply-templates select="tei:corr"/>
		<xsl:apply-templates select="tei:lem"/>
		<xsl:value-of select="'\hab' || $mark || 'FootmarkA{'" />
		<xsl:call-template name="makeID">
			<xsl:with-param name="targetElement" select="."/>
		</xsl:call-template>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:choice" mode="fnText">
		<xsl:text>\footnotetextA
    {</xsl:text>
		<xsl:if test="ancestor::tei:note[@place]">
			<xsl:call-template name="makeLabel" />
		</xsl:if>
		<xsl:apply-templates select="tei:corr/@source | tei:corr/@resp" />
		<xsl:text>konj. für: </xsl:text>
		<xsl:apply-templates select="tei:sic" mode="fn" />
		<xsl:text>.}</xsl:text>
	</xsl:template>
	
	<xsl:template
		match="tei:closer">
		<xsl:text>\vspace{0.5\baselineskip}
\pstart\noindent\skipnumbering{\textit{Zeitgenössische Notiz:}}\\\noindent </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>\pend</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:corr[@cert = 'low']">
		<xsl:text>〈</xsl:text>
		<xsl:apply-templates select="node()[not(self::tei:note[@type = 'comment'])]"/>
		<xsl:text>〉</xsl:text>
	</xsl:template>
	<xsl:template match="tei:corr[not(@cert = 'low')]">
		<xsl:apply-templates select="node()[not(self::tei:note[@type = 'comment'])]"/>
	</xsl:template>
	<xsl:template match="tei:del[parent::tei:app]">
		<xsl:text>\textit{</xsl:text>
		<xsl:choose>
			<xsl:when test="@type = 'omitted'">fehlt</xsl:when>
			<xsl:when test="@type = 'missing'">gestrichen</xsl:when>
			<xsl:otherwise>fehlt</xsl:otherwise>
		</xsl:choose>
		<xsl:text> }</xsl:text>
		<xsl:value-of select="normalize-space()"/>
		<xsl:text>.</xsl:text>
	</xsl:template>
	<!-- Konflikt beseitigt; 2016-12-07 DK -->
	<xsl:template match="tei:del[parent::tei:subst and not(ancestor::tei:note)]"/>
	<!-- die üblichen Ausnahmen ergänzt; 2016-10-28 DK -->
	<xsl:template
		match="tei:del[not(ancestor::tei:app or parent::tei:subst
		or (ancestor::tei:note[@place = 'margin'] or ancestor::tei:list[not(@rend = 'inline')]))]">
		<!-- ausgelagert wg. Aufruf aus Marginalie; 2016-06-17 DK -->
		<xsl:apply-templates select="." mode="fnText"/>
	</xsl:template>
	<xsl:template match="tei:del | tei:sic" mode="fn">
		<xsl:text>\textit{</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template
		match="tei:del[(ancestor::tei:note[@place = 'margin']
		or ancestor::tei:list[not(@rend = 'inline')])
		and not(parent::tei:subst)]">
		<xsl:text>\habMarginFootmarkA{</xsl:text>
		<xsl:call-template name="makeID">
			<xsl:with-param name="targetElement" select="."/>
		</xsl:call-template>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:del" mode="fnText">
		<xsl:text>\footnotetextA
    {</xsl:text>
		<xsl:apply-templates select="@rend" />
		<xsl:apply-templates select="@hand" />
		<xsl:apply-templates select="@extent" />
		<xsl:text>gestr.</xsl:text>
		<xsl:if test="text()">
			<xsl:text>: </xsl:text>
			<xsl:apply-templates select="." mode="fn"/>
			<xsl:if test="not(ancestor::tei:subst)">
				<xsl:text>.</xsl:text>
			</xsl:if>
		</xsl:if>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<!-- @type='supplement' entfernt wg. Konformität zu structMD; 2016-03-18 DK -->
	<xsl:template match="tei:body/tei:div">
		<!--<xsl:choose>
			<xsl:when test="tei:div">
				<xsl:text>\vspace{\baselineskip}</xsl:text>
			</xsl:when>
			<xsl:when test="preceding-sibling::tei:*">
				<xsl:text>\vspace{0.5\baselineskip}</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:call-template name="makeLabel"/>-->
		<xsl:apply-templates />
		<!--<xsl:call-template name="makeLabel">
			<xsl:with-param name="location" select="'e'"/>
		</xsl:call-template>-->
	</xsl:template>
	<!--<xsl:template match="tei:div/tei:div">
		<xsl:text>\vspace{0.5\baselineskip}</xsl:text>
		<xsl:apply-templates />
	</xsl:template>-->
	
	<xsl:template match="tei:front">
		<xsl:apply-templates select="tei:div" />
		<xsl:text>\vspace{0.5\baselineskip}</xsl:text>
	</xsl:template>
	<xsl:template match="tei:front/tei:div[normalize-space() != '']">
		<xsl:text>
\frontinfo{</xsl:text>
		<xsl:choose>
			<xsl:when test="@type = 'regest'">Regest</xsl:when>
			<xsl:when test="@type = 'vorlage'">
				<xsl:text>Textvorlage</xsl:text>
				<xsl:if test="descendant::tei:lb">
					<xsl:text>n</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:when test="@type = 'edition'">
				<xsl:text>Edition</xsl:text>
				<xsl:if test="descendant::tei:lb">
					<xsl:text>en</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:when test="@type = 'ueberlieferung'">Weitere Überlieferung</xsl:when>
		</xsl:choose>
		<xsl:text>}{</xsl:text>
		<xsl:apply-templates select="tei:p/node()" />
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<!-- neu 2016-06-08 DK -->
	<xsl:template match="tei:docTitle">
		<xsl:apply-templates/>
		<xsl:text>\vspace{\baselineskip}</xsl:text>
	</xsl:template>
	<!-- neu 2016-06-13 DK -->
	<!-- auskommentiert: kann identisch titlePart bearbeitet werden; 2016-08-01 DK -->
	<!--	<xsl:template match="tei:docAuthor">
		<xsl:text>
\pstart\noindent </xsl:text>
		<xsl:apply-templates />
		<xsl:text>\pend</xsl:text>
	</xsl:template>-->
	<!-- neu als Ersatz für reines hi[@rend='italics']; 2016-05-09 DK -->
	<xsl:template match="tei:emph">
		<xsl:text>\textit{</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>}</xsl:text>
	</xsl:template>
	<!-- neu für Sprachangaben zum ganzen Text; 2016-10-10 DK -->
	<xsl:template match="tei:text[@xml:lang]">
		<xsl:choose>
			<xsl:when test="@xml:lang = 'lat'">
				<xsl:text>\begin{latin}</xsl:text>
				<xsl:apply-templates/>
				<xsl:text>\end{latin}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- neu für komplexe Titel wie in 002; 2016-06-07 DK -->
	<xsl:template match="tei:titlePage//tei:epigraph">
		<xsl:if test="preceding-sibling::tei:epigraph and not(tei:label)">
			<xsl:text>\vspace{0.5\baselineskip}</xsl:text>
		</xsl:if>
		<xsl:apply-templates/>
	</xsl:template>
	<!--<!-\- nach front darf eine ganze Leerzeile stehen; 2016-05-13 DK -\->
	<!-\- vielleicht besser nicht; 2016-05-13 DK -\->
	<!-\- nehmen wir eine dreiviertel Leerzeile; 2016-08-25 DK -\->
	<xsl:template match="tei:front">
		<xsl:apply-templates/>
		<!-\-<xsl:if test="not(tei:div or descendant::tei:docTitle) or not(following::tei:div[1][tei:head])">
			<xsl:text>\vspace{\baselineskip}</xsl:text>
		</xsl:if>-\->
	</xsl:template>-->
	
	<xsl:template match="tei:fw"/>
	<xsl:template match="tei:g"/>
	
	<xsl:template match="tei:head[ancestor::tei:TEI/@n = '103']">
		<xsl:text>\\
\pagebreak[1]\vspace{1\baselineskip plus 0.25\baselineskip minus 0.25\baselineskip}%
\begin{center}\noindent 
		</xsl:text>
		<xsl:if test="@xml:id">
			<xsl:call-template name="makeLabel"/>
		</xsl:if>
		<xsl:apply-templates/>
		<xsl:if test="@xml:id">
			<xsl:call-template name="makeLabel">
				<xsl:with-param name="location">e</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:text>
\end{center}
		</xsl:text>
	</xsl:template>
	<xsl:template match="tei:head[not(ancestor::tei:TEI/@n = '103')]">
		<xsl:choose>
			<xsl:when test="parent::tei:div[@type = 'subsection']">
				<xsl:text>
\subhead</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<!-- zwischen zwei gleichrangigen Überschriften kein voller Abstand; 2016-09-20 DK -->
				<!-- eine halbe Zeile ist ggf. besser; 2017-01-09 DK -->
				<xsl:if test="preceding-sibling::*[1][self::tei:head]">
					<xsl:text>\vspace{-0.5\baselineskip}</xsl:text>
				</xsl:if>
				<xsl:text>
\head</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if
			test="preceding-sibling::*[1][self::tei:pb]
			or (preceding-sibling::*[1][self::tei:note[@place = 'margin']] and preceding-sibling::*[2][self::tei:pb])">
			<xsl:text>[</xsl:text>
			<xsl:call-template name="makeFolio">
				<xsl:with-param name="fol">
					<xsl:value-of select="preceding::tei:pb[1]/@n"/>
				</xsl:with-param>
			</xsl:call-template>
			<xsl:text>]</xsl:text>
		</xsl:if>
		<xsl:text>{</xsl:text>
		<xsl:if test="@xml:id">
			<xsl:call-template name="makeLabel"/>
		</xsl:if>
		<xsl:if test="(@rend = 'inline' or @place = 'margin') and (contains(., ' ') or contains(., '&#x09;'))">
			<xsl:text>\textsuperscript{\aalph{</xsl:text>
			<xsl:call-template name="makeID"/>
			<xsl:text>}}</xsl:text>
		</xsl:if>
		<xsl:apply-templates/>
		<!--<xsl:if test="following-sibling::*[1][self::tei:head]">
			<xsl:text>\\ </xsl:text>
			<xsl:apply-templates select="following-sibling::*[1]/node()"/>
		</xsl:if>-->
		<xsl:if test="@rend = 'inline'">
			<xsl:text>\footnotetextA[1]{</xsl:text>
			<xsl:call-template name="makeLabel"/>
			<xsl:text>\textit{im Original im fortlaufenden Text}}</xsl:text>
		</xsl:if>
		<xsl:if test="@place = 'margin'">
			<xsl:text>\footnotetextA[1]{</xsl:text>
			<xsl:call-template name="makeLabel"/>
			<xsl:text>\textit{im Original am Rand.}}</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="preceding-sibling::tei:note[@place = 'margin']"/>
		<xsl:if test="@xml:id">
			<xsl:call-template name="makeLabel">
				<xsl:with-param name="location">e</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:label">
		<xsl:if test="not(preceding-sibling::*[1][self::tei:list])">
			<xsl:text>\\\noindent</xsl:text>
		</xsl:if>
		<xsl:text>\vspace{0.25\baselineskip}
\textbf{\textit{</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>}}</xsl:text>
	</xsl:template>
	<!-- exklusion unter epigraph eingefügt; 2016-06-07 DK -->
	<xsl:template match="tei:label[@rend and not(parent::tei:epigraph)]">
		<!--<xsl:text>\hspace{2mm}-\-\-\hspace{2mm}</xsl:text>-->
		<xsl:text>\hfill </xsl:text>
		<xsl:apply-templates/>
	</xsl:template>
	<!-- neu für komplexe Titelseiten; 2016-06-07 DK -->
	<xsl:template match="tei:epigraph/tei:label">
		<xsl:if test="@xml:id">
			<xsl:call-template name="makeLabel"/>
		</xsl:if>
		<xsl:text>
\head{</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:l">
		<xsl:apply-templates/>
		<xsl:if test="following-sibling::tei:l">
			<xsl:text>&amp;
		</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:lb">
		<xsl:choose>
			<xsl:when test="ancestor::tei:front
				and not(preceding-sibling::* or preceding-sibling::text()[normalize-space() != ''])" />
			<xsl:when test="ancestor::tei:cell">
				<xsl:text>\linebreak </xsl:text>
			</xsl:when>
			<xsl:when test="ancestor::tei:front">
				<xsl:text>; </xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>\\
      </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:lg">
		<xsl:if test="parent::tei:p and preceding-sibling::*">
			<xsl:text>\pend</xsl:text>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="@rend">
				<xsl:text>
		\setstanzaindents{0,</xsl:text>
				<xsl:value-of select="@rend"/>
				<xsl:text>}\setcounter{stanzaindentsrepetition}{</xsl:text>
				<xsl:value-of select="count(tokenize(@rend, ','))"/>
				<xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>
		\setstanzaindents{0,1}\setcounter{stanzaindentsrepetition}{1}</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<!-- auch nicht direkt nach label; 2016-06-08 DK -->
		<xsl:if test="not(parent::tei:epigraph/preceding-sibling::*[1][self::tei:head] or preceding-sibling::tei:label)">
			<xsl:text>\vspace{0.5\baselineskip}</xsl:text>
		</xsl:if>
		<xsl:text>\stanza
		</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>\&amp;</xsl:text>
		<!-- auch kein weiterer, wenn danach wieder ein label kommt; 2016-06-08 DK -->
		<xsl:if
			test="not(parent::tei:epigraph/following-sibling::*[1][self::tei:head]
			or parent::tei:epigraph/following-sibling::*[1][self::tei:epigraph[tei:label]])">
			<xsl:text>\vspace{0.5\baselineskip}</xsl:text>
		</xsl:if>
		<xsl:if test="parent::tei:p and following-sibling::*">
			<xsl:text>
\pstart\noindent </xsl:text>
		</xsl:if>
	</xsl:template>
	<!-- Liste nach common ausgelagert; 2016-11-04 DK -->
	<xsl:template match="tei:list[@rend = 'continuous_text']">
		<xsl:if test="not(parent::tei:p)">
			<xsl:text>
\pstart </xsl:text>
		</xsl:if>
		<xsl:for-each select="tei:item">
			<xsl:apply-templates/>
			<xsl:text> </xsl:text>
		</xsl:for-each>
		<xsl:if test="not(parent::tei:p)">
			<xsl:text>\pend</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:note[@place = 'margin']">
		<xsl:text>\marginalie
    {</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>}</xsl:text>
		<xsl:if test="descendant::tei:note or descendant::tei:app or descendant::tei:choice or descendant::tei:del
			or descendant::tei:span or descendant::tei:subst or descendant::tei:seg">
			<xsl:text>\begin{marginFoot}</xsl:text>
			<!-- auch tei:subst/tei:add verarbeiten; 2016-10-11 DK -->
			<!-- muß hier descendant:: sein, falls z.B. ein rs oder ähnliches da ist; 2017-01-19 DK -->
			<xsl:apply-templates select="descendant::tei:note[not(@type = 'comment')]
				| descendant::tei:app[not(ancestor::tei:choice)]
				| descendant::tei:choice
				| descendant::tei:del[not(parent::tei:subst or ancestor::tei:app)] | tei:span | tei:seg
				| descendant::tei:add[not(ancestor::tei:app)]"
				mode="fnText"/>
			<xsl:text>\end{marginFoot}</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:note[@type = 'comment']">
		<xsl:text> — </xsl:text>
		<xsl:if test="@xml:id or @corresp">
			<xsl:call-template name="makeLabel"/>
		</xsl:if>
		<xsl:apply-templates select="node() | processing-instruction()"/>
	</xsl:template>
	
	<!-- nicht in Listen, opener oder closer; 2010-10-28 DK -->
	<!-- bei inline oder hängender closer genauso anwenden, wie in entsprechenden openern; 2017-01-02 DK -->
	<xsl:template match="tei:note[@type = 'footnote' and not(ancestor::tei:note[@place = 'margin']
		or ancestor::tei:titlePart[@rendition])]">
		<xsl:apply-templates select="." mode="fnText"/>
	</xsl:template>
	
	<!-- neu für note in opener; 2016-08-29 DK -->
	<!-- außer hanging oder inline-opener; 2016-10-24 DK -->
	<!-- auch in Listen; 2016-10-28 DK -->
	<!-- Aufruf jetzt der spezielle Befehl \bodyrefB; 2010-10-28 DK -->
	<!-- wieder rückgängig: marginFootMark verhindert Probleme mit Zeilenabstand; 2016-12-10 DK -->
	<!-- in \habCloser bringt sie aber Probleme, daher werden opener und closer getrennt behandelt; 2016-12-14 DK -->
	<!-- nicht in Listen; diese vertragen das andere besser; 2016-12-19 DK -->
	<xsl:template
		match="tei:note[@type = 'footnote' and ancestor::tei:note[@place = 'margin']]">
		<xsl:text>\marginFootMark{</xsl:text>
		<xsl:call-template name="makeID"/>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<!-- neu, da marginFootMark in \habCloser problematisch ist; 2016-12-14 DK -->
	<!-- und auch in Listen; 2016-12-19 DK -->
	<!-- closer wie opener: hanging oder inline nicht hier; 2017-01-01 DK -->
	<xsl:template match="tei:note[@type='footnote'
		and (ancestor::tei:label[parent::tei:list])]">
		<xsl:text>\bodyrefB{</xsl:text>
		<xsl:call-template name="makeID" />
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<!-- Anwendungsbereich auf opener und closer erweitert; 2016-10-27 DK -->
	<!-- auch nicht in Listen; 2016-10-28 DK -->
	<xsl:template
		match="tei:note[@type = 'crit_app' and (parent::tei:note[@place = 'margin']
		or ancestor::tei:list[not(@rend = 'inline')])]">
		<xsl:if test="ends-with(preceding-sibling::node()[1], '.') or ends-with(preceding-sibling::node()[1], ',')">
			<xsl:text>\kern-0.4pt</xsl:text>
		</xsl:if>
		<xsl:text>\habMarginFootmarkA{</xsl:text>
		<xsl:call-template name="makeID">
			<xsl:with-param name="id"/>
		</xsl:call-template>
		<xsl:text>}</xsl:text>
		<xsl:if test="starts-with(following-sibling::node()[1][self::text()], ',') or following-sibling::node()[1][self::tei:w] = ','">
			<xsl:text>\kern-0.4pt</xsl:text>
		</xsl:if>
	</xsl:template>
	<!-- nicht bei opener oder closer; 2016-10-27 DK -->
	<!-- auch nicht in Listen; 2016-10-28 DK -->
	<xsl:template
		match="tei:note[@type = 'crit_app'
		and not(parent::tei:note[@place = 'margin'] or ancestor::tei:list[not(@rend = 'inline')])]">
		<xsl:apply-templates select="." mode="fnText"/>
	</xsl:template>
	<xsl:template match="tei:note[@type = 'crit_app']" mode="fnText">
		<xsl:if test="ends-with(preceding-sibling::node()[1], '.') or ends-with(preceding-sibling::node()[1], ',')">
			<xsl:text>\kern-0.4pt</xsl:text>
		</xsl:if>
		<xsl:text>\footnotetextA</xsl:text>
		<xsl:if test="@corresp">
			<xsl:text>[1]</xsl:text>
		</xsl:if>
		<xsl:text>
    {</xsl:text>
		<xsl:if
			test="parent::tei:note[@place = 'margin']
			or ancestor::tei:list
			or preceding-sibling::*[1][self::tei:seg] or @xml:id or @corresp">
			<xsl:call-template name="makeLabel"/>
		</xsl:if>
		<xsl:apply-templates/>
		<xsl:if test="not(matches(., '[.!?]$'))">
			<xsl:text>!</xsl:text>
		</xsl:if>
		<xsl:text>}</xsl:text>
		<xsl:if test="starts-with(following-sibling::node()[1][self::text()], ',')
			or starts-with(following-sibling::node()[1][self::text()], '.')
			or following-sibling::node()[1][self::tei:w] = ','">
			<xsl:text>\kern-0.4pt</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="tei:note[@type = 'annotation']">
		<xsl:text>\footnoteB
		{</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:opener">
		<xsl:if test="preceding-sibling::*">
			<xsl:text>\vspace{0.5\baselineskip}</xsl:text>
		</xsl:if>
		<xsl:text>
\pstart\noindent </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>\pend</xsl:text>
		<xsl:if test="following-sibling::*[1][self::tei:salute or self::tei:p]">
			<xsl:text>\vspace{0.5\baselineskip}</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:orig[ancestor::tei:note or ancestor::tei:span]">
		<xsl:text>{\normalfont </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:p[ancestor::tei:front]">
		<xsl:text>\par </xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	<xsl:template match="tei:p">
		<xsl:choose>
			<xsl:when test="contains(@style, 'Heading1;')">
				<xsl:text>
\section{</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@style, 'Heading2;')">
				<xsl:text>
\subsection{</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@style, 'Heading3;')">
				<xsl:text>
\subsubsection{</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@style, 'Heading4;')">
				<xsl:text>
\paragraph{</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@style, 'Heading5;')">
				<xsl:text>
\subparagraph{</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>
\par\relax{</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:call-template name="makeLabel"/>
		<xsl:apply-templates select="*" />
		<xsl:call-template name="makeLabel">
			<xsl:with-param name="location">e</xsl:with-param>
		</xsl:call-template>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<!-- neu 2016-09-21 -->
	<xsl:template match="tei:postscript">
		<xsl:text>
\vspace{1.5\baselineskip}</xsl:text>
		<!-- label erzeugen, falls nötig; 2017-01-17 DK -->
		<xsl:if test="@xml:id">
			<xsl:call-template name="makeLabel"/>
		</xsl:if>
		<xsl:apply-templates/>
		<xsl:if test="@xml:id">
			<xsl:call-template name="makeLabel">
				<xsl:with-param name="location">e</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<!-- neu für zentrierte kurze Zitate ohne Abstände (046 A3r); 2016-09-20 DK -->
	<xsl:template match="tei:quote[@type = 'motto']">
		<xsl:text>\habMotto{</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:salute[not(parent::tei:opener or parent::tei:closer or @rend = 'inline')]">
		<xsl:text>
		\pstart\noindent</xsl:text>
		<xsl:if test="@xml:id">
			<xsl:call-template name="makeLabel" />
		</xsl:if>
		<xsl:apply-templates />
		<xsl:if test="@xml:id">
			<xsl:call-template name="makeLabel">
				<xsl:with-param name="location">e</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:text>\pend</xsl:text>
		<!-- wenn salute direkt bei einer Widmung steht, vollen Abstand davor; 2017-01-12 DK -->
		<xsl:choose>
			<xsl:when test="parent::tei:div and not(preceding-sibling::*)">
				<xsl:text>\vspace{0.5\baselineskip}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>\vspace{\baselineskip}</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- neu 2016-10-24; DK -->
	<xsl:template match="tei:salute[@rend = 'inline']"/>
	<!-- nachgetragen 2016-10-16; DK -->
	<xsl:template match="tei:salute[@rend = 'inline']" mode="long">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="tei:seg[@hand and not(ancestor::tei:note[@place])]">
		<xsl:apply-templates select="." mode="fnText" />
		<xsl:apply-templates />
		<xsl:text>\habBodyFootmarkA{</xsl:text>
		<xsl:call-template name="makeID" />
		<xsl:text>}</xsl:text>
	</xsl:template>
	<xsl:template match="tei:seg[@hand and ancestor::tei:note[@place]]">
		<xsl:text>\habMarginFootmarkA{</xsl:text>
		<xsl:call-template name="makeID" />
		<xsl:text>}</xsl:text>
		<xsl:apply-templates />
		<xsl:text>\habMarginFootmarkA{</xsl:text>
		<xsl:call-template name="makeID" />
		<xsl:text>}</xsl:text>
	</xsl:template>
	<xsl:template match="tei:seg" mode="fnText">
		<xsl:text>\footnotetextA[1]
    {</xsl:text>
		<xsl:call-template name="makeLabel" />
		<xsl:apply-templates select="@hand" />
		<xsl:text>.}</xsl:text>
	</xsl:template>
	
	<!-- tei:sic mit tei:app ohne tei:lem sind vom Autor korrigierte Zählungen, deren Original ausgegeben werden soll.
		Auf Wunsch UB (EE 044B) hinzugefügt 2016-02-03 DK -->
	<xsl:template match="tei:sic[not(parent::tei:choice or ancestor::tei:app)]">
		<xsl:apply-templates/>
		<xsl:text>(!)</xsl:text>
	</xsl:template>
	
	<!-- neu für Anmerkungen über beliebige Stellen; 2016-02-16 DK -->
	<!-- auf die üblichen Ausnahmen erweiter; 2016-10-28 DK -->
	<xsl:template
		match="tei:span[not((ancestor::tei:note[@place = 'margin']
		or ancestor::tei:list[not(@rend = 'inline')]))]">
		<xsl:text>\begin{marginFoot}</xsl:text>
		<!-- ausgelagert nach mode="fnText" für spans in margine; 2016-06-17 DK -->
		<xsl:apply-templates select="." mode="fnText"/>
		<xsl:text>\end{marginFoot}</xsl:text>
	</xsl:template>
	
	<!-- neu 2016-06-17 DK -->
	<!-- auf die üblichen Ausnahen erweitert; 2016-10-28 DK -->
	<xsl:template match="tei:span[(ancestor::tei:note[@place = 'margin']
		or ancestor::tei:list[not(@rend = 'inline')])]"/>
	<xsl:template match="tei:span" mode="fnText">
		<xsl:text>\footnotetextA[1]{</xsl:text>
		<xsl:call-template name="makeLabel"/>
		<xsl:choose>
			<xsl:when test="tei:app">
				<xsl:apply-templates select="tei:app/tei:rdg" mode="fnText" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>.}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:subst">
		<xsl:apply-templates select="tei:add" />
	</xsl:template>
	<!-- neu 2017-03-02 DK -->
	<!--<xsl:template match="tei:subst[parent::tei:note[@place='margin']]">
		<xsl:apply-templates select="tei:add" />
		<xsl:text>\habMarginFootmarkA{</xsl:text>
		<xsl:call-template name="makeID" />
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:subst">
		<xsl:apply-templates select="tei:add" />
		<xsl:apply-templates select="." mode="fnText" />
	</xsl:template>
	
	<xsl:template match="tei:subst" mode="fnText">
		<xsl:if test="ends-with(preceding-sibling::node()[1], '.') or ends-with(preceding-sibling::node()[1], ',')">
			<xsl:text>\kern-0.4pt</xsl:text>
		</xsl:if>
		<xsl:text>\footnotetextA
    {</xsl:text>
		<xsl:apply-templates select="." mode="fn" />
		<xsl:text>}</xsl:text>
		<xsl:if test="starts-with(following-sibling::node()[1][self::text()], ',')
			or starts-with(following-sibling::node()[1][self::text()], '.')
			or following-sibling::node()[1][self::tei:w] = ','">
			<xsl:text>\kern-0.4pt</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="tei:subst" mode="fn">
		<xsl:if test="parent::tei:note[@place]">
			<xsl:call-template name="makeLabel" />
		</xsl:if>
		<xsl:apply-templates select="tei:add/@place" />
		<xsl:apply-templates select="tei:add/@hand" />
		<xsl:text>korr. aus: </xsl:text>
		<xsl:if test="ancestor::tei:app">
			<xsl:text>\textit{</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="tei:del/node()" />
		<xsl:if test="ancestor::tei:app">
			<xsl:text>}</xsl:text>
		</xsl:if>
	</xsl:template>-->
	
	<!-- neu für Titelseiten von Drucken; 2016-04-20 DK -->
	<!-- Abstand zwischen zwei titlePart; 2016-05-13 DK -->
	<!-- @rend= durch contains() ersetzt; 2016-06-07 DK -->
	<xsl:template match="tei:titlePart | tei:docAuthor">
		<xsl:if test="preceding-sibling::tei:titlePart">
			<xsl:text>\vspace{0.5\baselineskip}</xsl:text>
		</xsl:if>
		<xsl:text>
	\pstart\noindent</xsl:text>
		<xsl:choose>
			<xsl:when test="contains(@rend, 'align:right')">
				<xsl:text>\begin{flushright}</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@rend, 'align:center')">
				<xsl:text>{\centering </xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text> </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates/>
		<xsl:choose>
			<xsl:when test="contains(@rend, 'align:right')">
				<xsl:text>\end{flushright}</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@rend, 'align:center')">
				<xsl:text>
	
	}</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:text>\pend</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:w[not(ancestor::tei:TEI/@n = '103')]">
		<xsl:apply-templates/>
		<!-- neu 2016-12-10 DK -->
		<xsl:if test="following-sibling::node()[1][self::text()] and starts-with(following-sibling::text()[1], ' ')">
			<xsl:text>
	</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="@xml:id">
		<xsl:call-template name="makeLabel">
			<xsl:with-param name="targetElement" select="parent::*" />
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="@wit">
		<xsl:variable name="lwit" select="//tei:listWit"/>
		<xsl:for-each select="tokenize(normalize-space(), '#')">
			<xsl:variable name="id" select="normalize-space(current())"/>
			<xsl:choose>
				<xsl:when test="position() = 1"/>
				<xsl:when test="$id = 'WA' or $id = 'EA'">
					<xsl:value-of select="$id" />
				</xsl:when>
				<xsl:when test="$lwit/id($id)/text()[not(normalize-space() = '')]">
					<xsl:apply-templates select="$lwit/id($id)" />
				</xsl:when>
				<xsl:when test="string-length($id) &gt; 1">
					<xsl:value-of select="substring($id, 1, 1)"/>
					<xsl:text>\textsubscript{</xsl:text>
					<xsl:value-of select="substring($id, 2)"/>
					<xsl:text>}</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$id"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="not(position() = last() or position() = 1)">
				<xsl:text>, </xsl:text>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="@place">
		<xsl:choose>
			<xsl:when test=". = ('above', 'supralinear')">über der Zeile</xsl:when>
			<xsl:when test=". = 'below'">unter der Zeile</xsl:when>
			<xsl:when test=". = 'top'">am Seitenanfang</xsl:when>
			<xsl:when test=". = 'bottom'">am Seitenende</xsl:when>
			<xsl:when test=". = 'margin'">am Rand</xsl:when>
			<xsl:when test=". = 'inline'">im Wortzwischenraum</xsl:when>
			<xsl:when test=". = 'after'">danach</xsl:when>
			<xsl:when test=". = 'before'">davor</xsl:when>
			<xsl:otherwise>\textbf{<xsl:value-of select="."/>}</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="parent::*[@hand or *] or ancestor::tei:subst">
			<xsl:text> </xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="@rend">
		<xsl:choose>
			<xsl:when test=". = 'after'">danach</xsl:when>
			<xsl:when test=". = 'before'">davor</xsl:when>
			<xsl:otherwise>\textbf{<xsl:value-of select="."/>}</xsl:otherwise>
		</xsl:choose>
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="@extent">
		<xsl:choose>
			<xsl:when test=". = 'word'">ein Wort</xsl:when>
			<xsl:when test=". = 'words'">Wörter</xsl:when>
			<xsl:when test=". = 'letter'">ein Buchstabe</xsl:when>
			<xsl:when test=". = 'letters'">Buchstaben</xsl:when>
			<xsl:otherwise>\textbf{<xsl:value-of select="."/>}</xsl:otherwise>
		</xsl:choose>
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="@cause">
		<xsl:choose>
			<xsl:when test=". = 'manualCorrection'">hsl.</xsl:when>
		</xsl:choose>
		<xsl:text> </xsl:text>
	</xsl:template>
	<xsl:template match="@cert">
		<xsl:text> (?)</xsl:text>
	</xsl:template>
	
	<xsl:template match="@hand">
		<xsl:choose>
			<xsl:when test=". = 'other'">
				<xsl:text>von anderer Hand</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:seg">
				<xsl:text>von </xsl:text>
				<xsl:value-of select="." />
				<xsl:choose>
					<xsl:when test="ends-with(., 's')">
						<xsl:text>’</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>s</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text> Hand</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>von </xsl:text>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="ancestor::tei:subst or parent::tei:del[@rend] or ancestor::tei:rdg">
			<xsl:text> </xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="@source">
		<xsl:text>in </xsl:text>
		<xsl:value-of select="." />
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:front//text()[following-sibling::node()[1][self::tei:lb]]">
		<xsl:choose>
			<xsl:when test="ends-with(., '.')">
				<xsl:value-of select="substring(., string-length() - 1)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="tei:body//text()[following-sibling::node()[1][self::tei:note[@place]]]">
		<xsl:choose>
			<xsl:when test="ends-with(., ' ')">
				<xsl:value-of select="substring(., string-length() - 1)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- named Templates -->
	<xsl:template name="makeFolio">
		<xsl:param name="fol"/>
		<xsl:choose>
			<!-- falls in @n bereits Klammern gesetzt sind; 2016-04-20 DK -->
			<xsl:when test="starts-with($fol, '[')">
				<xsl:variable name="text">
					<xsl:value-of select="substring-after(substring-before($fol, ']'), '[')"/>
				</xsl:variable>
				<xsl:call-template name="replaceRV">
					<xsl:with-param name="string" select="$text"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="contains($fol, '[')">
				<xsl:variable name="vorne">
					<xsl:value-of select="normalize-space(tokenize($fol, '\[')[1])"/>
				</xsl:variable>
				<xsl:variable name="hinten">
					<!-- ich nehme jetzt einfach an, daß nie [ alleine steht -->
					<xsl:value-of select="normalize-space(substring-before(tokenize($fol, '\[')[2], ']'))"/>
				</xsl:variable>
				<xsl:variable name="replVorne">
					<xsl:choose>
						<xsl:when test="ends-with($vorne, 'r') or ends-with($vorne, 'v')">
							<xsl:call-template name="replaceRV">
								<xsl:with-param name="string">
									<xsl:value-of select="$vorne"/>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$vorne"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="replHinten">
					<xsl:choose>
						<xsl:when test="ends-with($hinten, 'r') or ends-with($hinten, 'v')">
							<xsl:call-template name="replaceRV">
								<xsl:with-param name="string">
									<xsl:value-of select="$hinten"/>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$hinten"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:value-of select="concat($replVorne, ' {[', $replHinten, ']}')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="ends-with($fol, 'r') or ends-with($fol, 'v')">
						<xsl:call-template name="replaceRV">
							<xsl:with-param name="string">
								<xsl:value-of select="$fol"/>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$fol"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="replaceRV">
		<xsl:param name="string"/>
		<xsl:value-of select="concat(substring($string, 1, string-length($string) - 1),
			replace(replace(substring($string, string-length($string)),
			'r', '\\textsuperscript{r}'), 'v', '\\textsuperscript{v}'))"
		/>
	</xsl:template>
	
	<!-- für das XSpec -->
	<xsl:template match="tei:listWit" mode="fnText" />
</xsl:stylesheet>
