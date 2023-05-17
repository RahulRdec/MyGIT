#!/usr/bin/python
# List Domains on a DP appliance

import sys
import re
import base64
from xml.dom.minidom import parseString
from optparse import OptionParser
from DPCommonFunctions import setHeaders
from DPCommonFunctions import insertNewlines


# parser = OptionParser("usage: %prog")
# parser.add_option("-u", "--userid", dest="username", help="userid")
# parser.add_option("-p", "--password", dest="password", help="password")
# parser.add_option("-s", "--server", dest="server", help="datapower server name")
# parser.add_option("-z", "--parameterFile", dest="file", help="parameter filename")
# (options, args) = parser.parse_args()

# if options.file != None:
#    try:
#        options.read_file(options.file)
#    except IOError:
#        print "Could not open '" + options.file + "', exiting."
#        sys.exit(4)

somaDomainStatus = """<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
        <mgmt:request xmlns:mgmt="http://www.datapower.com/schemas/management" domain="default">
            <mgmt:get-status class="DomainStatus" />
        </mgmt:request>
    </soap:Body>
</soap:Envelope>
"""

somaGetFileStore = """<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
   <soapenv:Header/>
   <soapenv:Body>
      <man:request domain="%s">
         <man:get-filestore location="temporary:" annotated="false" layout-only="false" no-subdirectories="true"/>
      </man:request>
   </soapenv:Body>
</soapenv:Envelope>
"""

somaGetFile = """<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
   <soapenv:Header/>
   <soapenv:Body>
      <man:request domain="%s">
         <man:get-file name="temporary:///%s"/>
      </man:request>
   </soapenv:Body>
</soapenv:Envelope>
"""


# construct and send the headers
webservice = setHeaders("OffShore_SecBkup", "L@g!n$afe", "10.87.27.21", len(somaDomainStatus))
webservice.send(somaDomainStatus.encode('utf-8'))

# get the response for domain listing
r1 = webservice.getresponse()
res = r1.read()
print("Response: ", r1.status)
print("Reason: ", r1.reason)
print("Response Payload : ", res)

dom = parseString(res)
# fetch the nodelist with element names DomainStatus
fileNodes = dom.getElementsByTagName("DomainStatus")
# iterate over the contents of nodelist for each of the domain name
for domainNode in fileNodes:
    nameNodes = domainNode.getElementsByTagName("Domain")[:1]
    domainName = nameNodes[0].childNodes[0].data
    print("Domain Name is ::::: ", domainName)
    if domainName != 'default':
        getFileStoreReq = somaGetFileStore % (domainName)
        getFileStore = setHeaders("OffShore_SecBkup", "L@g!n$afe", "10.87.27.21", len(getFileStoreReq))
        getFileStore.send(getFileStoreReq.encode('utf-8'))
        resGetFileStore = getFileStore.getresponse()
        resGetFileStoreData = resGetFileStore.read()
        domResGetFileStore = parseString(resGetFileStoreData)
        nodeFileStore = domResGetFileStore.getElementsByTagName("file")
        for file in nodeFileStore:
            fileName = file.getAttribute('name')
            getFileReq = somaGetFile % (domainName, fileName)
            getFile = setHeaders("OffShore_SecBkup", "L@g!n$afe", "10.87.27.21", len(getFileReq))
            getFile.send(getFileReq.encode('utf-8'))
            resGetFile = getFile.getresponse()
            resGetFileData = resGetFile.read()
            domResGetFile = parseString(resGetFileData)
            nodeFile = domResGetFile.getElementsByTagNameNS("http://www.datapower.com/schemas/management", "file")
            for file1 in nodeFile:
                file1Name = file1.getAttribute('name')
                downloadFileName = file1Name.split("temporary:///")[1].split(".txt")[0]
                file1Contents = file1.childNodes[0].data
                decodedfile1Contents = base64.standard_b64decode(file1Contents)
                domCertContents = parseString(decodedfile1Contents)
                certContents = domCertContents.getElementsByTagName("certificate")
                certContentsData = certContents[0].childNodes[0].data
                certContentsDataFormaated = insertNewlines(certContentsData,64)
                FILE = open(downloadFileName, "w")
                FILE.write("-----BEGIN CERTIFICATE-----\n")
                FILE.write(certContentsDataFormaated)
                FILE.write("\n-----END CERTIFICATE-----")
                FILE.close()


