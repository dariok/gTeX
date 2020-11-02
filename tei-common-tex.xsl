<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	xmlns:tei="http://www.tei-c.org/ns/1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:hab="http://diglib.hab.de"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:mets="http://www.loc.gov/METS/"
	exclude-result-prefixes="tei" version="3.0"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.w3.org/1999/XSL/Transform http://www.w3.org/2007/schema-for-xslt20.xsd">
	
	<xsl:function name="hab:replaceAll" as="xs:string?">
		<xsl:param name="input" as ="xs:string?" />
		<xsl:param name="find" as="xs:string*" />
		<xsl:param name="repl" as="xs:string*" />
		
		<xsl:sequence select="
			if (count($find) > 0)
			then hab:replaceAll(
				replace($input, $find[1], $repl[1]),
				$find[position() > 1],
				$repl[position() > 1])
			else $input
		" /> 
	</xsl:function>
	
	<xsl:template match="processing-instruction()[name() = 'tex']">
		<xsl:value-of select="." />
	</xsl:template>
	
	<xsl:template match="text() | @*">
		<xsl:variable name="from" select="('#', '&amp;', '%', '_', 'ℂ', '\s{2,}')" />
		<xsl:variable name="to" select="('\\#', '\\&amp;', '\\%', '\\_', '{\\foreign ℂ}', ' ')" />
		<xsl:value-of select="hab:replaceAll(., $from, $to)" />
	</xsl:template>
	
	<xsl:template match="tei:anchor">
		<xsl:choose>
			<xsl:when test="@type">
				<xsl:variable name="ref" select="concat('#', @xml:id)" />
				<xsl:variable name="target" select="//tei:*[@from = $ref or @to = $ref or @corresp = $ref]" />
				<xsl:variable name="type">
					<xsl:value-of select="@type" />
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$type='crit_app' and not(parent::tei:note[@place])">
						<xsl:text>\textsuperscript{\aalph{</xsl:text>
						<xsl:call-template name="makeID">
							<xsl:with-param name="targetElement" select="$target" />
						</xsl:call-template>
						<xsl:text>}}</xsl:text>
					</xsl:when>
					<!-- neu 2016-06-17 DK -->
					<xsl:when test="$type='crit_app' and parent::tei:note[@place]">
						<xsl:text>\habBodyFootmarkA{</xsl:text>
						<xsl:call-template name="makeID">
							<xsl:with-param name="targetElement" select="$target" />
						</xsl:call-template>
						<xsl:text>}</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="makeLabel"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="makeLabel"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- neu 2016-12-13 DK -->
	<xsl:template match="tei:addName">
		<xsl:apply-templates select="text()" />
		<xsl:if test="following-sibling::tei:addName">
			<xsl:text> </xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:bibl | tei:rs[@type = 'bibl']">
		<xsl:if test="not(@ref or @corresp)">\textbf{</xsl:if>
		<xsl:choose>
			<xsl:when test="@rend='Ebd' or @rend='Ebd.'">
				<xsl:text>Ebd</xsl:text>
				<xsl:if test="(text() and not(starts-with(., '.'))) or (not(text())
					and not(starts-with(following-sibling::text()[1], '.')))">
					<xsl:text>.</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:when test="@rend='ebd' or @rend='ebd.'">
				<xsl:text>ebd</xsl:text>
				<xsl:if test="(text() and not(starts-with(., '.'))) or (not(text())
					and not(starts-with(following-sibling::text()[1], '.')))">
					<xsl:text>.</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="ref">
					<xsl:choose>
						<xsl:when test="@ref">
							<xsl:value-of select="substring-after(@ref, '#')" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="substring-after(@corresp, '#')" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:apply-templates select="document('../register/bibliography.xml')/id($ref)/tei:abbr" />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="ends-with(., '.') and following-sibling::*[1][self::tei:ptr[@type='digitalisat' or @type='link']]
				and starts-with(following::text()[1], '.')">
				<xsl:value-of select="substring(., 1, string-length(.) - 1)" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="not(@ref or @corresp)">}</xsl:if>
	</xsl:template>
	
	<!-- \noindent, falls noch Text folgt; 2016-08-29 DK -->
	<!-- es werden keine Anführungszeichen mehr gewüsncht; 2016-09-20 DK -->
	<xsl:template match="tei:cit">
		<xsl:if test="not(ancestor::tei:p)">
			<xsl:text>
