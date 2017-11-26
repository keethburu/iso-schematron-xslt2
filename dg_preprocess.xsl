<xsl:stylesheet xmlns:dg="http://www.degruyter.com/namespace" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:letex="http://www.le-tex.de/namespace" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dgs="http://www.degruyter.com/namespace/schematron-annotation" xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs xd sch" version="2.0">
	<xsl:output indent="yes"/>
	<xd:doc>
		<xd:desc>pre-processes a schematron withtin DG book workflow
        
        </xd:desc>
	</xd:doc>
	<xsl:template match="sch:schema">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<dgs:phases/>
			<!-- use -->
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>
	<!-- if phase_mode_dgs2phases eq true() a pattern annotated like this
     <dgs:ph>
            <dgs:ref dgs:role="error" dgs:phase="editorial_family"/>
            <dgs:ref dgs:role="error" dgs:phase="editorial"/>
            <dgs:ref dgs:role="error" dgs:phase="herstellung_family"/>
            <dgs:ref dgs:role="error" dgs:phase="herstellung"/>
            <dgs:ref dgs:role="error" dgs:phase="erstversand_family"/>
            <dgs:ref dgs:role="error" dgs:phase="erstversand"/>
        </dgs:ph>
    
    will result in accordingly created phase refs
    
    if phase_mode_dgs2phases eq false()
    the stilesheet will write thos dgs annotations from existing phases to the patterns
    
    -->
	<xsl:param name="phase_mode_dgs2phases" select="true()"/>
	<xsl:template match="@* | node()">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="dgs:phases">
		<xsl:for-each-group select="./ancestor::sch:schema//sch:pattern" group-by=".//@dgs:phase">
			<phase xmlns="http://purl.oclc.org/dsdl/schematron" id="{current-grouping-key()}">
				<xsl:variable name="cgk" select="current-grouping-key()"/>
				<xsl:for-each select="current-group()">
					<xsl:variable name="patternId" select="./@id"/>
					<xsl:variable name="pattern" select="."/>
					<xsl:for-each select=".//dgs:ref[@dgs:phase = $cgk]">
						<xsl:variable name="pattern_id" select="         if (./@dgs:refid) then          data(./@dgs:refid)         else          if (:ref links a phase directly, without any virtual patterns:) (count(.//*[self::dgs:from or self::dgs:before or @dgs:status or @dgs:status_not]) eq 0) then           $patternId          else (:pattern has refs, but refs don't have IDs yet:)           dg:refIdFromRefAndPattern($pattern, .)"/>
						<active pattern="{$pattern_id}"/>
					</xsl:for-each>
				</xsl:for-each>
			</phase>
		</xsl:for-each-group>
	</xsl:template>
	<xsl:template match="dgs:ref">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:if test="not(@dgs:refif)">
				<xsl:attribute name="dgs:refid" select="dg:refIdFromRefAndPattern(ancestor::sch:pattern, .)"/>
			</xsl:if>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="sch:phase">
		<xsl:choose>
			<xsl:when test="$phase_mode_dgs2phases eq true()">
				<!--   <xsl:comment>
             original-phase:<xsl:value-of select="@id"/> {<xsl:for-each select="./sch:active">
                 <xsl:value-of select="./@pattern"/>,
             </xsl:for-each>}</xsl:comment>--> </xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<xsl:apply-templates select="@*"/>
					<xsl:apply-templates select="node()"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="sch:pattern[@dgs:virtual]"/>
	<xsl:function name="dg:virtualAssertIdFromRefAndAssert" as="xs:string">
		<xsl:param name="assert"/>
		<xsl:param name="ref"/>
		<xsl:variable name="pattern" select="$assert/ancestor::sch:pattern"/>
		<xsl:variable name="rule" select="$assert/ancestor::sch:rule"/>
		<xsl:variable name="refId" select="dg:refIdFromRefAndPattern($pattern, $ref)"/>
		<xsl:variable name="r_distictive" select="(1 + count($rule/preceding-sibling::*:rule)) cast as xs:string"/>
		<xsl:variable name="distictive" select="(1 + count($assert/preceding-sibling::*:assert)) cast as xs:string"/>
		<xsl:value-of select="concat($refId, '_r', $r_distictive, '_a', $distictive)"/>
	</xsl:function>
	<xsl:function name="dg:virtualRuleIdFromRefAndAssert" as="xs:string">
		<xsl:param name="rule"/>
		<xsl:param name="ref"/>
		<xsl:variable name="pattern" select="$rule/ancestor::sch:pattern"/>
		<xsl:variable name="refId" select="dg:refIdFromRefAndPattern($pattern, $ref)"/>
		<xsl:variable name="distictive" select="(1 + count($rule/preceding-sibling::*:rule)) cast as xs:string"/>
		<xsl:value-of select="concat($refId, '_r', $distictive)"/>
	</xsl:function>
	<xsl:function name="dg:refIdFromRefAndPattern" as="xs:string">
		<!--  <dgs:ref dgs:role="error" dgs:phase="editorial" dgs:id="sa"> -->
		<xsl:param name="pattern"/>
		<xsl:param name="ref"/>
		<xsl:variable name="r" select="$ref/@dgs:role"/>
		<xsl:variable name="p" select="$ref/@dgs:phase"/>
		<xsl:variable name="refId">
			<xsl:choose>
				<xsl:when test="$ref/@dgs:refid">
					<xsl:value-of select="$ref/@dgs:refid"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="stat" select="        if ($ref/@dgs:status) then         concat('-st', substring(replace($ref/@dgs:status, '[\W]+', ''), 1, 6))        else         ''"/>
					<xsl:variable name="statno" select="        if ($ref/@dgs:status_not) then         concat('-n', substring(replace($ref/@dgs:status_not, '[\W]+', ''), 1, 6))        else         ''"/>
					<xsl:variable name="distictive" select="(1 + count($ref/preceding-sibling::*:ref[@dgs:role = $r][@*:phase = $p])) cast as xs:string"/>
					<!--<xsl:variable name="descriptivePart" select="concat($p, '-', $r, $stat, $statno)"/>-->
					<xsl:variable name="descriptivePart" select="concat($r, '-', $p)"/>
					<xsl:value-of select="concat($pattern/@id, '_', $descriptivePart, $distictive, '_v')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$refId"/>
	</xsl:function>
	<!-- match="dgs:ref[child::dgs:from or child::dgs:before or @dgs:status or @dgs:status_not]" -->
	<xsl:template match="dgs:ref" mode="create_virtual">
		<xsl:variable name="from_pred" select="     if (./dgs:from) then      dg:tasksAndBeforePdatePredicates(./dgs:from)     else      ''"/>
		<xsl:variable name="before_pred" select="     if (./dgs:before) then      dg:tasksAndBeforePdatePredicates(./dgs:before)     else      ''"/>
		<xsl:variable name="statusPreds" select="dg:refImpressionStatusFilterPredicate(.)"/>
		<xsl:variable name="clsf_exclPred" select="dg:refEditionClassificationExcludeFilterPredicate(.)"/>
		<xsl:variable name="clsf_inclPred" select="dg:refEditionClassificationIncludeFilterPredicate(.)"/>
		<xsl:variable name="predicates" select="concat(dg:refEditionExcludeDDEALSPredicate(), $statusPreds, $clsf_exclPred, $clsf_inclPred, $from_pred, $before_pred)"/>
		<xsl:apply-templates select="ancestor::sch:pattern" mode="create_virtual">
			<xsl:with-param name="ref" select="."/>
			<xsl:with-param name="predicates" select="$predicates"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="dgs:ref[not(child::dgs:from or child::dgs:before or @dgs:status or @dgs:status_not) and not(child::comment())]">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:comment>&lt;dgs:ref dgs:role="error" dgs:phase="editorial" dgs:status="LFB" dgs:status_not="LFB"&gt;
                &lt;dgs:from dgs:pending="true" dgs:tasks="3000740_translate-marketing-texts 3000200_publish-metadata" dgs:days_to_pdate="180"/&gt;
                &lt;dgs:before dgs:pending="true" dgs:tasks="3000740_translate-marketing-texts 3000200_publish-metadata"/&gt;
            &lt;/dgs:ref&gt;</xsl:comment>
		</xsl:copy>
	</xsl:template>
	<xd:doc>
		<xd:desc>
			<xd:p/>
		</xd:desc>
		<xd:param name="ref"/>
		<xd:param name="predicates"/>
	</xd:doc>
	<xsl:template match="sch:pattern[not(@dgs:virtual)]" mode="create_virtual">
		<xsl:param name="ref" required="yes"/>
		<xsl:param name="predicates" as="xs:string" required="yes"/>
		<xsl:variable name="pid" select="@id"/>
		<xsl:variable name="v_pattern_id" select="dg:refIdFromRefAndPattern(., $ref)"/>
		<xsl:copy>
			<xsl:attribute name="id" select="$v_pattern_id"/>
			<xsl:attribute name="dgs:virtual" select="true()"/>
			<xsl:attribute name="dgs:original_id" select="$pid"/>
			<xsl:copy-of select="$ref/@dgs:task_bind"/>
			<xsl:apply-templates select="@abstract"/>
			<xsl:apply-templates select="@is-a"/>
			<xsl:apply-templates select="sch:title"/>
			<xsl:apply-templates select="sch:rule | sch:param | sch:let" mode="create_virtual">
				<xsl:with-param name="ref" select="$ref"/>
				<xsl:with-param name="predicates" select="$predicates"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<xd:doc>
		<xd:desc>creates a virtual copy of a rule</xd:desc>
		<xd:param name="ref">rhe dgs:ref element</xd:param>
		<xd:param name="predicates"/>
	</xd:doc>
	<xsl:template match="sch:rule" mode="create_virtual">
		<xsl:param name="ref" as="element()" required="yes"/>
		<xsl:param name="predicates" as="xs:string"/>
		<xsl:variable name="rid" select="@id"/>
		<xsl:variable name="v_rule_id" select="dg:virtualRuleIdFromRefAndAssert(., $ref)"/>
		<xsl:copy>
			<xsl:attribute name="id" select="$v_rule_id"/>
			<xsl:attribute name="dgs:virtual" select="true()"/>
			<xsl:attribute name="dgs:original_id" select="$rid"/>
			<xsl:copy-of select="$ref/@dgs:task_bind"/>
			<xsl:attribute name="context" select="dg:injectPredicate(data(@context), $predicates)"/>
			<xsl:apply-templates select="sch:assert | sch:let" mode="create_virtual_assert_let">
				<xsl:with-param name="ref" select="$ref"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="sch:assert" mode="create_virtual_assert_let">
		<xsl:param name="ref" as="element()" required="yes"/>
		<xsl:variable name="aid" select="@id"/>
		<xsl:variable name="v_assert_id" select="dg:virtualAssertIdFromRefAndAssert(., $ref)"/>
		<xsl:copy>
			<xsl:attribute name="id" select="$v_assert_id"/>
			<xsl:attribute name="dgs:virtual" select="true()"/>
			<xsl:attribute name="dgs:original_id" select="$aid"/>
			<xsl:copy-of select="$ref/@dgs:task_bind"/>
			<xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="sch:let" mode="create_virtual_assert_let">
		<xsl:param name="ref" as="element()" required="yes"/>
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="sch:param" mode="create_virtual">
		<xsl:param name="ref" as="element()" required="yes"/>
		<xsl:param name="predicates" as="xs:string"/>
		<xsl:copy>
			<xsl:attribute name="name" select="@name"/>
			<xsl:attribute name="value" select="dg:injectPredicate(data(@value), $predicates)"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="sch:let" mode="create_virtual">
		<xsl:param name="ref" as="element()" required="yes"/>
		<xsl:param name="predicates" as="xs:string"/>
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
		</xsl:copy>
	</xsl:template>
	<xd:doc>
		<xd:desc>
			<xd:p>injects a prediacte into a TITLE|EDITION|IMPRESSION @context expression, </xd:p>
			<xd:p>$context = '//TITLE[@foo]' and $prediactes = '[@bar]' returns '//TITLE[@bar][@foo]'</xd:p>
			<xd:p>caution: of cause it is designed to work with TITLE|EDITION|IMPRESSION as context elements only,</xd:p>
		</xd:desc>
		<xd:param name="context">the XPath value of the schematron context attribute</xd:param>
		<xd:param name="predicates">the predicate or predicates</xd:param>
		<xd:return>the updated context xpath </xd:return>
	</xd:doc>
	<xsl:function name="dg:injectPredicate" as="xs:string">
		<xsl:param name="context" as="xs:string"/>
		<xsl:param name="predicates" as="xs:string"/>
		<!-- //@context/replace(.,'(^//)(TITLE|EDITION|IMPRESSION)',concat('$1$2','\$FOOO')) -->
		<!-- done via substring and not replace because I don't want to regex-escape the second argument of replace -->
		<xsl:variable name="splitter" select="'#######'" as="xs:string"/>
		<xsl:variable name="splittable" select="replace($context, '(^\s*//)(TITLE|EDITION|IMPRESSION)', concat('$1$2', $splitter))"/>
		<xsl:variable name="virtualized_context" select="concat(substring-before($splittable, $splitter), $predicates, substring-after($splittable, $splitter))"/>
		<xsl:value-of select="$virtualized_context"/>
	</xsl:function>
	<!-- 
    
     <dgs:ph>
            <dgs:ref dgs:role="error" dgs:phase="editorial" dgs:status="LFB" dgs:status_not="LFB">
                    @dgs:status - mutiple strings (IPL, IHST, LFB, WNN, PLZ, DIS) separated by whitespace  or comma filters KuP Lieferstatus, (will be combined by OR),
                    @dgs:status_not - mutiple strings (IPL, IHST, LFB, WNN, PLZ, DIS) separated by whitespace  or comma filters KuP Lieferstatus, (will be combined by OR),
                    @dgs:clsf - multiple strings, separated by whitespace  or comma, filters classifications
                    @dgs:clsf_not - multiple strings, separated by whitespace  or comma, filters classifications
                    dgs:from creates a condition 'applies for all titles with a finished task from that list' that will be added in the virtual schematron to all rules -
                    dgs:before creates a condition 'applies for all titles without a finished task from that list' that will be added in the virtual schematron to all rules -
                    @dgs:tasks whitespace separated list of (finished or pending) tasks that should be a condition (will be combined by OR)
                    @dgs:pending - if attribute is present finished or pending tasks will be taken into account, otherwise its only finished tasks
                    @dgs:status - mutiple strings (IPL, IHST, LFB, WNN, PLZ, DIS) separated by whitespace  or comma filters KuP Lieferstatus, (will be combined by OR), 
                    @dgs:days_to_pdate - integer - filters a day relative to the planned pub date (title is matched, if current-date() later than planned-pub-date - days_to_pdate)
                
                <dgs:from dgs:pending="true" dgs:tasks="3000740_translate-marketing-texts 3000200_publish-metadata" dgs:days_to_pdate="180"/>
                <dgs:before dgs:pending="true" dgs:tasks="3000740_translate-marketing-texts 3000200_publish-metadata"/>
            </dgs:ref>
            <dgs:ref dgs:role="error" dgs:phase="erstversand"/>
        </dgs:ph>
        not(.//CLS[@CAT_CODE = 'BTFG'])
        
    -->
	<xsl:function name="dg:refEditionClassificationExcludeFilterPredicate" as="xs:string">
		<xsl:param name="ref" as="element()"/>
		<xsl:choose>
			<xsl:when test="$ref/@dgs:clsf_not">
				<xsl:variable name="openingPred" select="'[not(descendant-or-self::IMPRESSION/ancestor::EDITION'"/>
				<xsl:variable name="closingpred" select="')]'"/>
				<xsl:variable name="clsf_not" as="xs:string">
					<xsl:choose>
						<xsl:when test="$ref/@dgs:clsf_not">
							<!-- <xsl:variable name="statusListInner"
                                select="string-join(tokenize(replace($ref/@dgs:status, '[\S\W^,]', ''), '[\s]+'), ''', ''')"/>-->
							<xsl:variable name="clsf_notListInner" select="string-join(tokenize($ref/@dgs:clsf_not, '[\s]+'), ''', ''')"/>
							<xsl:value-of select="concat('[.//CLS[@CAT_CODE = (''', $clsf_notListInner, ''')]]')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="''"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<!-- <xsl:value-of
                    select="concat($openingPred, $statusPreds, $statusNotPreds, $closingpred)"/>-->
				<xsl:value-of select="concat($openingPred, $clsf_not, $closingpred)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="''"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<xsl:function name="dg:refEditionClassificationIncludeFilterPredicate" as="xs:string">
		<xsl:param name="ref" as="element()"/>
		<xsl:choose>
			<xsl:when test="$ref/@dgs:clsf">
				<xsl:variable name="openingPred" select="'[descendant-or-self::IMPRESSION/ancestor::EDITION'"/>
				<xsl:variable name="closingpred" select="']'"/>
				<xsl:variable name="clsf" as="xs:string">
					<xsl:choose>
						<xsl:when test="$ref/@dgs:clsf_not">
							<!-- <xsl:variable name="statusListInner"
                                select="string-join(tokenize(replace($ref/@dgs:status, '[\S\W^,]', ''), '[\s]+'), ''', ''')"/>-->
							<xsl:variable name="clsfListInner" select="string-join(tokenize($ref/@dgs:clsf, '[\s]+'), ''', ''')"/>
							<xsl:value-of select="concat('[.//CLS[@CAT_CODE = (''', $clsfListInner, ''')]]')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="''"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<!-- <xsl:value-of
                    select="concat($openingPred, $statusPreds, $statusNotPreds, $closingpred)"/>-->
				<xsl:value-of select="concat($openingPred, $clsf, $closingpred)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="''"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xd:doc>
		<xd:desc>creates a predicate, that excludes @GROUP_OF_COMPANY = 'DDEAL'] </xd:desc>
	</xd:doc>
	<xsl:function name="dg:refEditionExcludeDDEALSPredicate" as="xs:string">
		<xsl:sequence select="'[not(descendant-or-self::IMPRESSION/ancestor::EDITION[@GROUP_OF_COMPANY = ''DDEAL''])]'"/>
	</xsl:function>
	
	<!-- 
    
     <dgs:ph>
            <dgs:ref dgs:role="error" dgs:phase="editorial" dgs:status="LFB" dgs:status_not="LFB">
                    @dgs:status - mutiple strings (IPL, IHST, LFB, WNN, PLZ, DIS) separated by whitespace  or comma filters KuP Lieferstatus, (will be combined by OR),
                    @dgs:status_not - mutiple strings (IPL, IHST, LFB, WNN, PLZ, DIS) separated by whitespace  or comma filters KuP Lieferstatus, (will be combined by OR),
                    @dgs:clsf - multiple strings, separated by whitespace  or comma, filters classifications
                    @dgs:clsf_not - multiple strings, separated by whitespace  or comma, filters classifications
                    dgs:from creates a condition 'applies for all titles with a finished task from that list' that will be added in the virtual schematron to all rules -
                    dgs:before creates a condition 'applies for all titles without a finished task from that list' that will be added in the virtual schematron to all rules -
                    @dgs:tasks whitespace separated list of (finished or pending) tasks that should be a condition (will be combined by OR)
                    @dgs:pending - if attribute is present finished or pending tasks will be taken into account, otherwise its only finished tasks
                    @dgs:status - mutiple strings (IPL, IHST, LFB, WNN, PLZ, DIS) separated by whitespace  or comma filters KuP Lieferstatus, (will be combined by OR), 
                    @dgs:days_to_pdate - integer - filters a day relative to the planned pub date (title is matched, if current-date() later than planned-pub-date - days_to_pdate)
                
                <dgs:from dgs:pending="true" dgs:tasks="3000740_translate-marketing-texts 3000200_publish-metadata" dgs:days_to_pdate="180"/>
                <dgs:before dgs:pending="true" dgs:tasks="3000740_translate-marketing-texts 3000200_publish-metadata"/>
            </dgs:ref>
            <dgs:ref dgs:role="error" dgs:phase="erstversand"/>
        </dgs:ph>
        not(.//CLS[@CAT_CODE = 'BTFG'])
        
    -->
	<xsl:function name="dg:refImpressionStatusFilterPredicate" as="xs:string">
		<xsl:param name="ref" as="element()"/>
		<xsl:choose>
			<xsl:when test="$ref/@dgs:status or $ref/@dgs:status_not">
				<xsl:variable name="openingPred" select="'[descendant-or-self::IMPRESSION'"/>
				<xsl:variable name="closingpred" select="']'"/>
				<xsl:variable name="statusPreds" as="xs:string">
					<xsl:choose>
						<xsl:when test="$ref/@dgs:status">
							<!-- <xsl:variable name="statusListInner"
                                select="string-join(tokenize(replace($ref/@dgs:status, '[\S\W^,]', ''), '[\s]+'), ''', ''')"/>-->
							<xsl:variable name="statusListInner" select="string-join(tokenize($ref/@dgs:status, '[\s]+'), ''', ''')"/>
							<xsl:value-of select="concat('[@STATUS = (''', $statusListInner, ''')]')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="''"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="statusNotPreds" as="xs:string">
					<xsl:choose>
						<xsl:when test="$ref/@dgs:status_not">
							<xsl:variable name="statusListInner" select="string-join(tokenize(replace($ref/@dgs:status_not, '[\S\W^,]', ''), '[\s]+'), ''', ''')"/>
							<xsl:value-of select="concat('[not(@STATUS = (''', $statusListInner, '''))]')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="''"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:value-of select="concat($openingPred, $statusPreds, $statusNotPreds, $closingpred)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="''"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<xsl:function name="dg:tasksAndBeforePdatePredicates" as="xs:string">
		<xsl:param name="from_before" as="element()"/>
		<!-- //EDITION[ancestor-or-self::TITLE//wf/*/*[self::finished or self::pending][@PBS_SCHD_TASK='1000200']] -->
		<xsl:variable name="planned_pub_date_predicate">
			<!-- /TITLE/EDITION[2]/IMPRESSIONS[1]/IMPRESSION[1]/@STATUS 
            /TITLE/EDITION[1]/IMPRESSIONS[1]/IMPRESSION[1]/@PLANNED_PUB_DATE
            
            [.//IMPRESSION[(current-date() ge xs:date(@PLANNED_PUB_DATE) - xs:dayTimeDuration('P20D'))]]
            
            current-date() + xs:dayTimeDuration('P7D')
            
            -->
			<xsl:choose>
				<xsl:when test="$from_before/@dgs:days_to_pdate">
					<xsl:variable name="pre" select="'descendant-or-self::IMPRESSION[(current-date() ge xs:date(@PLANNED_PUB_DATE) - xs:dayTimeDuration(''P'"/>
					<xsl:variable name="duration" select="($from_before/@dgs:days_to_pdate cast as xs:integer) cast as xs:string"/>
					<xsl:variable name="end" select="'D''))]'"/>
					<xsl:variable name="predicate_comment" select="concat('(: PLANNED_PUB_DATE predicate ', name($from_before), ' :)')"/>
					<xsl:choose>
						<xsl:when test="$from_before/self::dgs:from">
							<xsl:value-of select="concat(' or ', $predicate_comment, $pre, $duration, $end, '')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat('or not', $predicate_comment, '(', $pre, $duration, $end, ')')"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'(:no pubpdate filter:)'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="task_predicates" as="xs:string">
			<xsl:choose>
				<xsl:when test="$from_before/@dgs:tasks">
					<xsl:variable name="pred_pending" select="        if ($from_before/@dgs:pending eq 'true') then         ' or self::pending'        else         ''"/>
					<xsl:variable name="pred_finished_pending" select="concat('[self::finished', $pred_pending, ']')"/>
					<!-- creates smth like 3000740', '3000200 from dgs:tasks="3000740_translate-marketing-texts 3000200_publish-metadata" -->
					<xsl:variable name="pred_tasks_inner" select="string-join(tokenize(replace($from_before/@dgs:tasks, '[_|a-z|-]', ''), '(\D)+'), ''', ''')"/>
					<!-- results in this case in [@PBS_SCHD_TASK=('3000740', '3000200') -->
					<xsl:variable name="pred_tasks">
						<xsl:value-of select="concat('[@PBS_SCHD_TASK=(''', $pred_tasks_inner, ''')]')"/>
					</xsl:variable>
					<xsl:variable name="predicate_comment" select="concat('(:task_predicate ', name($from_before), ' :)')"/>
					<xsl:choose>
						<xsl:when test="$from_before/self::dgs:from">
							<xsl:value-of select="concat($predicate_comment, '[ancestor-or-self::TITLE//wf/*/*', $pred_finished_pending, $pred_tasks, $planned_pub_date_predicate, ']')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat($predicate_comment, '[not(ancestor-or-self::TITLE//wf/*/*', $pred_finished_pending, $pred_tasks, ')', $planned_pub_date_predicate, ']')"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="$from_before/@dgs:days_to_pdate">
							<xsl:variable name="pre" select="'descendant-or-self::IMPRESSION[(current-date() ge xs:date(@PLANNED_PUB_DATE) - xs:dayTimeDuration(''P'"/>
							<xsl:variable name="duration" select="($from_before/@dgs:days_to_pdate cast as xs:integer) cast as xs:string"/>
							<xsl:variable name="end" select="'D''))]'"/>
							<xsl:variable name="predicate_comment" select="concat('(: PLANNED_PUB_DATE predicate ', name($from_before), ' :)')"/>
							<xsl:choose>
								<xsl:when test="$from_before/self::dgs:from">
									<xsl:value-of select="concat(' [ ', $predicate_comment, $pre, $duration, $end, ']')"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="concat('[ not', $predicate_comment, '(', $pre, $duration, $end, ')]')"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$task_predicates"/>
	</xsl:function>
	<xsl:template match="sch:let" mode="create_virtual">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="sch:pattern[not(@dgs:virtual)]">
		<xsl:variable name="pid" select="@id"/>
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<!-- <xsl:if test="not(@abstract = 'true')">
                <xsl:comment>
                usage:
                <xsl:value-of select="string-join(distinct-values(//sch:phase[.//@pattern = $pid]/@id), '; ')"/>
                </xsl:comment>
            </xsl:if>-->
			<!-- inject existing phases here -->
			<!--            <xsl:if test="not(@abstract = 'true') and not(./*[local-name()='ph']) and $phase_mode_dgs2phases eq false()">
                <dgs:ph>
                    <xsl:for-each select="distinct-values(//sch:phase[.//@pattern = $pid]/@id)">
                        <dgs:ref dgs:role="error" dgs:phase="{.}"/>
                    </xsl:for-each>
                </dgs:ph>
            </xsl:if>-->
			<xsl:apply-templates select="dgs:ph[1]"/>
			<xsl:apply-templates select="node()[not(self::dgs:ph)]"/>
		</xsl:copy>
		<xsl:if test="not(following-sibling::sch:pattern[not(@dgs:virtual)])">
			<xsl:apply-templates select="//dgs:ref[child::dgs:from or child::dgs:before or @dgs:status or @dgs:status_not]" mode="create_virtual"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="sch:assert[@diagnostics]">
		<xsl:copy>
			<xsl:apply-templates select="@id"/>
			<xsl:apply-templates select="@diagnostics"/>
			<xsl:apply-templates select="@test"/>
			<xsl:apply-templates select="@*[local-name() = ('id', 'diagnostics', 'test')]"/>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="sch:assert[not(@diagnostics)]">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:attribute name="diagnostics">
				<xsl:text>diag-</xsl:text>
				<xsl:value-of select="@id"/>
				<xsl:text>-de</xsl:text>
				<xsl:text> diag-</xsl:text>
				<xsl:value-of select="@id"/>
				<xsl:text>-en</xsl:text>
			</xsl:attribute>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="sch:assert" mode="create-diag">
		<!--
        <diagnostic id="#ID" see="http://wiki.degruyter.com/bin/view/DGWiki/####" xml:lang="de" xml:space="preserve">
            <span class="de"></span>
        </diagnostic>-->
		<xsl:variable name="titleForUrl">
			<xsl:value-of select="      string-join((for $s in tokenize(replace(replace(replace(if (./ancestor::sch:pattern/sch:title) then       ./ancestor::sch:pattern/sch:title      else       @id, 'ü', 'u', 'i'), 'ö', 'o', 'i'), 'ä', 'a', 'i'), '\W'),       $fl in substring($s, 1, 1),       $tail in substring($s, 2)      return       concat(upper-case($fl), lower-case($tail))), '')"/>
		</xsl:variable>
		<xsl:comment>
            <xsl:text>
                ~~~~~~~~~~~~~~~~~~~~~~~~~~~
            </xsl:text>
            <xsl:value-of select="$titleForUrl"/>
        </xsl:comment>
		<diagnostic xmlns="http://purl.oclc.org/dsdl/schematron">
			<xsl:attribute name="id">
				<xsl:text>diag-</xsl:text>
				<xsl:value-of select="@id"/>
				<xsl:text>-de</xsl:text>
			</xsl:attribute>
			<xsl:attribute name="see">
				<xsl:text>http://wiki.degruyter.com/bin/view/DGWiki/Bwf</xsl:text>
				<xsl:value-of select="$titleForUrl"/>
				<xsl:text>De</xsl:text>
			</xsl:attribute>
			<xsl:choose>
				<xsl:when test=".//sch:span[@class = 'de']">
					<xsl:apply-templates select="sch:span[@class = 'de']"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="node()"/>
				</xsl:otherwise>
			</xsl:choose>
		</diagnostic>
		<diagnostic xmlns="http://purl.oclc.org/dsdl/schematron">
			<xsl:attribute name="id">
				<xsl:text>diag-</xsl:text>
				<xsl:value-of select="@id"/>
				<xsl:text>-en</xsl:text>
			</xsl:attribute>
			<xsl:attribute name="see">
				<xsl:text>http://wiki.degruyter.com/bin/view/DGWiki/Bwf</xsl:text>
				<xsl:value-of select="$titleForUrl"/>
				<xsl:text>En</xsl:text>
			</xsl:attribute>
			<xsl:choose>
				<xsl:when test=".//sch:span[@class = 'en']">
					<xsl:apply-templates select="sch:span[@class = 'en']"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="node()"/>
				</xsl:otherwise>
			</xsl:choose>
		</diagnostic>
	</xsl:template>
	<xsl:template match="sch:diagnostics">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates select="node()"/>
			<xsl:apply-templates select="//sch:assert[not(@diagnostics)]" mode="create-diag"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="sch:diagnostic">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:if test="not(@xml:lang)">
				<xsl:attribute name="xml:lang" select="       if (ends-with(data(./@id), 'de')) then        'de'       else        'en'"/>
			</xsl:if>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>