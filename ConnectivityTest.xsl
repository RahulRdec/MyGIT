<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:dpfunc="http://www.datapower.com/extensions/functions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:dyn="http://exslt.org/dynamic" xmlns:ghu="http://ghu.com" extension-element-prefixes="dp func ghu dpfunc dpconfig date str regexp dyn" exclude-result-prefixes="dp ghu func dpfunc dpconfig date str regexp dyn">
	<xsl:template match="/">
		<xsl:variable name="domainName" select="/Request/DomainName/text()"/>
		<!-- <xsl:variable name="allWSPRewritePolicies"> -->
			<!-- <xsl:call-template name="getConfigAll"> -->
				<!-- <xsl:with-param name="objectClass" select="'WSEndpointRewritePolicy'"/> -->
				<!-- <xsl:with-param name="domainName" select="$domainName"/> -->
			<!-- </xsl:call-template> -->
		<!-- </xsl:variable> -->
		<xsl:variable name="allMPGWs">
			<xsl:call-template name="getConfigAll">
				<xsl:with-param name="objectClass" select="'MultiProtocolGateway'"/>
				<xsl:with-param name="domainName" select="$domainName"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:message dp:priority="debug">Starting for MPGWs</xsl:message>
		<MPGWs>
			<xsl:for-each select="$allMPGWs//MultiProtocolGateway">
				<xsl:variable name="nameMPGW" select="./@name"/>
				<xsl:variable name="backendURL" select="./BackendUrl/text()"/>
				<xsl:variable name="backendURLIP" select="substring-before(substring-after($backendURL,'://'),':')"/>
				<xsl:variable name="backendURLPort" select="substring-before(substring-after(substring-after($backendURL,'://'),':'),'/')"/>
				<xsl:variable name="TCPConnectionRespose">
					<xsl:call-template name="TCPTest">
						<xsl:with-param name="remoteHost" select="$backendURLIP"/>
						<xsl:with-param name="remotePort" select="$backendURLPort"/>
						<xsl:with-param name="domainName" select="$domainName"/>
					</xsl:call-template>
				</xsl:variable>
				<MPGW>
					<name>
						<xsl:value-of select="$nameMPGW"/>
					</name>
					<remoteHost>
						<xsl:value-of select="$backendURL"/>
					</remoteHost>
					<ConnectionResult>
						<xsl:copy-of select="$TCPConnectionRespose"/>
					</ConnectionResult>
				</MPGW>
			</xsl:for-each>
		</MPGWs>
	</xsl:template>

	<xsl:template name="TCPTest">
		<xsl:param name="remoteHost" select="''"/>
		<xsl:param name="remotePort" select="''"/>
		<xsl:param name="domainName" select="''"/>
		<xsl:variable name="somaReq">
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="{$domainName}">
						<man:do-action>
							<TCPConnectionTest>
								<RemoteHost>
									<xsl:value-of select="$remoteHost"/>
								</RemoteHost>
								<RemotePort>
									<xsl:value-of select="$remotePort"/>
								</RemotePort>
							</TCPConnectionTest>
						</man:do-action>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable>
		<xsl:variable name="somaResp" select="ghu:somaCall($somaReq)"/>
		<xsl:copy-of select="$somaResp"/>
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
		<xsl:variable name="somaResp" select="ghu:somaCall($somaReq)"/>
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
		<xsl:variable name="somaResp" select="ghu:somaCall($somaReq)"/>
		<xsl:copy-of select="$somaResp"/>
	</xsl:template>

	<func:function name="ghu:somaCall">
		<xsl:param name="object"/>
		<xsl:variable name="url" select="'https://127.0.0.1:5550/service/mgmt/current'"/>
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
