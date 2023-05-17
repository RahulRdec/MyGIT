<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:dpfunc="http://www.datapower.com/extensions/functions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:dyn="http://exslt.org/dynamic" xmlns:ghu="http://ghu.com" extension-element-prefixes="dp func ghu dpfunc dpconfig date str regexp dyn" exclude-result-prefixes="dp ghu func dpfunc dpconfig date str regexp dyn">
	<xsl:template match="/">
		<xsl:variable name="domainNames">
			<xsl:call-template name="fetchDomainNames"/>
		</xsl:variable>
		<xsl:for-each select="$domainNames//Domain">
			<xsl:variable name="domainName" select="."/>
			<xsl:message dp:priority="debug">Domain name is ::: <xsl:value-of select="$domainName"/></xsl:message>
			<xsl:variable name="cryptoCerts">
				<xsl:call-template name="getConfigAll">
					<xsl:with-param name="objectClass" select="'CryptoCertificate'"/>
					<xsl:with-param name="domainName" select="$domainName"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:for-each select="$cryptoCerts//CryptoCertificate">
				<xsl:variable name="cryptoCertName" select="./@name"/>
				<xsl:message dp:priority="debug">Crypto Cert Object is ::: <xsl:value-of select="$cryptoCertName"/></xsl:message>
				<xsl:variable name="certificateName" select="./Filename/text()"/>
				<xsl:message dp:priority="debug">cert name is ::: <xsl:value-of select="$certificateName"/></xsl:message>
				<xsl:variable name="exportObjectName" select="concat(substring-after($certificateName,'///'),'.txt')"/>
				<xsl:message dp:priority="debug">File will be exported with name::: <xsl:value-of select="$exportObjectName"/></xsl:message>
				<xsl:variable name="exportObjects">
					<xsl:call-template name="CryptoExport">
						<xsl:with-param name="domainName" select="$domainName"/>
						<xsl:with-param name="objectName" select="$cryptoCertName"/>
						<xsl:with-param name="outputObjectName" select="$exportObjectName"/>
					</xsl:call-template>
				</xsl:variable>
			</xsl:for-each>
		</xsl:for-each>

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

	<xsl:template name="fetchDomainNames">
		<xsl:variable name="somaReq">
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="default">
						<man:get-status class="DomainStatus"/>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable>
		<xsl:variable name="somaResp" select="ghu:somaCall($somaReq)"/>
		<xsl:copy-of select="$somaResp"/>
	</xsl:template>

	<xsl:template name="CryptoExport">
		<xsl:param name="domainName" select="''"/>
		<xsl:param name="objectName" select="''"/>
		<xsl:param name="outputObjectName" select="''"/>
		<xsl:variable name="cryptoExportSomaReq">
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="{$domainName}">
						<man:do-action>
							<CryptoExport>
								<ObjectType>cert</ObjectType>
								<ObjectName>
									<xsl:value-of select="$objectName"/>
								</ObjectName>
								<OutputFilename>
									<xsl:value-of select="$outputObjectName"/>
								</OutputFilename>
								<Mechanism/>
							</CryptoExport>
						</man:do-action>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable>

		<xsl:variable name="somaResp" select="ghu:somaCall($cryptoExportSomaReq)"/>
		<xsl:copy-of select="$somaResp"/>
		<xsl:message dp:priority="debug">Soma request to export object is ::: <xsl:copy-of select="$cryptoExportSomaReq"/></xsl:message>
		<xsl:message dp:priority="debug">response of export object is ::: <xsl:copy-of select="$somaResp"/></xsl:message>
	</xsl:template>

	<func:function name="ghu:somaCall">
		<xsl:param name="object"/>
		<xsl:variable name="url" select="'https://127.0.0.1:4461/service/mgmt/current'"/>
		<xsl:variable name="sslProxy" select="'soma-ssl'"/>
		<xsl:variable name="headers">
			<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
		</xsl:variable>
		<xsl:variable name="somaResponse" select="dp:soap-call('https://127.0.0.1:4461/service/mgmt/current',$object/*,$sslProxy,0,'',$headers/*)"/>
		<func:result>
			<xsl:copy-of select="$somaResponse"/>
		</func:result>
	</func:function>
</xsl:stylesheet>
