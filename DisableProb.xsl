<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:dpfunc="http://www.datapower.com/extensions/functions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:dyn="http://exslt.org/dynamic" xmlns:ghu="http://ghu.com" extension-element-prefixes="dp func ghu dpfunc dpconfig date str regexp dyn" exclude-result-prefixes="dp ghu func dpfunc dpconfig date str regexp dyn">
	<xsl:template match="/">
		<xsl:variable name="DeviceName" select="/Request/DeviceName/text()"/>
		<!-- Create Checkpoint -->
		<xsl:variable name="CreateCheckpoint">
			<xsl:call-template name="createCheckpoint">
				<xsl:with-param name="DeviceName" select="$DeviceName"/>
			</xsl:call-template>
		</xsl:variable>
		<!-- Disbale DebugMode -->
		<xsl:variable name="disableDebug">
			<xsl:call-template name="disableDebug">
				<xsl:with-param name="DeviceName" select="$DeviceName"/>
			</xsl:call-template>
		</xsl:variable>
	</xsl:template>

	<xsl:template name="createCheckpoint">
		<xsl:variable name="CurrentDateTime">
			<xsl:value-of select="date:date-time()"/>
		</xsl:variable>
		<xsl:variable name="checkpointName" select="translate(concat('SecureBackup_', $CurrentDateTime), '-:', '')"/>
		<xsl:variable name="somaReq">
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="default">
						<man:do-action>
							<SaveCheckpoint>
								<ChkName>
									<xsl:value-of select="$checkpointName"/>
								</ChkName>
							</SaveCheckpoint>
						</man:do-action>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable>
		<xsl:variable name="somaResp" select="ghu:somaCall($somaReq)"/>
		<xsl:copy-of select="$somaResp"/>
		<xsl:message dp:priority="error">Checkpoint soma request :: <xsl:copy-of select="$somaReq"/>
		</xsl:message>
	</xsl:template>

	<xsl:template name="disableDebug">
		<xsl:variable name="xmlMgmtHost" select="/Request/xmlMgmtHost/text()"/>
		<xsl:variable name="sslProfile" select="/Request/sslProfile/text()"/>
		<xsl:variable name="httpHeaders">
			<header name="Content-Type">application/soap+xml</header>
			<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
		</xsl:variable>
		<!-- Get a list of all domains using Domain Status -->
		<xsl:variable name="domainStatus">
			<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
				<soap:Body>
					<mgmt:request xmlns:mgmt="http://www.datapower.com/schemas/management" domain="default">
						<mgmt:get-status class="DomainStatus" />
					</mgmt:request>
				</soap:Body>
			</soap:Envelope>
		</xsl:variable>
		<xsl:variable name="getDomainStatusResponse" select="dp:soap-call($xmlMgmtHost,$domainStatus/*,$sslProfile,0,'',$httpHeaders/*)"/>
		<!-- <xsl:message dp:priority="debug">getDomainStatusResponse '<xsl:value-of select="$getDomainStatusResponse"/>' </xsl:message>	 -->
		<!-- Get list of all MPGW from each domains -->
		<xsl:for-each select="$getDomainStatusResponse//Domain">
			<xsl:variable name="domain" select="."/>
			<xsl:variable name="getMPGList">
				<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
					<soapenv:Header/>
					<soapenv:Body>
						<man:request domain="{$domain}">
							<man:get-config class="MultiProtocolGateway"/>
						</man:request>
					</soapenv:Body>
				</soapenv:Envelope>
			</xsl:variable>
			<xsl:variable name="getMPGListResponse" select="dp:soap-call($xmlMgmtHost,$getMPGList/*,$sslProfile,0,'',$httpHeaders/*)"/>
			<!-- <xsl:message dp:priority="debug">getMPGListResponse: '<xsl:value-of select="$getMPGListResponse"/>'</xsl:message> -->
			<xsl:for-each select="$getMPGListResponse//MultiProtocolGateway">
				<xsl:variable name="MPGName" select="./@name"/>
				<xsl:variable name="disableMPGDebug">
					<soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
						<soapenv:Header/>
						<soapenv:Body>
							<man:request domain="{$domain}">
								<man:modify-config>
									<MultiProtocolGateway name="{$MPGName}">
										<DebugMode>off</DebugMode>
									</MultiProtocolGateway>
								</man:modify-config>
							</man:request>
						</soapenv:Body>
					</soapenv:Envelope>
				</xsl:variable>
				<xsl:variable name="disableMPGDebugResponse" select="dp:soap-call($xmlMgmtHost,$disableMPGDebug/*,$sslProfile,0,'',$httpHeaders/*)"/>
				<!-- <xsl:message dp:priority="debug">disableMPGDebugResponse: '<xsl:value-of select="$getMPGListResponse"/>'</xsl:message> -->
			</xsl:for-each>
			<!-- Disbale DebugMode for WSP for all domains -->
			<xsl:variable name="getWSPList">
				<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
					<soapenv:Header/>
					<soapenv:Body>
						<man:request domain="{$domain}">
							<man:get-config class="WSGateway"/>
						</man:request>
					</soapenv:Body>
				</soapenv:Envelope>
			</xsl:variable>
			<xsl:variable name="getWSPListResponse" select="dp:soap-call($xmlMgmtHost,$getWSPList/*,$sslProfile,0,'',$httpHeaders/*)"/>

			<xsl:for-each select="$getWSPListResponse//WSGateway">
				<xsl:variable name="WSPName" select="./@name"/>
				<xsl:variable name="disableWSPDebug">
					<soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
						<soapenv:Header/>
						<soapenv:Body>
							<man:request domain="{$domain}">
								<man:modify-config>
									<WSGateway name="{$WSPName}">
										<DebugMode>off</DebugMode>
									</WSGateway>
								</man:modify-config>
							</man:request>
						</soapenv:Body>
					</soapenv:Envelope>
				</xsl:variable>
				<xsl:variable name="disableWSPDebugResponse" select="dp:soap-call($xmlMgmtHost,$disableWSPDebug/*,$sslProfile,0,'',$httpHeaders/*)"/>
			</xsl:for-each>
			<xsl:variable name="getXMLFWList">
				<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
					<soapenv:Header/>
					<soapenv:Body>
						<man:request domain="{$domain}">
							<man:get-config class="XMLFirewallService"/>
						</man:request>
					</soapenv:Body>
				</soapenv:Envelope>
			</xsl:variable>
			<xsl:variable name="getXMLFWListResponse" select="dp:soap-call($xmlMgmtHost,$getXMLFWList/*,$sslProfile,0,'',$httpHeaders/*)"/>

			<xsl:for-each select="$getXMLFWListResponse//XMLFirewallService">
				<xsl:variable name="XMLFWName" select="./@name"/>
				<xsl:variable name="disableXMLFWDebug">
					<soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
						<soapenv:Header/>
						<soapenv:Body>
							<man:request domain="{$domain}">
								<man:modify-config>
									<XMLFirewallService name="{$XMLFWName}">
										<DebugMode>off</DebugMode>
									</XMLFirewallService>
								</man:modify-config>
							</man:request>
						</soapenv:Body>
					</soapenv:Envelope>
				</xsl:variable>
				<xsl:variable name="disableXMLFWDebugResponse" select="dp:soap-call($xmlMgmtHost,$disableXMLFWDebug/*,$sslProfile,0,'',$httpHeaders/*)"/>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<func:function name="ghu:somaCall">
		<xsl:param name="object"/>
		<xsl:variable name="xmlMgmtHost" select="/Request/xmlMgmtHost/text()"/>
		<xsl:variable name="sslProfile" select="/Request/sslProfile/text()"/>
		<xsl:variable name="headers">
			<header name="Content-Type">application/soap+xml</header>
			<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
		</xsl:variable>
		<xsl:variable name="somaResponse" select="dp:soap-call($xmlMgmtHost,$object/*,$sslProxy,0,'',$headers/*)"/>
		<func:result>
			<xsl:copy-of select="$somaResponse"/>
		</func:result>
	</func:function>
</xsl:stylesheet>
