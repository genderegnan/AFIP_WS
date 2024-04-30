#!/bin/bash
parametros=${@}
parametros=($parametros)

case ${parametros[0]} in 
    1) PedidoCSR ${parametros[*]};;
    2) FirmarCertificado;;
    3) GetOrCreateTA ${parametros[*]} 

esac

function GetOrCreateDir () {

    if [ -d $cuit/ ]; then 
        path=$cuit/
    else 
        mkdir $cuit
        path=$cuit/
    fi
}

function ProductiveTesting () {
    if  [ ${parametros[1]}  = 1 ];then
        url_wsaa="https://wsaa.afip.gov.ar/ws/services/LoginCms?wsdl"
        padron_A5="https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL"
    
    else
        url_wsaa="https://wsaahomo.afip.gov.ar/ws/services/LoginCms"
        padron_A5="https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL"
    fi
}

function GetTokenTA () {
    sign_ticket=$(grep -oP '(;[0-9a-zA-Z\+\=\/]{150,200}&)' <<< $ticket_acceso_xml)
    sign_ticket=$(grep -oP '([0-9a-zA-Z\+\=\/]{150,200})' <<< $sign_ticket)
    token_ticket=$(grep -oP '([0-9a-zA-Z\+\=\/]{200,})' <<< $ticket_acceso_xml)
}

function PedidoCSR () {
    empresa=${parametros[2]} #Nombre de empresa
    cliente=${parametros[3]} #Nombre sistema cliente
    cuit=${parametros[4]}    #Cuit empresa o programador
    echo $empresa $cliente $cuit
    GetOrCreateDir
    
    if ! [ -f $path$cuit.key ];then 
        echo "existe"
        clave_privada=$(openssl genrsa -out $path$cuit.key 2048)
        clave_csr=$(openssl req -new -key $path$cuit.key -subj "/C=AR/O=$empresa/CN=$cliente/serialNumber=CUIT $cuit" -out $path$cuit.csr)
    fi
}

function FirmarCertificado () {
    certificado_pfx=$(openssl pkcs12 -export -inkey $path$cuit.key -in $path$cuit.crt -out $path$cuit.pfx)
}

function GetOrCreateTA () { 
    ProductiveTesting ${parametros[1]} 
    cuit=${parametros[2]}
    cliente=${parametros[3]}
    service=${parametros[4]}
    GetOrCreateDir
    if ! [ -f $path$cuit"_"$service"_TA.xml" ];then 
        ticket_acceso_xml=$(touch $path$cuit"_"$service"_TA.xml")
        ticket_acceso_xml=$(< $path$cuit"_"$service"_TA.xml")
    else
        ticket_acceso_xml=$(< $path$cuit"_"$service"_TA.xml")
    fi
    expiration_time=$(grep -oP '(expirationTime&gt;[0-9|T|\-\:]{10,})' <<< $ticket_acceso_xml)
    expiration_time=$(grep -oP '([0-9|\:|T|-]{10,})' <<< $expiration_time)
    date=$(date +%Y-%m-%dT%H:%M:%S)
    if [[ $expiration_time < $date ]]; then
        unique_id=$(shuf -i 0-4294967295 -n1)
        created=$(date +%Y-%m-%dT%H:%M:%S-03:00)
        expired=$(date +%Y-%m-%dT%H:%M:%S-03:00 --date='+10 hour')
        xml_wsaa='<?xml version="1.0" encoding="UTF-8"?><loginTicketRequest version="1.0"><header><source>serialNumber=CUIT '$cuit', cn='$cliente'</source><destination>CN=wsaa, O=AFIP, C=AR, SERIALNUMBER=CUIT 33693450239</destination><uniqueId>'$unique_id'</uniqueId><generationTime>'$created'</generationTime><expirationTime>'$expired'</expirationTime></header><service>'$service'</service></loginTicketRequest>' #
        echo $xml_wsaa > $path$cuit"_"$service"_TRA.xml"
        rta_wsaa=$(openssl cms -sign -in $path$cuit"_"$service"_TRA.xml" -out $path$cuit"_"$service"_TRA.xml.cms" -signer $path$cuit.crt -inkey $path$cuit.key -nodetach -outform PEM)
        
        rta_wsaa=$(< $path$cuit"_"$service"_TRA.xml.cms")
        access_token_wsaa=$(grep -oP '([A-Za-z0-9\+\/\ \=]{10,5000})' <<< $rta_wsaa)
        access_token_wsaa=$(echo "$access_token_wsaa" | tr -d '[[:space:]]')
        login_cms='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsaa="http://wsaa.view.sua.dvadac.desein.afip.gov"><soapenv:Header/><soapenv:Body><wsaa:loginCms><wsaa:in0>'$access_token_wsaa'</wsaa:in0></wsaa:loginCms></soapenv:Body></soapenv:Envelope>'
        
        ticket_acceso=$(curl -k -v -X POST --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction:urn:LoginCms" --header "User-Agent: Apache-HttpClient/4.1.1 (java 1.5)" --data-binary "$login_cms" --noproxy "*" $url_wsaa > $path$cuit"_"$service"_"TA.xml)
        ticket_acceso_xml=$(< $path$cuit"_"$service"_"TA.xml)
        #echo $access_token_wsaa
    else 
        GetTokenTA
        echo $token_ticket
        echo $sign_ticket
       
    fi
} 