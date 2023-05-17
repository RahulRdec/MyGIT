<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:dpfunc="http://www.datapower.com/extensions/functions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:dyn="http://exslt.org/dynamic" xmlns:ghu="http://ghu.com" extension-element-prefixes="dp func ghu dpfunc dpconfig date str regexp dyn" exclude-result-prefixes="dp ghu func dpfunc dpconfig date str regexp dyn">
	<xsl:output method = "text"/>
	<xsl:template match="/">
		<xsl:variable name="DPDevices" select="document('datapowerProdDevices.xml')"/>

		<xsl:for-each select="$DPDevices//device">
			<xsl:variable name="xmlmgmthost" select="."/>

			<xsl:variable name="httpHeaders">
				<header name="Content-Type">application/soap+xml</header>
				<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
			</xsl:variable>

			<xsl:variable name="domainStatus">
				<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
					<soap:Body>
						<mgmt:request xmlns:mgmt="http://www.datapower.com/schemas/management" domain="default">
							<mgmt:get-status class="DomainStatus" />
						</mgmt:request>
					</soap:Body>
				</soap:Envelope>
			</xsl:variable>

			<!-- <xsl:text>Disabling probes. It will take few mins.</xsl:text> -->
			<xsl:variable name="getDomainStatusResponse" select="dp:soap-call($xmlmgmthost,$domainStatus/*,'ldap_ssl',0,'',$httpHeaders/*)"/>

			<!-- For MultiProtocolGateway -->
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
				<xsl:variable name="getMPGListResponse" select="dp:soap-call($xmlmgmthost,$getMPGList/*,'ldap_ssl',0,'',$httpHeaders/*)"/>

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
					<xsl:variable name="disableMPGDebugResponse" select="dp:soap-call($xmlmgmthost,$disableMPGDebug/*,'ldap_ssl',0,'',$httpHeaders/*)"/>
				</xsl:for-each>

				<!-- For WS Gateways -->
				<xsl:variable name="getWSGList">
					<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
						<soapenv:Header/>
						<soapenv:Body>
							<man:request domain="{$domain}">
								<man:get-config class="WSGateway"/>
							</man:request>
						</soapenv:Body>
					</soapenv:Envelope>
				</xsl:variable>
				<xsl:variable name="getWSGListResponse" select="dp:soap-call($xmlmgmthost,$getWSGList/*,'ldap_ssl',0,'',$httpHeaders/*)"/>

				<xsl:for-each select="$getWSGListResponse//WSGateway">
					<xsl:variable name="WSGName" select="./@name"/>
					<xsl:variable name="disableWSGDebug">
						<soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
							<soapenv:Header/>
							<soapenv:Body>
								<man:request domain="{$domain}">
									<man:modify-config>
										<WSGateway name="{$WSGName}">
											<DebugMode>off</DebugMode>
										</WSGateway>
									</man:modify-config>
								</man:request>
							</soapenv:Body>
						</soapenv:Envelope>
					</xsl:variable>
					<xsl:variable name="disableWSGDebugResponse" select="dp:soap-call($xmlmgmthost,$disableWSGDebug/*,'ldap_ssl',0,'',$httpHeaders/*)"/>
				</xsl:for-each>
			</xsl:for-each>
		</xsl:for-each>
		<xsl:text>Probe disabled successfully for all Gateways.</xsl:text>
	</xsl:template>
</xsl:stylesheet>
