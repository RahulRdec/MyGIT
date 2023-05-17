<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions">
	<xsl:template match="/">
		<xsl:variable name="xmlMgmtHost" select="'https://127.0.0.1:5550/service/mgmt/current'"/>
		<xsl:variable name="sslProfile" select="'localhost_sslProxyProfile'"/>
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
</xsl:stylesheet>	