# AFIP_WS
# Instrucciones de Ejecución para Afip.sh

Este archivo README proporciona instrucciones detalladas sobre cómo ejecutar el script `Afip.sh`, que contiene un conjunto de opciones para interactuar con los servicios de AFIP.

## Requisitos Previos

- Tener instalado Bash en tu sistema.
- Tener permisos de ejecución para el script `Afip.sh`.

## Ejecución del Script

Para ejecutar el script `Afip.sh`, sigue las siguientes instrucciones:

### Opción 1: Generar Certificado CRS

Esta opción te permite generar el certificado CRS necesario para interactuar con los servicios de AFIP.

```bash
. Afip.sh 1 <ambiente> "<nombre_de_empresa>" "<nombre_de_sistema_cliente>" "<CUIT_empresa_o_programador>"
Donde:
    <ambiente>: Puede ser 1 para producción o cualquier otro valor para entorno de testing.
    <nombre_de_empresa>: Nombre de la empresa que solicita el certificado.
    <nombre_de_sistema_cliente>: Nombre del sistema cliente que utilizará el certificado.
    <CUIT_empresa_o_programador>: CUIT de la empresa o programador.
Después de generar el certificado, sigue las instrucciones proporcionadas en este enlace.

Opción 2: Firmar Certificado
Una vez generado el certificado, puedes firmarlo utilizando esta opción.
. Afip.sh 2
Opción 3: Generar Certificado para Consumir Web Service
Esta opción te permite generar un certificado para consumir un web service específico de AFIP.
. Afip.sh 3 <ambiente> "<empresa>" "<CUIT>" "<cliente>" "<web_service_a_consumir>"
Donde:
    <ambiente>: Puede ser 1 para producción o cualquier otro valor para entorno de testing.
    <empresa>: Nombre de la empresa.
    <CUIT>: CUIT de la empresa.
    <cliente>: Nombre del cliente.
    <web_service_a_consumir>: Nombre del web service que deseas consumir.
Este comando devolverá el access token necesario para consumir el servicio indicado.

Ejemplo de Uso
. Afip.sh 3 2 "empresa" 22222222222 "cliente" "ws_sr_padron_a1"