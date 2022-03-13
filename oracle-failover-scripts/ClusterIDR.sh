#!/bin/bash
# Licensed Materials - Property of IBM 
# IBM InfoSphere Change Data Capture
# 5724-U70
# 
# (c) Copyright IBM Corp. 2009 All rights reserved.
# 
# The following sample of source code ("Sample") is owned by International 
# Business Machines Corporation or one of its subsidiaries ("IBM") and is 
# copyrighted and licensed, not sold. You may use, copy, modify, and 
# distribute the Sample in any form without payment to IBM.
# 
# The Sample code is provided to you on an "AS IS" basis, without warranty of 
# any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
# IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
# not allow for the exclusion or limitation of implied warranties, so the above 
# limitations or exclusions may not apply to you. IBM shall not be liable for 
# any damages you suffer as a result of using, copying, modifying or 
# distributing the Sample, even if IBM has been advised of the possibility of 
# such damages.
#
# Start up and down CDC agent
#
# Historia de Cambios
# Versión 2:
#       1) Se incluyó el uso de variables de ambiente CDC_INST_DIR y CDC_STAGING_DIR
#          para que las rutas de instalación y de staging no estuvieran codificadas en
#          el script.  Si las variables ambientales no están definidas, utiliza rutas
#          por omisión.
#       2) TODO: Se agregó validación de existencia de directorios de instalación y staging
#       3) Se retiró la limpieza de stagingstore. Esta solo sería necesario cuando se
#          tiene un incidente mayor en el que dichas áreas pierdan consistencia y
#          dejarlo en el código aumenta el tiempo de switch over innecesariamente
#       4) Se retiró el arranque de mirroring de las suscripciones.  Esta operación solo
#          se requiere cuando explícitamente las suscripciones se han detenido.  Dejar
#          el Start Mirror en el script hace que cuando un operador haya detenido
#          explícitamente unas suscripciones, la operación de switch over las reinicie,
#          desconociendo la intención de quien las detuvo.  Este comportamiento no es el
#          deseado
#       5) Se retiró la detención de las suscripciones por el mismo motivo anterior.
#       6) Se envía comando dmshutdown en forma desconectada para que el proceso
#          no se quede esperando más de lo necesario antes de terminar el stop y
#          se agregó ciclo de espera de terminación hasta un máximo de 20 segundos, al final
#          de los cuales se fuerza un terminado anormal con dmterminate
#       7) Independizar el código del nombre del usuario de CDC.  El script debe ejecutarse con
#          el usuario de instalación/administración de CDC.
#       8) Se dirigió la salida de los comandos con >/dev/null y 2>/dev/null para evitar
#          mensajes innecesarios durante la ejecución.
#
 
check() {
        if [[ $1 == '1' ]] ; then echo "verifica el estado de las instancias " ; fi
        nLines=$(ps -ef | grep dmts64 | grep -v grep | wc -l)
        if ((${nLines} == 0)); then
            if [[ $1 == '1' ]] ; then echo "no hay instancias activas" ; fi
            # no hay agentes activos
            exit 1
        else
            # hay al menos un agente activo.
            if [[ $1 == '1' ]] ; then echo "Hay " $nLines " instancias activas" ; fi
            exit 0
        fi
}
 
start()
{
        #Inicio del ciclo. awk '{print $NF}' imprime la última columna de la salida del comando ls,
        # que corresponde al nombre de la instancia.
        if [[ $1 == '1' ]] ; then echo "arranca instancias:" ; fi
        ls -l $CDC_STAGING_DIR/instance/| grep $LOGNAME | awk '{print $NF}'|while read -r line; do
            if [[ $1 == '1' ]] ; then echo "    arranca la instancia " $line ; fi
                 $CDC_INST_DIR"/bin/dmts64" -I $line > /dev/null 2> /dev/null &
        done
        sleep 2
        check $1
        RETVAL=$?
        return RETVAL
}

