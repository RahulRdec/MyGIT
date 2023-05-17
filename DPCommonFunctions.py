#!/usr/bin/python
#
# reused functions for DataPower script library
# Ken Hygh, khygh@us.ibm.com 6/14/2012
import sys, string, time, http.client
from xml.dom.minidom import parseString
import base64

import ssl

try:
    _create_unverified_https_context = ssl._create_unverified_context
except AttributeError:
    # Legacy Python that doesn't verify HTTPS certificates by default
    pass
else:
    # Handle target environment that doesn't support HTTPS verification
    ssl._create_default_https_context = _create_unverified_https_context

def getText(nodelist):
    rc = []
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            rc.append(node.data)
    return ''.join(rc)

# results can have multiple XML documents when multiple
# dp:request elements are in the request
def showResults(res, actions):
    looper = 0
    start = 39 # length of XML declaration
    index = res.find('</env:Env', start) + 15
    while index > 15:
        aResult = res[start:index]
    #print "'",aResult,"'"
        if aResult.startswith("<env:Envelope"):
            dom = parseString(aResult)
            Nodes = dom.getElementsByTagName("dp:result")
            for node in Nodes:
                print (actions[looper], getText(node.childNodes))
            
            start = start + index
            index = res.find('</env:Env', start) + 15
            start = start - 39
            looper += 1
        else:
            looper += 1
    
    index = res.find('faultstring')
    if index > 0:
        faultstring = res[index + 12:res.find('/faultstring', index) - 1]
        print ("SOAP Fault:", faultstring)



def setHeaders(username,password,server, messageLen):
    #construct and send the headers
    #base64string = base64.b64encode(('%s:%s' % (username, password)).encode('utf-8'))[:-1]
    base64string = "T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU="
    webservice = http.client.HTTPSConnection(server + ":5550")
    webservice.putrequest("POST", "/service/mgmt/current")
    webservice.putheader("Host", server)
    webservice.putheader("Authorization", "Basic %s" % base64string)
    webservice.putheader("User-Agent", "Python post")
    webservice.putheader("Content-type", "text/xml; charset=\"UTF-8\"")
    webservice.putheader("Content-length", "%d" % messageLen)
    webservice.putheader("SOAPAction", "\"\"")
    webservice.endheaders()
    return webservice

def insertNewlines(text, lineLength):
    if len(text) <= lineLength:
        return text
    else:
        return text[:lineLength] + '\n' + insertNewlines(text[lineLength:], lineLength)
