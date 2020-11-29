<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:gtex="https://github.com/dariok/gTeX"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="tei" version="3.0">
  <!-- Gemeinsame templates importieren. Dies betrifft: text(), @*, ptr, rs, term -->
  
  <xsl:output method="text" encoding="UTF-8"/>
  
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
  
  <xsl:template match="tei:head">
        <xsl:text>
\head{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:note">
    <xsl:text>\footnote
    {</xsl:text>
    <xsl:apply-templates select="*" />
    <xsl:text>}</xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:p[not(@rendition)]">
    <xsl:apply-templates select="@style" />
    <xsl:text>\par\relax </xsl:text>
    <xsl:call-template name="makeLabel"/>
    <xsl:apply-templates select="*" />
    <xsl:call-template name="makeLabel">
      <xsl:with-param name="location">e</xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="tei:p/@style">
    <xsl:choose>
      <xsl:when test="contains(., 'bold')">
        <xsl:text>
\beforeBoldParagraph{}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="tei:p[@rendition]">
    <xsl:text>
</xsl:text>
    <xsl:choose>
      <xsl:when test="@rendition = 'Heading1'">
        <xsl:text>
\beforeSectionHeading{}\section{</xsl:text>
      </xsl:when>
      <xsl:when test="@rendition = 'Heading2'">
        <xsl:text>
\beforeSubsectionHeading{}\subsection{</xsl:text>
      </xsl:when>
      <xsl:when test="@rendition = 'Heading3'">
        <xsl:text>
\beforeSubsubsectionHeading{}\subsubsection{</xsl:text>
      </xsl:when>
      <xsl:when test="@rendition = 'Heading4'">
        <xsl:text>
\beforeParagraphHeading{}\paragraph{</xsl:text>
      </xsl:when>
      <xsl:when test="@rendition = 'Heading5'">
        <xsl:text>
\beforeSubparagraphHeading{}\subparagraph{</xsl:text>
      </xsl:when>
    </xsl:choose>
    
    <!-- try to remove pre-existing section numbering -->
    <xsl:choose>
      <xsl:when test="tei:space">
        <xsl:apply-templates select="tei:space/following-sibling::node()" />
      </xsl:when>
      <xsl:when test="tei:hi/tei:space">
        <xsl:apply-templates select="descendant::tei:space/following-sibling::node()" />
      </xsl:when>
      <xsl:when test="matches(normalize-space(), '^\d\.')">
        <xsl:value-of select="substring-after(normalize-space(), ' ')" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="*" />
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}</xsl:text>
  </xsl:template>
  
  <xsl:template match="@xml:id">
    <xsl:call-template name="makeLabel">
      <xsl:with-param name="targetElement" select="parent::*" />
    </xsl:call-template>
  </xsl:template>
  
  <xsl:function name="gtex:replaceAll" as="xs:string?">
    <xsl:param name="input" as ="xs:string?" />
    <xsl:param name="find" as="xs:string*" />
    <xsl:param name="repl" as="xs:string*" />
    
    <xsl:sequence select="
      if (count($find) > 0)
      then gtex:replaceAll(
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
    <xsl:value-of select="gtex:replaceAll(., $from, $to)" />
  </xsl:template>
  
  <xsl:template match="tei:anchor[@type eq 'bookmarkStart']" />
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
            <xsl:value-of select="generate-id()"/>
            <xsl:text>}}</xsl:text>
          </xsl:when>
          <!-- neu 2016-06-17 DK -->
          <xsl:when test="$type='crit_app' and parent::tei:note[@place]">
            <xsl:text>\habBodyFootmarkA{</xsl:text>
            <xsl:value-of select="generate-id()"/>
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
  
  <!-- neue Regelung nach Treffen 2016-02-10: tr immer spitz, intro und FN eckig, außer wenn @reason; 2016-02-12 DK -->
  <xsl:template match="tei:gap">
    <xsl:text>[…]</xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:hi">
    <xsl:choose>
      <xsl:when test="contains(@style,'font-style: italic;') and contains(@style, 'font-weight: bold')">
        <xsl:text>\textbf{\textit{</xsl:text>
        <xsl:apply-templates />
        <xsl:text>}}</xsl:text>
      </xsl:when>
      <xsl:when test="contains(@style,'font-style: italic;')">
        <xsl:text>\textit{</xsl:text>
        <xsl:apply-templates />
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:when test="contains(@style, 'font-weight: bold')">
        <xsl:text>\textbf{</xsl:text>
        <xsl:apply-templates />
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:when test="contains(@style, 'vertical-align: super')">
        <xsl:text>\textsuperscript{</xsl:text>
        <xsl:apply-templates />
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:when test="contains(@style, 'vertical-align: sub')">
        <xsl:text>\textsubscript{</xsl:text>
        <xsl:apply-templates />
        <xsl:text>}</xsl:text>
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
  
  <!--<xsl:template match="tei:note[not(@type = 'crit_app' or @type = 'comment')]" mode="fnText">
    <xsl:choose>
      <xsl:when test="ancestor::tei:note[@place]" /><!-\- Ausgleich in marginFoot zerstört Abstand dahinter -\->
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
    <!-\- parent:: durch ancestor:: ersetzt; 2017-02-03 DK -\->
    <xsl:if
      test="@xml:id or ancestor::tei:note[@place = 'margin'] or @corresp or preceding-sibling::*[1][self::tei:seg] 
      or ancestor::tei:opener or ancestor::tei:closer or ancestor::tei:list[not(@rend or @rend = 'inline')]">
      <xsl:call-template name="makeLabel"/>
    </xsl:if>
    <xsl:apply-templates select="node() | processing-instruction()"/>
    <xsl:text>}</xsl:text>
    <!-\- neu 2016-12-10 DK -\->
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
  </xsl:template>-->
  
  <xsl:template match="tei:ptr[@type='digitalisat']" />
  <xsl:template match="tei:ptr[@type = 'link']">
    <xsl:value-of select="normalize-space(@target)"/>
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
  
  <xsl:template match="tei:ref[string-length(normalize-space()) gt 0]">
    <xsl:text>\url{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:table">
    <xsl:text>\microtypesetup{protrusion=false}
\begin{tabularx}{\textwidth}{@{}|</xsl:text>
    <xsl:sequence select="for $i in (1 to @cols) return 'p{' || (1 - @cols * 0.015) div number(@cols) || '\textwidth}|'"/>
    <xsl:text>@{}}</xsl:text>
    <xsl:text>
  \hline\rowcolor{lightgray}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\hline</xsl:text>
    <xsl:text>\end{tabularx}\microtypesetup{protrusion=true}</xsl:text>
  </xsl:template>
  <xsl:template match="tei:row">
    <!--<xsl:if test="not(following-sibling::tei:row)">
      <xsl:text>\rowcolor{lightgray}</xsl:text>
    </xsl:if>-->
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
  
  <xsl:template match="tei:lb">
    <xsl:text>
    \newline </xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:title[parent::tei:p or parent::tei:note]">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:list[tei:label]">
    <xsl:text>
\beforeList{}\begin{</xsl:text>
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
    <xsl:text>}\afterList{}</xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:label" />
  <xsl:template match="tei:item">
    <xsl:text>
  \item{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>
  
  <xsl:template name="makeLabel">
    <xsl:param name="location" select="''" />
    <xsl:param name="targetElement" select="." />
    
    <xsl:text>\label{</xsl:text>
    <xsl:value-of select="concat(generate-id($targetElement), $location)" />
    <xsl:text>}</xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:space">
    <xsl:text>\spaceCommand{</xsl:text>
    <xsl:value-of select="@width" />
    <xsl:text>}</xsl:text>
  </xsl:template>
</xsl:stylesheet>