stop()
{
        #Inicio del ciclo. awk '{print $NF}' imprime la última columna de la salida del comando ps, en este caso se asume que la
        #ultima columna corresponde al nombre la instancia.
        if [[ $1 == '1' ]] ; then echo "detiene las instancias " ; fi
        ps -ef | grep dmts | grep -v grep | awk '{print $NF}'|while read -r line; do
 
            # Detener las instancias CDC
            if [[ $1 == '1' ]] ; then echo "detiene con dmshudtown la instancia " $line ; fi
            $CDC_INST_DIR"/bin/dmshutdown" -I $line > /dev/null 2> /dev/null &
        done
        #Fin del ciclo
 
        # la terminación se sometió desconectada.  Espera máximo 20 segundos para la terminación de todos los procesos
        TERMINA=false
        for i in {1..5};
        do
            if ! ps -ef | grep dmts | grep -v grep > /dev/null
            then
                TERMINA=true
                break
            fi
            if [[ $1 == '1' ]] ; then echo "espera " $i " segundos" ; fi
            sleep $i
        done
 
        if [ "$TERMINA" == false ]
        then
            # Los procesos no han bajado, entonces los detiene con dmterminate
            if [[ $1 == '1' ]] ; then echo "detiene con dmterminate todas las instancias " ; fi
            $CDC_INST_DIR"/bin/dmterminate" > /dev/null 2> /dev/null
       else
            if [[ $1 == '1' ]] ; then echo "los procesos terminaron rápidamente. No se requiere dmterminate " ; fi
       fi
 
}
 
clean() {
        if [[ $1 == '1' ]] ; then echo "limpia colas para las instancias " ; fi
 
        ls -l $CDC_STAGING_DIR/instance/| grep $LOGNAME | awk '{print $NF}'|while read -r line; do
            # Borrar las colas de transaccion para cada instancia
            if [[ $1 == '1' ]] ; then echo "limpia colas para la instancia " $line ; fi
            echo vacio > $CDC_STAGING_DIR/instance/$line/txnstore/txqueue_vacio
            rm $CDC_STAGING_DIR/instance/$line/txnstore/txqueue*
        done
}
 
# validación número de parámetros recibidos
if (( "$#" == 0 || "$#" > 2 )) ; then
        echo $"Usage: $0 {start|stop|status|clean} [0|1]"
        echo $"where the first parameter is the required operation and"
        echo $"the second parameter is 1 when verbose is required"
        exit 2
fi
 
# Revisión de variables ambientales que definen carpetas de instalación y de staging
if [ -z "$CDC_INST_DIR" ]; then
        CDC_INST_DIR="/cdcbin/ibm/IDR/ReplicationEngineforOracle"
fi
 
if [ -z "$CDC_STAGING_DIR" ]; then
        CDC_STAGING_DIR="/cdcstaging/ibm/IDR/ReplicationEngineforOracle"
fi
 
if [[ $2 == '1' ]]
then
        echo "Directorio de instalación: " $CDC_INST_DIR
        echo "Directorio de tránsito:    " $CDC_STAGING_DIR
fi
 
if [[ $2 == '1' ]] ; then echo "Operación solicitada: " $1 ; fi

case "$1" in
        start)
            if [[ $2 == '1' ]] ; then echo "invoca start" ; fi
            start $2
            RETVAL=$?
            ;;
        stop)
            if [[ $2 == '1' ]] ; then echo "invoca stop" ; fi
            stop $2
            RETVAL=$?
            ;;
        clean)
            if [[ $2 == '1' ]] ; then echo "invoca clean" ; fi
            exit 0
            clean $2
            RETVAL=$?
            ;;
        check)
            if [[ $2 == '1' ]] ; then echo "invoca check" ; fi
            check $2
            RETVAL=$?
            ;;
        *)
            echo $"Usage: $0 {start|stop|check|clean} [1]"
            RETVAL=2
esac
exit $RETVAL
