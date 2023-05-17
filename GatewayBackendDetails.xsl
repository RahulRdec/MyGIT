<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:dpfunc="http://www.datapower.com/extensions/functions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:dyn="http://exslt.org/dynamic" xmlns:ghu="http://ghu.com" extension-element-prefixes="dp func ghu dpfunc dpconfig date str regexp dyn" exclude-result-prefixes="dp ghu func dpfunc dpconfig date str regexp dyn">
	<xsl:template match="/">
		<xsl:variable name="httpHeaders">
			<header name="Content-Type">application/soap+xml</header>
			<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
		</xsl:variable>
		<xsl:variable name="xmlMgmtHost" select="'https://127.0.0.1:5550/service/mgmt/current'"/>
		<xsl:variable name="sslProfile" select="'localhost_sslProxyProfile'"/>
		<!-- Get Domain Details -->
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
		<xsl:for-each select="$getDomainStatusResponse//Domain">
			<xsl:variable name="domain" select="."/>
			<xsl:variable name="getMPGWNames">
				<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
					<soapenv:Header/>
					<soapenv:Body>
						<man:request domain="{$domain}">
							<man:get-config class="MultiProtocolGateway"/>
						</man:request>
					</soapenv:Body>
				</soapenv:Envelope>
			</xsl:variable>

			<xsl:variable name="getWSPNames">
				<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
					<soapenv:Header/>
					<soapenv:Body>
						<man:request domain="{$domain}">
							<man:get-config class="WSGateway"/>
						</man:request>
					</soapenv:Body>
				</soapenv:Envelope>
			</xsl:variable>
			<xsl:variable name="getMPGWNameResponse" select="dp:soap-call($xmlMgmtHost,$getMPGWNames/*,$sslProfile,0,'',$httpHeaders/*)"/>
			<xsl:variable name="getWSPNamesResponse" select="dp:soap-call($xmlMgmtHost,$getWSPNames/*,$sslProfile,0,'',$httpHeaders/*)"/>
			<MPGWs>
				<xsl:for-each select="$getMPGWNameResponse//MultiProtocolGateway">
					<xsl:variable name="nameMPGW" select="./@name"/>
					<xsl:variable name="backendURL" select="./BackendUrl/text()"/>
					<xsl:message dp:priority="error"> MPG name: <xsl:value-of select="$nameMPGW"/>
					</xsl:message>
					<xsl:message dp:priority="error"> MPG backendURL: <xsl:value-of select="$backendURL"/>
					</xsl:message>
					<MPGW>
						<domain>
							<xsl:value-of select="$domain"/>
						</domain>
						<name>
							<xsl:value-of select="$nameMPGW"/>
						</name>
						<backendURL>
							<xsl:value-of select="$backendURL"/>
						</backendURL>
					</MPGW>
				</xsl:for-each>
			</MPGWs>
			<WSPs>
				<xsl:for-each select="$getWSPNamesResponse//WSGateway">
					<xsl:variable name="nameWSP" select="./@name"/>
					<xsl:variable name="endpointRewritePolicy" select="./EndpointRewritePolicy/text()"/>
					<xsl:variable name="getEndpointRewritePolicy">
						<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
							<soapenv:Header/>
							<soapenv:Body>
								<man:request domain="{$domain}">
									<man:get-config class="WSEndpointRewritePolicy" name="{$endpointRewritePolicy}"/>
								</man:request>
							</soapenv:Body>
						</soapenv:Envelope>
					</xsl:variable>
					<xsl:variable name="getEndpointRewritePolicyResponse" select="dp:soap-call($xmlMgmtHost,$getEndpointRewritePolicy/*,$sslProfile,0,'',$httpHeaders/*)"/>
					<xsl:for-each select="$getEndpointRewritePolicyResponse//WSEndpointRemoteRewriteRule">
						<xsl:variable name="Protocol" select="normalize-space(./RemoteEndpointProtocol/text())"/>
						<xsl:variable name="Host" select="normalize-space(./RemoteEndpointHostname/text())"/>
						<xsl:variable name="Port" select="normalize-space(./RemoteEndpointPort/text())"/>
						<xsl:variable name="URI" select="normalize-space(./RemoteEndpointURI/text())"/>
						<xsl:variable name="endpoint" select="concat($Protocol,'://',$Host,':',$Port,$URI)"/>
						<xsl:message dp:priority="error"> WSP name: <xsl:value-of select="$nameWSP"/>
						</xsl:message>
						<xsl:message dp:priority="error"> WSP backendURL: <xsl:value-of select="$endpoint"/>
						</xsl:message>
						<WSP>
							<domain>
								<xsl:value-of select="$domain"/>
							</domain>
							<name>
								<xsl:value-of select="$nameWSP"/>
							</name>
							<backendURL>
								<xsl:value-of select="$endpoint"/>
							</backendURL>
						</WSP>
					</xsl:for-each>
				</xsl:for-each>
			</WSPs>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
