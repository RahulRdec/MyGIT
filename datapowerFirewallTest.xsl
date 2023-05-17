<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:ghu="http://ghu.com" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:mgmt="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" extension-element-prefixes="dp func ghu" exclude-result-prefixes="dp ghu func">
	<xsl:template match="/">
		<xsl:variable name="DPDevices" select="document('datapowerProdDevices.xml')"/>
		<xsl:variable name="incomingURI" select="dp:variable('var://service/URI')"/>
		<xsl:variable name="IP" select="substring-before(substring-after($incomingURI,'://'),':')"/>
		<xsl:variable name="Port" select="substring-before(substring-after(substring-after($incomingURI,'://'),':'),'/')"/>

		<xsl:variable name="somaReq">
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="default">
						<man:do-action>
							<TCPConnectionTest>
								<RemoteHost>
									<xsl:value-of select="$IP"/>
								</RemoteHost>
								<RemotePort>
									<xsl:value-of select="$Port"/>
								</RemotePort>
							</TCPConnectionTest>
						</man:do-action>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable>
		<!-- <xsl:message dp:priority="error">SOMA Req <xsl:copy-of select="$somaReq"/></xsl:message> -->
		<xsl:for-each select="$DPDevices//device">
			<xsl:variable name="xmlmgmthost" select="."/>
			<xsl:variable name="remoteHost" select="substring-before(substring-after($xmlmgmthost,'://'),':')"/>

			<xsl:variable name="httpHeaders">
				<header name="Content-Type">application/soap+xml</header>
				<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
			</xsl:variable>

			<xsl:variable name="TCPConnectionResponse" select="dp:soap-call($xmlmgmthost,$somaReq/*,'ldap_ssl',0,'',$httpHeaders/*)"/>
			<!-- <xsl:message dp:priority="error">TCPConnectionResponse <xsl:copy-of select="$TCPConnectionResponse"/> -->
			<!-- </xsl:message> -->

			<!-- Prepare response -->
			<xsl:text> Firewall Test Result on DataPower Device </xsl:text>
			<xsl:value-of select="$remoteHost"/>
			<xsl:text> is : </xsl:text>
			<xsl:value-of select="$TCPConnectionResponse//*[local-name()='Envelope']/*[local-name()='Body']/*[local-name()='response']/*[local-name()='result']"/>
			<xsl:text>&#10;</xsl:text>
		</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>