\pstart\relax</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="tei:quote" />
		<xsl:apply-templates select="tei:note" />
		<xsl:if test="not(ancestor::tei:p)">
			<xsl:text>\pend</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:emph">
		<xsl:text>\textit{</xsl:text>
		<xsl:apply-templates />
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:ex">
		<xsl:text>[</xsl:text>
		<xsl:apply-templates select="node() | processing-instruction()"/>
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:expan">
		<xsl:apply-templates />
	</xsl:template>
	
	<!-- neu 2016-12-14 DK -->
	<xsl:template match="tei:forename">
		<xsl:apply-templates />
		<xsl:if test="following-sibling::tei:forename">
			<xsl:text> </xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- neue Regelung nach Treffen 2016-02-10: tr immer spitz, intro und FN eckig, außer wenn @reason; 2016-02-12 DK -->
	<xsl:template match="tei:gap">
		<xsl:text>[…]</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:hi | tei:seg[@rend] | tei:ab[@style]">
		<xsl:choose>
			<xsl:when test="@style='font-style: italic;'
				or @rend='italics' or starts-with(@rend, 'i:1;') or starts-with(@style, 'i:1;')">
				<xsl:text>\textit{</xsl:text>
				<xsl:apply-templates />
				<xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:when test="@rend = 'bold' or starts-with(@rend, 'b:1; sz') or starts-with(@style, 'b:1; sz')">
				<xsl:text>\textbf{</xsl:text>
				<xsl:apply-templates />
				<xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:when test="@rend='super'">
				<xsl:text>\textsuperscript{</xsl:text><xsl:apply-templates /><xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:when test="@rend='sub'">
				<xsl:text>\textsubscript{</xsl:text><xsl:apply-templates /><xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@rend, 'b:1; i:1;')">
				<xsl:text>\textbf{\textit{</xsl:text>
				<xsl:apply-templates />
				<xsl:text>}}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Autoren von Sekundärliteratur in kleinen Kapitälchen; 2016-04-26 DK -->
	<xsl:template match="tei:name[parent::tei:abbr]">
		<xsl:if test="ancestor::tei:listBibl[not(@type='primary')]">
			<xsl:text>\textsc{</xsl:text>
		</xsl:if>
		<xsl:value-of select="replace(., '/', '\\slash ')" />
		<xsl:if test="ancestor::tei:listBibl[not(@type='primary')]">
			<xsl:text>}</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:note[not(@type = 'crit_app' or @type = 'comment')]" mode="fnText">
		<xsl:choose>
			<xsl:when test="ancestor::tei:note[@place]" /><!-- Ausgleich in marginFoot zerstört Abstand dahinter -->
			<xsl:when test="ends-with(preceding-sibling::node()[1], '.') or ends-with(preceding-sibling::node()[1], ',')">
				<xsl:text>\kern-0.4pt</xsl:text>
			</xsl:when>
			<xsl:when test="ends-with(preceding-sibling::node()[1][not(
				self::tei:note or self::tei:app)], 'f')">
				<xsl:text>\kern1.25pt</xsl:text>
			</xsl:when>
			<xsl:when test="ends-with(preceding-sibling::node()[1][not(
				self::tei:note or self::tei:app)], 't')">
				<xsl:text>\kern0.5pt</xsl:text>
			</xsl:when>
			<xsl:when test="ends-with(preceding-sibling::node()[1][not(
				self::tei:note or self::tei:app)], 'r')">
				<xsl:text>\kern0.6pt</xsl:text>
			</xsl:when>
			<xsl:when test="ends-with(preceding-sibling::node()[1][not(
				self::tei:note or self::tei:app)], 's')">
				<xsl:text>\kern0.2pt</xsl:text>
			</xsl:when>
			<xsl:when test="ends-with(preceding-sibling::node()[1][not(
				self::tei:note or self::tei:app)], 'i')">
				<xsl:text>\kern0.3pt</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:text>\footnote
    {</xsl:text>
		<!-- parent:: durch ancestor:: ersetzt; 2017-02-03 DK -->
		<xsl:if
			test="@xml:id or ancestor::tei:note[@place = 'margin'] or @corresp or preceding-sibling::*[1][self::tei:seg] 
			or ancestor::tei:opener or ancestor::tei:closer or ancestor::tei:list[not(@rend or @rend = 'inline')]">
			<xsl:call-template name="makeLabel"/>
		</xsl:if>
		<xsl:apply-templates select="node() | processing-instruction()"/>
		<xsl:text>}</xsl:text>
		<!-- neu 2016-12-10 DK -->
		<xsl:if
			test="not(ancestor::tei:note[@place])
			and following-sibling::node()[1][self::text()] and starts-with(following-sibling::text()[1], ' ')">
			<xsl:text>
	</xsl:text>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="ancestor::tei:note[@place]" />
			<xsl:when test="starts-with(following-sibling::node()[1], ',') or starts-with(following-sibling::node()[1], '.')">
				<xsl:text>\kern-0.4pt</xsl:text>
			</xsl:when>
			<xsl:when test="starts-with(following-sibling::node()[1], '/')">
				<xsl:text>\kern-0.6pt</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:ptr[@type='digitalisat']" />
	<xsl:template match="tei:ptr[@type = 'link']">
		<xsl:value-of select="normalize-space(@target)"/>
	</xsl:template>
	<!-- neu 2016-12-15 DK -->
	<xsl:template match="tei:ptr[contains(@subtype, 'bd.')]">
		<xsl:value-of select="@subtype" />
	</xsl:template>
	<!-- TODO diese Funktion generalisieren: /@n oder über /@xml:id oder über mets (@ORDER) -->
	<xsl:template match="tei:ptr[@type='wdb' and not(@cRef or @subtype)]">
		<xsl:variable name="targetFileName">
			<xsl:choose>
				<xsl:when test="starts-with(@target, '#')">
					<xsl:value-of select="base-uri()" />
				</xsl:when>
				<xsl:when test="contains(@target, '#')">
					<xsl:value-of select="substring-before(@target, '#')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@target" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="targetEENumber">
			<xsl:choose>
				<xsl:when test="string-length($targetFileName) &gt; 0">
					<xsl:call-template name="getEENumber">
						<xsl:with-param name="file" select="$targetFileName" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<!-- bei Link in eigener Datei -->
					<xsl:call-template name="getEENumber"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="targetElement">
			<xsl:if test="contains(@target, '#')">
				<xsl:value-of select="substring-after(@target, '#')" />
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="ownEENumber">
			<xsl:call-template name="getEENumber"/>
		</xsl:variable>
		<xsl:variable name="targetID">
			<xsl:choose>
				<xsl:when test="string-length($targetFileName) &gt; 0">
					<xsl:value-of select="document($targetFileName, .)/tei:TEI/@xml:id"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="/tei:TEI/@xml:id" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="chapterID">
			<xsl:call-template name="getChapterID">
				<xsl:with-param name="targetID" select="$targetID" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="reftext">
			<xsl:if test="string-length($targetElement) &gt; 1">
				<xsl:variable name="ref">
					<xsl:choose>
						<!-- Link in andere Datei -->
						<xsl:when test="string-length($targetFileName) &gt; 1">
							<xsl:call-template name="makeID">
								<xsl:with-param name="targetElement" select="document($targetFileName, .)/id($targetElement)" />
							</xsl:call-template>
						</xsl:when>
						<!-- Link in gleiche Datei -->
						<xsl:otherwise>
							<xsl:call-template name="makeID">
								<xsl:with-param name="targetElement" select="id($targetElement)" />
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<xsl:choose>
					<xsl:when test="starts-with($targetElement, 'n')">
						<xsl:text>\noteref{</xsl:text>
						<xsl:value-of select="$ref" />
						<xsl:text>}</xsl:text>
					</xsl:when>
					<xsl:when test="contains($targetFileName, 'intro')">
						<xsl:text>\habPageref{</xsl:text>
						<xsl:value-of select="$ref" />
						<xsl:text>}</xsl:text>
					</xsl:when>
					<!-- neu für kritische Fußnoten; 2016-10-06 DK -->
					<xsl:when test="starts-with($targetElement, 'c')">
						<xsl:text>\habCritNoteRef{</xsl:text>
						<xsl:value-of select="$ref" />
						<xsl:text>}</xsl:text>
					</xsl:when>
					<!-- test 2017-01-02 DK -->
					<xsl:when test="id($targetElement)[self::tei:app]">
						<xsl:text>\aalph{</xsl:text>
						<xsl:value-of select="$ref" />
						<xsl:text>}</xsl:text>
					</xsl:when>
					<xsl:when test="matches($targetElement, '^(q|p|i|hl)\d')">
						<xsl:text>\lineref{</xsl:text>
						<xsl:value-of select="$ref"/>
						<xsl:text>}</xsl:text>
					</xsl:when>
					<xsl:when test="matches($targetElement, 'supp\d')">
						<xsl:text>Beilage</xsl:text>
						<xsl:if test="count(document($targetFileName, .)/tei:TEI/tei:text/tei:body/tei:div[@type='supplement']) &gt; 1">
							<xsl:text> </xsl:text>
							<xsl:value-of select="count(document($targetFileName, .)/tei:TEI/tei:text/tei:body/tei:div[@type='supplement'
								and following-sibling::tei:div[@xml:id=$targetElement]]) + 1"/>
						</xsl:if>
						<!--<xsl:text>, \habPageref{</xsl:text>
						<xsl:value-of select="$ref" />
						<xsl:text>}</xsl:text>-->
					</xsl:when>
					<xsl:when test="matches($targetElement, '^[sd]') or starts-with($targetElement, 'pag')">
						<xsl:text>\habPageref{</xsl:text>
						<xsl:value-of select="$ref" />
						<xsl:text>}</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>\textbf{unbekanntes Verweisziel!}</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="number($targetEENumber) &gt; 143">
				<xsl:text>KGK III, Nr. </xsl:text>
				<xsl:value-of select="$targetEENumber"/>
			</xsl:when>
			<xsl:when test="substring-before(preceding-sibling::tei:ptr[@type = 'wdb'][1]/@target, '#') = $targetFileName">
				<xsl:value-of select="$reftext"/>
			</xsl:when>
			<xsl:when test="number($targetEENumber) &gt; 99">
				<xsl:if test="contains(@target, 'intro')">
					<xsl:text>Einleitung</xsl:text>
				  <xsl:if test="$targetEENumber = $ownEENumber">
				    <xsl:text>, </xsl:text>
				  </xsl:if>
				</xsl:if>
				<xsl:if test="not($targetEENumber = $ownEENumber)">
				  <xsl:if test="contains(@target, 'intro')">
				    <xsl:text> zu </xsl:text>
				  </xsl:if>
					<xsl:text>KGK </xsl:text>
					<xsl:text>\ref{</xsl:text>
					<xsl:value-of select="$chapterID" />
					<xsl:text>}</xsl:text>
					<xsl:if test="string-length($reftext) &gt; 0">
						<xsl:text>, </xsl:text>
					</xsl:if>
				</xsl:if>
				<xsl:value-of select="$reftext"/>
			</xsl:when>
			<xsl:when test="contains(@target, 'personenregister.xml')">
				<xsl:value-of select="$reftext" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>KGK I</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- quote mit @type wird getrennt behandelt; 2016-09-20 DK -->
	<xsl:template match="tei:quote[@type = 'term']">
		<xsl:text>›</xsl:text>
		<xsl:apply-templates />
		<xsl:text>‹</xsl:text>
	</xsl:template>
	<xsl:template match="tei:quote[not(@type)]">
		<xsl:if test="@xml:id">
			<xsl:call-template name="makeLabel" />
		</xsl:if>
		<xsl:text>»</xsl:text>
		<xsl:choose>
			<xsl:when test="@xml:lang='grc-Grek'">
				<xsl:text>\textgreek{</xsl:text><xsl:apply-templates /><xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:when test="@xml:lang='heb-Hebr'">
				<xsl:text>\texthebrew{</xsl:text><xsl:apply-templates /><xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>«</xsl:text>
		<xsl:if test="@xml:id">
			<xsl:call-template name="makeLabel">
				<xsl:with-param name="location">e</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:ref">
		<xsl:text>\url{</xsl:text>
		<xsl:apply-templates />
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<!--<xsl:template match="tei:rs">
		<xsl:apply-templates />
		<xsl:if test="@ref">
			<xsl:variable name="prefix" select="substring-before(@ref, ':')" />
			<xsl:text>\sindex[</xsl:text>
			<xsl:value-of select="$prefix" />
			<xsl:text>]{</xsl:text>
			<xsl:variable name="type">
				<xsl:choose>
					<xsl:when test="$prefix = 'pla'">ort</xsl:when>
					<xsl:when test="$prefix = 'thi'">sache</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="@type"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="json"
				select="json-doc('https://thbw-www.adw.uni-heidelberg.de/api/v1/' || $type || '/' || substring-after(@ref, ':'))"/>
			<xsl:value-of select="$json?long?v"/>
			<xsl:text>}</xsl:text>
		</xsl:if>
	</xsl:template>-->
	
	<xsl:template match="tei:seg[@xml:lang and not(@type)] | tei:term[@xml:lang] | tei:foreign">
		<xsl:apply-templates select="." mode="lang" />
	</xsl:template>
	
	<xsl:template match="tei:term | tei:foreign" mode="lang">
		<xsl:choose>
			<xsl:when test="@xml:lang='grc-Grek'">
				<xsl:text>\textgreek{</xsl:text><xsl:apply-templates /><xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:when test="@xml:lang='heb-Hebr'">
				<xsl:text>\texthebrew{</xsl:text><xsl:apply-templates /><xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:otherwise><xsl:apply-templates /></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- neu 2016-12-17 DK -->
	<xsl:template match="tei:surname">
		<xsl:value-of select="normalize-space()"/>
	</xsl:template>
	
	<xsl:template match="tei:supplied">
		<xsl:text>[</xsl:text>
		<xsl:apply-templates />
		<xsl:text>]</xsl:text>
		<!--<xsl:choose>
			<xsl:when test="@reason">
				<xsl:text>〈</xsl:text>
				<xsl:apply-templates />
				<xsl:text>〉</xsl:text>
			</xsl:when>
			<xsl:when test="@resp">
				<xsl:text>[</xsl:text>
				<xsl:apply-templates/>
				<xsl:text>]</xsl:text>
			</xsl:when>
			<xsl:when test="ends-with(/tei:TEI/@xml:id, 'introduction')">
				<xsl:text>[</xsl:text>
				<xsl:apply-templates />
				<xsl:text>]</xsl:text>
			</xsl:when>
			<xsl:when test="ends-with(/tei:TEI/@xml:id, 'transcript') and not(ancestor::tei:note[@type='footnote'])">
				<xsl:text>〈</xsl:text>
				<xsl:apply-templates />
				<xsl:text>〉</xsl:text>
			</xsl:when>
			<xsl:when test="ends-with(/tei:TEI/@xml:id, 'transcript') and ancestor::tei:note[@type='footnote']">
				<xsl:text>[</xsl:text>
				<xsl:apply-templates />
				<xsl:text>]</xsl:text>
			</xsl:when>
		</xsl:choose>-->
	</xsl:template>
	
	<xsl:template match="tei:table">
		<xsl:text>\microtypesetup{protrusion=false}
\begin{tabularx}{\textwidth}{@{}|d|s|s|s|@{}|}</xsl:text>
<!--		<xsl:sequence select="for $i in (1 to @cols) return 'l|'"/>-->
<!--		<xsl:text>@{}}</xsl:text>-->
		<xsl:text>
  \hline\rowcolor{lightgray}</xsl:text>
		<xsl:apply-templates />
		<xsl:text>\hline</xsl:text>
		<xsl:text>\end{tabularx}\microtypesetup{protrusion=true}</xsl:text>
	</xsl:template>
	<xsl:template match="tei:row">
		<xsl:if test="not(following-sibling::tei:row)">
			<xsl:text>\rowcolor{lightgray}</xsl:text>
		</xsl:if>
		<xsl:apply-templates/>
		<!--<xsl:if test="following-sibling::tei:row">-->
			<xsl:text>\\
  </xsl:text>
		<!--</xsl:if>-->
		<xsl:if test="tei:cell[@cols]">
			<xsl:text>\tabuphantomline </xsl:text>
		</xsl:if>
		<!--<xsl:if test="@role='label' or not(preceding-sibling::tei:row)">
			<xsl:text>\hline</xsl:text>
		</xsl:if>-->
		<xsl:if test="following-sibling::tei:row">
			<xsl:text>\hline</xsl:text>
		</xsl:if>
		<xsl:text>
		</xsl:text>
	</xsl:template>
	<xsl:template match="tei:cell">
		<xsl:if test="preceding-sibling::tei:cell">
			<xsl:text>&amp; </xsl:text>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="@rows">
				<xsl:text> \multirow{</xsl:text>
				<xsl:value-of select="@rows"/>
				<xsl:text>}{*}{</xsl:text>
				<xsl:apply-templates/>
				<xsl:text>} </xsl:text>
			</xsl:when>
			<xsl:when test="@cols">
				<xsl:text>\multicolumn2{l}{</xsl:text>
				<xsl:apply-templates />
				<xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="parent::tei:row/@role='label'">
					<xsl:text>\textit{</xsl:text>
				</xsl:if>
				<xsl:apply-templates/>
				<xsl:if test="parent::tei:row/@role='label'">
					<xsl:text>}</xsl:text>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:title[parent::tei:p or parent::tei:note]">
		<xsl:text>\textit{</xsl:text>
		<xsl:apply-templates />
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:idno[starts-with(@type, 'vd')]">
		<xsl:choose>
			<xsl:when test="@type='vd16'">
				<xsl:text>VD 16 </xsl:text>
				<xsl:apply-templates />
			</xsl:when>
			<xsl:when test="@type='vd17'">
				<xsl:text>VD17: </xsl:text>
				<xsl:apply-templates />
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:list">
		<xsl:text>
\begin{</xsl:text>
		<xsl:choose>
			<xsl:when test="@type = 'ordered'">
				<xsl:text>enumerate</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>itemize</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>}</xsl:text>
		<xsl:text>[topsep=2pt,itemsep=-1ex]</xsl:text>
		<xsl:apply-templates />
		<xsl:text>
\end{</xsl:text>
		<xsl:choose>
			<xsl:when test="@type = 'ordered'">
				<xsl:text>enumerate</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>itemize</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>}</xsl:text>
	</xsl:template>
	<xsl:template match="tei:item">
		<xsl:text>
	\item{</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<!-- neu 2016-06-16 DK -->
	<xsl:template match="tei:listBibl[@type='primary']//tei:abbr/tei:title">
		<xsl:text>\textit{</xsl:text>
		<xsl:apply-templates />
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:term[not(@xml:lang)]">
		<xsl:text>›</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>‹</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:unclear[text()]">
		<xsl:text>[</xsl:text>
		<xsl:apply-templates />
		<xsl:text>]</xsl:text>
	</xsl:template>
	<xsl:template match="tei:unclear">
		<xsl:text>\footnotetextA
    {</xsl:text>
		<xsl:apply-templates select="@place" />
		<xsl:apply-templates select="@extent" />
		<xsl:text>unleserlich.}</xsl:text>
	</xsl:template>
	
	<xsl:template name="makeID">
		<xsl:param name="targetElement"/>
		<xsl:param name="id" />
		
		<xsl:choose>
			<xsl:when test="$targetElement">
				<xsl:value-of select="hab:generateID($targetElement, '')" />
			</xsl:when>
			<xsl:when test="$id">
				<xsl:value-of select="hab:generateID(current(), $id)" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="hab:generateID(current(), '')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:function name="hab:generateID">
		<xsl:param name="target" as="node()" />
		<xsl:param name="pos" as="xs:string?" />
		
		<xsl:variable name="idVal">
			<xsl:choose>
				<xsl:when test="$pos">
<!--					<xsl:value-of select="string-length($pos) &gt; 0" />-->
					<xsl:value-of select="$pos"/>
				</xsl:when>
				<xsl:when test="$target/@xml:id">
					<xsl:value-of select="translate($target/@xml:id, '_', '-')" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="generate-id($target)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="concat(translate($target/ancestor::tei:TEI/@xml:id, '_', '-'), '-', $idVal)"/>
	</xsl:function>
	
	<xsl:template name="getEENumber">
		<xsl:param name="file" as="xs:string?" />
		
		<xsl:variable name="elemTEI" as="node()">
			<xsl:choose>
				<xsl:when test="string-length($file) &gt; 0">
					<xsl:choose>
						<xsl:when test="doc-available($file) or document($file, current())//tei:TEI">
							<xsl:sequence select="document($file, current())//tei:TEI" />
						</xsl:when>
						<xsl:otherwise><xsl:value-of select="$file" /></xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:sequence select="document(base-uri(), current())//tei:TEI" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$elemTEI/@n" />
		<!--<xsl:choose>
			<xsl:when test="$elemTEI/@n">
				<xsl:value-of select="$elemTEI/@n" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="metsStruct" select="document($metsFile)/mets:mets/mets:structMap"/>
				<xsl:choose>
					<xsl:when test="$metsStruct//mets:div[descendant::mets:filePtr[@FILEID=$elemTEI/@xml:id]]/@ORDER">
						<xsl:value-of select="$metsStruct//mets:div[descendant::mets:filePtr[@FILEID=$elemTEI/@xml:id]]/@ORDER" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$elemTEI/@xml:id"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>-->
	</xsl:template>
	
	<xsl:template name="makeLabel">
		<xsl:param name="location" select="''"/>
		<xsl:param name="elem" select="''"/>
		<xsl:param name="targetElement" />
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="$targetElement">
					<xsl:value-of select="hab:generateID($targetElement, '')" />
				</xsl:when>
				<xsl:when test="string-length($elem) &gt; 0">
					<xsl:value-of select="hab:generateID(current(), $elem)" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="hab:generateID(., '')" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- edlabel sollte nicht in Fußnoten stehen, da sonst die Zählung durcheinander kommt; 2016-05-03 DK -->
		<!-- kein edlabel in krit. FN: ebenfalls Probleme für Zählung -->
		<xsl:if test="(matches(current()/@xml:id, '^[qip]') or starts-with(@xml:id, 'supp'))
			and contains(ancestor::tei:TEI/@xml:id, 'transcr')">
			<xsl:text>&#x200B;\edlabel{</xsl:text>
			<xsl:value-of select="concat($id, $location)" />
			<xsl:text>}</xsl:text>
		</xsl:if>
		<xsl:text>\label{</xsl:text>
		<xsl:value-of select="concat($id, $location)" />
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template name="getChapterID">
		<xsl:param name="targetID" />
		
		<xsl:choose>
			<xsl:when test="contains($targetID, '_introduction')">
				<xsl:value-of select="substring-before($targetID, '_introduction')" />
			</xsl:when>
			<xsl:when test="contains($targetID, '_transcript')">
				<xsl:value-of select="substring-before($targetID, '_transcript')" />
			</xsl:when>
			<xsl:when test="contains($targetID, '_einleitung')">
				<xsl:value-of select="substring-before($targetID, '_einleitung')" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$targetID" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="makeName">
		<!--<xsl:param name="entry" />
		<xsl:param name="ref" />
		<!-\-<xsl:variable name="node"
			select="(document('../register/personenregister.xml')/id($entry)/tei:persName[@type = 'index' or not(@type)])[1]" />-\->
		<xsl:choose>
			<!-\- besondere Abkürzungen -\->
			<xsl:when test="$entry = 'Ov.'">Ovid</xsl:when>
			<xsl:when test="$entry = 'Hom.'">Homer</xsl:when>
			<xsl:when test="$entry = 'Arist.'">Aristoteles</xsl:when>
			<xsl:when test="$entry = 'Hier.'">Hieronymus</xsl:when>
			<xsl:when test="$entry = 'Suet.'">Sueton</xsl:when>
			<xsl:when test="$entry = 'Quint.'">Quintilian</xsl:when>
			<xsl:when test="$entry = 'Hor.'">Horaz</xsl:when>
			<xsl:when test="$entry = 'Plin.'">Plinius</xsl:when>
			<xsl:when test="$entry = 'Verg.'">Vergilius, Polydorus</xsl:when>
			<xsl:when test="$entry = 'Aug.'">Augustinus</xsl:when>
			<xsl:when test="$entry = 'Ps. Aug.'">Ps. Augustin</xsl:when>
			<xsl:when test="$entry = 'Thomas'">Thomas von Aquin</xsl:when>
			<xsl:when test="$entry = 'Bern.'">Bernhard von Clairvaux</xsl:when>
			<xsl:when test="$entry = 'Prosp.'">Prosper von Aquitanien</xsl:when>
			<xsl:when test="$entry = 'Plat.'">Platon</xsl:when>
			<xsl:when test="$entry = 'Ambr.'">Ambrosius</xsl:when>
			<xsl:when test="$entry = 'Ambrosiast.'">Ambrosiaster</xsl:when>
			<xsl:when test="$entry = 'Cic.'">Cicero, Marcus Tullius</xsl:when>
			<xsl:when test="$entry = 'Erasmus'">Erasmus von Rotterdam</xsl:when>
			<xsl:when test="$entry = 'Lucil.'">Lucilius, Gaius</xsl:when>
			<xsl:when test="$entry = 'Macr.'">Macobius Ambrosius Theodosius</xsl:when>
			<xsl:when test="$entry = 'Tert.'">Tertullian</xsl:when>
			<xsl:when test="$entry = 'Val.'">Valerius Maximus</xsl:when>
			<xsl:when test="$entry = 'Petr. Lomb.'">Petrus Lombardus</xsl:when>
			<xsl:when test="$entry = 'Ockham'">Wilhelm von Ockham</xsl:when>
			<xsl:when test="$entry = 'Phaedr.'">Phaedrus</xsl:when>
			<xsl:when test="$entry = 'Cypr.'">Cyprian</xsl:when>
			<xsl:when test="$entry = 'Plaut.'">Plautus</xsl:when>
			<xsl:when test="$entry = 'Biel, Gabriel'">Biel, Gabriel</xsl:when>
			<xsl:when test="$entry = 'Bonav.'">Bonaventura</xsl:when>
			<xsl:when test="$entry = 'Oros.'">Orosius</xsl:when>
			<xsl:when test="$entry = 'Scotus'">Duns Scotus, Johannes</xsl:when>
			<xsl:when test="$entry = 'Fulg. Rusp.'">Fulgentius von Ruspe</xsl:when>
			<xsl:when test="$entry = 'Boeth.'">Boethius</xsl:when>
			<xsl:when test="$entry = 'Cassiod.'">Cassiodorus, Flavius Magnus Aurelius</xsl:when>
			<xsl:when test="$entry = 'Cassian.'">Cassianus, Johannes</xsl:when>
			<xsl:when test="$entry = 'Chrys.'">Chrysostomos</xsl:when>
			<xsl:when test="$entry = 'Cyr.'">Cyrill</xsl:when>
			<xsl:when test="$entry = 'Dion.'">Dionysius Areopagita</xsl:when>
			<xsl:when test="$entry = 'Gell.'">Gellius, Aulus</xsl:when>
			<xsl:when test="$entry = 'Greg.'">Gregor I., der Große</xsl:when>
			<xsl:when test="$entry = 'Hil.'">Hilarius von Poitiers</xsl:when>
			<xsl:when test="$entry = 'Capreolus'">Johannes Capreolus</xsl:when>
			<xsl:when test="$entry = 'Gennad.'">Ps. Augustin</xsl:when>
			<xsl:when test="$entry = 'Nemes.'">Ps. Gregorius Nyssenus</xsl:when>
			<xsl:when test="$entry = 'Ockham'">Wilhelm von Ockham</xsl:when>
			<xsl:when test="$entry = 'Or.'">Origenes</xsl:when>
			<xsl:when test="$entry = 'Paul.'">Paulinus von Nola</xsl:when>
			<xsl:when test="$entry = 'Pelag.'">Ps. Hieronymus</xsl:when>
			<xsl:when test="$entry = 'Ps. Hier.'">Ps. Hieronymus</xsl:when>
			<xsl:when test="$entry = 'Prosp.' and $ref = ('resp. ad Gall.', 'sent.')">Ps. Augustin</xsl:when>
			<xsl:when test="$entry = 'Prosp.' and $ref = ('vocat. gent.')">Ps. Ambrosius</xsl:when>
			<xsl:when test="$entry = 'Scotus'">Duns Scotus, Johannes</xsl:when>
			<xsl:when test="$entry = 'Suet.'">Suetonius Tranquillus, Gaius</xsl:when>
			<xsl:when test="$entry = 'Iuv.'">Iuvenal</xsl:when>
			<xsl:when test="$entry = 'Liv.'">Livius</xsl:when>
			<xsl:when test="$entry = 'Mart.'">Martial</xsl:when>
			<xsl:when test="not($node)">
				<xsl:value-of select="$entry"/>
				<xsl:text>?</xsl:text>
			</xsl:when>
			<xsl:when test="$node/following-sibling::tei:persName[@type='index']">
				<xsl:apply-templates select="$node/following-sibling::tei:persName[@type='index'][1]" />
			</xsl:when>
			<xsl:when test="$node/tei:surname and $node/tei:forename">
				<!-\- erweitert um ggfs. vorhandene lat. Cognomina; 2016-12-13 DK -\->
				<xsl:apply-templates select="$node/tei:surname" />
				<xsl:if test="$node/tei:addName[@type='cognomen']">
					<xsl:text> </xsl:text>
					<xsl:apply-templates select="$node/tei:addName[@type='cognomen']"/>
				</xsl:if>
				<xsl:text>, </xsl:text>
				<xsl:apply-templates select="$node/tei:forename" />
				<xsl:if test="$node/tei:nameLink">
					<xsl:value-of select="concat(' ', $node/tei:nameLink)" />
				</xsl:if>
				<xsl:apply-templates select="$node/tei:roleName" mode="index" />
			</xsl:when>
			<xsl:when test="$node/tei:forename and $node/tei:addName">
				<xsl:value-of select="string-join($node/tei:forename | $node/tei:addName, ' ')" />
				<xsl:apply-templates select="$node/tei:roleName" mode="index" />
			</xsl:when>
			<!-\- neu 2017-01-05 DK -\->
			<xsl:when test="$node/tei:name and $node/tei:addName">
				<xsl:value-of select="concat($node/tei:name, ' ', $node/tei:addName)"/>
				<xsl:apply-templates select="$node/tei:roleName" mode="index" />
			</xsl:when>
			<!-\- Päpste, Kaiser und Vergleichbare; 2016-10-04 DK -\->
			<xsl:when test="$node/tei:name and $node/tei:genName and ($node/tei:roleName or $node/tei:addName)">
				<xsl:value-of select="$node/tei:name" />
				<xsl:text> </xsl:text>
				<xsl:value-of select="$node/tei:genName" />
				<!-\- neu 2016-12-14 DK -\->
				<xsl:if test="$node/tei:genName and $node/tei:addName">
					<xsl:text>,</xsl:text>
				</xsl:if>
				<xsl:if test="$node/tei:addName">
					<xsl:text> </xsl:text>
					<xsl:value-of select="$node/tei:addName"/>
				</xsl:if>
				<xsl:apply-templates select="$node/tei:roleName" mode="index" />
			</xsl:when>
			<xsl:when test="$node/tei:name">
				<xsl:value-of select="$node/tei:name" />
				<xsl:apply-templates select="$node/tei:roleName" mode="index" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="normalize-space($node)"/>
			</xsl:otherwise>
			<!-\-<xsl:otherwise>
				<xsl:text>(\</xsl:text>
				<xsl:value-of select="@ref" />
				<xsl:text>)</xsl:text>
			</xsl:otherwise>-\->
		</xsl:choose>-->
	</xsl:template>
	<xsl:template match="tei:roleName" mode="index">
		<xsl:text> (</xsl:text>
		<xsl:apply-templates />
		<xsl:text>)</xsl:text>
	</xsl:template>
</xsl:stylesheet>
