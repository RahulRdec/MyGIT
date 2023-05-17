<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:dpfunc="http://www.datapower.com/extensions/functions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:dyn="http://exslt.org/dynamic" xmlns:hgu="http://hgu.com" extension-element-prefixes="dp func hgu dpfunc dpconfig date str regexp dyn" exclude-result-prefixes="dp hgu func dpfunc dpconfig date str regexp dyn">
	<xsl:template match="/">
		<xsl:variable name="domainName" select="/Request/DomainName/text()"/>
		<xsl:message dp:priority="error">Domain Name to be acted upon ::: <xsl:value-of select="$domainName"/>
		</xsl:message>
		<xsl:variable name="exemptedMPGWs">
			<xsl:for-each select="/Request/ExemptedMPGWs/MPGW">
				<xsl:value-of select="."/>
				<xsl:text>+</xsl:text>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="CurrentDateTime">
			<xsl:value-of select="date:date-time()"/>
		</xsl:variable>
		<xsl:variable name="checkpointName" select="translate(concat('MPGW_Checkpoint_', $CurrentDateTime), '-:', '')"/>
		<xsl:message dp:priority="error">Checkpoint Name ::: <xsl:value-of select="$checkpointName"/>
		</xsl:message>
		<xsl:variable name="CreateCheckpoint">
			<xsl:call-template name="createCheckpoint">
				<xsl:with-param name="ChkName" select="$checkpointName"/>
				<xsl:with-param name="domainName" select="$domainName"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="allMPGWs">
			<xsl:call-template name="getConfigAll">
				<xsl:with-param name="objectClass" select="'MultiProtocolGateway'"/>
				<xsl:with-param name="domainName" select="$domainName"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:message dp:priority="error">
			<xsl:copy-of select="$allMPGWs"/>
		</xsl:message>
		<xsl:for-each select="$allMPGWs//MultiProtocolGateway">
			<xsl:variable name="nameMPGW" select="./@name"/>
			<xsl:if test="not(contains($exemptedMPGWs,$nameMPGW))">
				<xsl:message dp:priority="error">MPGW to update is <xsl:value-of select="$nameMPGW"/>
				</xsl:message>
				<xsl:variable name="stylePolicyName" select="./StylePolicy/text()"/>
				<!-- <xsl:if test="not(contains($WSStylePolicyName,'default'))"> -->
				<xsl:if test="($stylePolicyName != 'default')">
					<xsl:message dp:priority="error">Policy to update is <xsl:value-of select="$stylePolicyName"/>
					</xsl:message>
					<xsl:variable name="stylePolicyConfig">
						<xsl:call-template name="getConfig">
							<xsl:with-param name="objectClass" select="'StylePolicy'"/>
							<xsl:with-param name="objectName" select="$stylePolicyName"/>
							<xsl:with-param name="domainName" select="$domainName"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:message dp:priority="error">style policy config to update is <xsl:copy-of select="$stylePolicyConfig"/>
					</xsl:message>
					<xsl:for-each select="$stylePolicyConfig//Rule">
						<xsl:variable name="ruleName" select="."/>
						<xsl:message dp:priority="error">Rule to update is <xsl:value-of select="$ruleName"/>
						</xsl:message>
						<xsl:variable name="getRuleConfig">
							<xsl:call-template name="getConfig">
								<xsl:with-param name="objectClass" select="'StylePolicyRule'"/>
								<xsl:with-param name="objectName" select="$ruleName"/>
								<xsl:with-param name="domainName" select="$domainName"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:message dp:priority="error">Rule Config to update is <xsl:copy-of select="$getRuleConfig"/>
						</xsl:message>
						<xsl:variable name="actionName" select="concat($ruleName,'_xform_splunkLogging')"/>
						<xsl:variable name="direction" select="$getRuleConfig//Direction/text()"/>
						<xsl:variable name="fileName">
							<xsl:choose>
								<xsl:when test="$direction='request-rule' or $direction='response-rule'">
									<xsl:value-of select="'store:///TraceDisplay_v0_2.xsl'"/>
								</xsl:when>
								<xsl:when test="$direction='error-rule'">
									<xsl:value-of select="'store:///TraceDisplay_v0_Error.xsl'"/>
								</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="logActionConfig">
							<xsl:call-template name="splunkLogAction">
								<xsl:with-param name="fileName" select="$fileName"/>
								<xsl:with-param name="actionName" select="$actionName"/>
								<xsl:with-param name="domainName" select="$domainName"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:message dp:priority="error">Log action config is <xsl:copy-of select="$logActionConfig"/>
						</xsl:message>
						<xsl:variable name="createLogAction" select="hgu:somaCall($logActionConfig)"/>
						<xsl:message dp:priority="error">log action creation result is <xsl:copy-of select="$createLogAction"/>
						</xsl:message>
						<xsl:variable name="modifiedRuleConfig">
							<xsl:call-template name="addActionToRule">
								<xsl:with-param name="domainName" select="$domainName"/>
								<xsl:with-param name="ruleName" select="$ruleName"/>
								<xsl:with-param name="newActionName" select="$actionName"/>
								<xsl:with-param name="originalConfig" select="$getRuleConfig"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:message dp:priority="error">Modified Rule Config is <xsl:copy-of select="$modifiedRuleConfig"/>
						</xsl:message>
						<xsl:variable name="deployModifiedRuleResp" select="hgu:somaCall($modifiedRuleConfig)"/>
						<xsl:message dp:priority="error">deployment result is <xsl:copy-of select="$deployModifiedRuleResp"/>
						</xsl:message>
					</xsl:for-each>
				</xsl:if>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="addActionToRule">
		<xsl:param name="domainName" select="''"/>
		<xsl:param name="ruleName" select="''"/>
		<xsl:param name="newActionName" select="''"/>
		<xsl:param name="originalConfig" select="''"/>

		<xsl:variable name="modifiedRule">
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="{$domainName}">
						<man:modify-config>
							<StylePolicyRule name="{$ruleName}" xmlns:env="http://www.w3.org/2003/05/soap-envelope">
								<mAdminState>
									<xsl:value-of select="$originalConfig//mAdminState"/>
								</mAdminState>
								<Direction>
									<xsl:value-of select="$originalConfig//Direction"/>
								</Direction>
								<InputFormat>
									<xsl:value-of select="$originalConfig//InputFormat"/>
								</InputFormat>
								<OutputFormat>
									<xsl:value-of select="$originalConfig//OutputFormat"/>
								</OutputFormat>
								<NonXMLProcessing>
									<xsl:value-of select="$originalConfig//NonXMLProcessing"/>
								</NonXMLProcessing>
								<Unprocessed>
									<xsl:value-of select="$originalConfig//Unprocessed"/>
								</Unprocessed>
								<xsl:for-each select="$originalConfig//Actions">
									<Actions class="StylePolicyAction">
										<xsl:value-of select="."/>
									</Actions>
								</xsl:for-each>
								<Actions class="StylePolicyAction">
									<xsl:value-of select="$newActionName"/>
								</Actions>
							</StylePolicyRule>
						</man:modify-config>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable>
		<xsl:copy-of select="$modifiedRule"/>
	</xsl:template>

	<xsl:template name="splunkLogAction">
		<xsl:param name="fileName" select="''"/>
		<xsl:param name="actionName" select="''"/>
		<xsl:param name="domainName" select="''"/>
		<xsl:variable name="actionConfig">
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="{$domainName}">
						<man:set-config>
							<StylePolicyAction name="{$actionName}" xmlns:env="http://www.w3.org/2003/05/soap-envelope">
								<mAdminState>enabled</mAdminState>
								<Type>xform</Type>
								<Input>NULL</Input>
								<Transform>
									<xsl:value-of select="$fileName"/>
								</Transform>
								<TransformLanguage>none</TransformLanguage>
								<ActionDebug>off</ActionDebug>
								<Output>NULL</Output>
								<NamedInOutLocationType>default</NamedInOutLocationType>
								<SSLClientConfigType>proxy</SSLClientConfigType>
								<OutputType>default</OutputType>
								<Transactional>off</Transactional>
								<SOAPValidation>body</SOAPValidation>
								<SQLSourceType>static</SQLSourceType>
								<JWSVerifyStripSignature>on</JWSVerifyStripSignature>
								<Asynchronous>off</Asynchronous>
								<ResultsMode>first-available</ResultsMode>
								<RetryCount>0</RetryCount>
								<RetryInterval>1000</RetryInterval>
								<MultipleOutputs>off</MultipleOutputs>
								<IteratorType>XPATH</IteratorType>
								<Timeout>0</Timeout>
								<MethodRewriteType>GET</MethodRewriteType>
								<MethodType>POST</MethodType>
								<MethodType2>POST</MethodType2>
							</StylePolicyAction>
						</man:set-config>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable>
		<xsl:copy-of select="$actionConfig"/>
	</xsl:template>

	<xsl:template name="createCheckpoint">
		<xsl:param name="ChkName" select="''"/>
		<xsl:param name="domainName" select="''"/>
		<xsl:variable name="somaReq">
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="{$domainName}">
						<man:do-action>
							<SaveCheckpoint>
								<ChkName>
									<xsl:value-of select="$ChkName"/>
								</ChkName>
							</SaveCheckpoint>
						</man:do-action>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable>
		<xsl:variable name="somaResp" select="hgu:somaCall($somaReq)"/>
		<xsl:copy-of select="$somaResp"/>
		<xsl:message dp:priority="error">Checkpoint soma request :: <xsl:copy-of select="$somaReq"/>
		</xsl:message>
	</xsl:template>

	<xsl:template name="getConfig">
		<xsl:param name="objectClass" select="''"/>
		<xsl:param name="objectName" select="''"/>
		<xsl:param name="domainName" select="''"/>
		<xsl:variable name="somaReq">
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="{$domainName}">
						<man:get-config class="{$objectClass}" name="{$objectName}"/>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable>
		<xsl:variable name="somaResp" select="hgu:somaCall($somaReq)"/>
		<xsl:copy-of select="$somaResp"/>
	</xsl:template>

	<xsl:template name="getConfigAll">
		<xsl:param name="objectClass" select="''"/>
		<xsl:param name="domainName" select="''"/>
		<xsl:variable name="somaReq">
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="{$domainName}">
						<man:get-config class="{$objectClass}"/>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable>
		<xsl:message dp:priority="error">soma request :: <xsl:copy-of select="$somaReq"/>
		</xsl:message>
		<xsl:variable name="somaResp" select="hgu:somaCall($somaReq)"/>
		<xsl:copy-of select="$somaResp"/>
	</xsl:template>localhost_sslProxyProfile
	<func:function name="hgu:somaCall">
		<xsl:param name="object"/>
		<!-- <xsl:variable name="url" select="'https://127.0.0.1:5550/service/mgmt/current'"/> -->
		<xsl:variable name="sslProxy" select="'soma-ssl'"/>
		<xsl:variable name="headers">
			<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
		</xsl:variable>
		<xsl:variable name="somaResponse" select="dp:soap-call('https://127.0.0.1:5550/service/mgmt/current',$object/*,$sslProxy,0,'',$headers/*)"/>
		<func:result>
			<xsl:copy-of select="$somaResponse"/>
		</func:result>
	</func:function>
</xsl:stylesheet>
