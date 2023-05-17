<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:dpfunc="http://www.datapower.com/extensions/functions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:dyn="http://exslt.org/dynamic" xmlns:ghu="http://ghu.com" extension-element-prefixes="dp func ghu dpfunc dpconfig date str regexp dyn" exclude-result-prefixes="dp ghu func dpfunc dpconfig date str regexp dyn">
	<xsl:template match="/">
		<xsl:variable name="domainNames">
			<xsl:call-template name="fetchDomainNames"/>
		</xsl:variable>
		<xsl:for-each select="$domainNames//Domain">
			<xsl:variable name="domainName" select="."/>
			<xsl:if test="$domainName != 'default'">

				<xsl:message dp:priority="debug">Domain name is ::: <xsl:value-of select="$domainName"/>
				</xsl:message>
				<xsl:variable name="saveCheckPoint">
					<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
						<soapenv:Header/>
						<soapenv:Body>
							<man:request domain="{$domainName}">
								<man:do-action>
									<SaveCheckpoint>
										<ChkName>CertChange</ChkName>
									</SaveCheckpoint>
								</man:do-action>
							</man:request>
						</soapenv:Body>
					</soapenv:Envelope>
				</xsl:variable>
				<xsl:variable name="somaSaveCheckPoint" select="ghu:somaCall($saveCheckPoint)"/>
				<xsl:variable name="createCryptoCerts">
					<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
						<soapenv:Header/>
						<soapenv:Body>
							<man:request domain="{$domainName}">
								<man:set-config>
									<CryptoCertificate name="mutpoInternalPolicyCA_Exp04162027_cert" xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:dp="http://www.datapower.com/schemas/management">
										<mAdminState>enabled</mAdminState>
										<Filename>sharedcert:///mutpoInternalPolicyCA_Exp04162027.cer</Filename>
										<PasswordAlias>off</PasswordAlias>
										<IgnoreExpiration>off</IgnoreExpiration>
									</CryptoCertificate>
									<CryptoCertificate name="mutpoIssuingCA2_SHA2_Exp06072023_cert" xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:dp="http://www.datapower.com/schemas/management">
										<mAdminState>enabled</mAdminState>
										<Filename>sharedcert:///mutpoIssuingCA2_SHA2_Exp06072023.cer</Filename>
										<PasswordAlias>off</PasswordAlias>
										<IgnoreExpiration>off</IgnoreExpiration>
									</CryptoCertificate>
									<CryptoCertificate name="mutpoRootCA_Exp04162040_cert" xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:dp="http://www.datapower.com/schemas/management">
										<mAdminState>enabled</mAdminState>
										<Filename>sharedcert:///mutpoRootCA_Exp04162040.cer</Filename>
										<PasswordAlias>off</PasswordAlias>
										<IgnoreExpiration>off</IgnoreExpiration>
									</CryptoCertificate>
								</man:set-config>
							</man:request>
						</soapenv:Body>
					</soapenv:Envelope>
				</xsl:variable>
				<xsl:variable name="somaCreateCryptoCerts" select="ghu:somaCall($createCryptoCerts)"/>
				<xsl:variable name="getConfigAllIdCred">
					<xsl:call-template name="getConfigAll">
						<xsl:with-param name="objectClass" select="'CryptoIdentCred'"/>
						<xsl:with-param name="domainName" select="$domainName"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:for-each select="$getConfigAllIdCred//CryptoIdentCred">
					<xsl:variable name="idCredName" select="./@name"/>
					<xsl:variable name="cryptoCert" select="./Certificate/text()"/>
					<xsl:variable name="cryptoKey" select="./Key/text()"/>
					<xsl:variable name="adminState" select="./mAdminState/text()"/>

					<xsl:variable name="recreateIDCred">
						<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
							<soapenv:Header/>
							<soapenv:Body>
								<man:request domain="{$domainName}">
									<man:modify-config>
										<CryptoIdentCred name="{$idCredName}" xmlns:env="http://www.w3.org/2003/05/soap-envelope">
											<mAdminState>
												<xsl:value-of select="$adminState"/>
											</mAdminState>
											<Key class="CryptoKey">
												<xsl:value-of select="$cryptoKey"/>
											</Key>
											<Certificate class="CryptoCertificate">
												<xsl:value-of select="$cryptoCert"/>
											</Certificate>
											<CA class="CryptoCertificate">mutpoIssuingCA2_SHA2_Exp06072023_cert</CA>
											<CA class="CryptoCertificate">mutpoRootCA_Exp04162040_cert</CA>
											<CA class="CryptoCertificate">mutpoInternalPolicyCA_Exp04162027_cert</CA>
										</CryptoIdentCred>
									</man:modify-config>
								</man:request>
							</soapenv:Body>
						</soapenv:Envelope>
					</xsl:variable>
					<xsl:variable name="somaCreateIDCred" select="ghu:somaCall($recreateIDCred)"/>
				</xsl:for-each>

			</xsl:if>
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
