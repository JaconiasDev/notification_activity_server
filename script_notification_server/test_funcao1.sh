#====================================================
# ARQUIVOS DE CONTROLE
#====================================================
USER=$(whoami)    # usuario atual 
TOKEN=""          # TOKEN DO BOT 
CHANNEL_ID=""     # CHANNEL_ID (ENDERECO DE CANAL)


if [ ! -d  "/home/$USER/logs_script_alert_server" ]; then mkdir /home/$USER/logs_script_alert_server ; fi

LAST_RUN_FILE="/home/$USER/logs_script_alert_server/_ssh_monitor_last_run" # mude pra /tmp porem pode perder ref
SCRIPT_LOG="/home/$USER/logs_script_alert_server/_ssh_monitor.log"
LIMITE_TENTATIVAS=5

#=====================================================
# FUNCAO DE LOG
#=====================================================

log () {
   
   if [[ -z "$1" || "$1" == "." ]]; then 
      echo -e "\n" >> "$SCRIPT_LOG"
   else
      echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a  "$SCRIPT_LOG"
   fi

}

#====================================================
# FUNCAO MSG PRA O BOT DISCORD
#====================================================
 
 messager_bot () {

     local TEXTO_PARA_JSON=$(echo "$1" | sed ':a;N;$!ba;s/\n/\\n/g')

     curl -X POST "https://discord.com/api/v10/channels/${CHANNEL_ID}/messages" \
      -H "Authorization: Bot ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"content\": \"$TEXTO_PARA_JSON\"}" 2>/dev/null | grep -q "channel_id";

    local DATE2=$(date '+%Y-%m-%d  %H:%M:%S')

    log " - Messagem Enviada ao Bot as [ $DATE2 ]"

 }


#======================================================
# LER O TIMESTEMP DA ULTIMA EXECUSAO (LAST_RUN_FILE)
#======================================================
  
if [ -f "${LAST_RUN_FILE}" ]; then 
      
    FROM_TIMESTEMP=$(cat $LAST_RUN_FILE)
    log " - lendo a linha que ja tem Log [timestemp] - $FROM_TIMESTEMP : " # vai pra o arquivo de log

else 

    FROM_TIMESTEMP=$(date -d "1 hour ago " "+%Y-%m-%d %H:%M:%S") #  se esse arquivo nao existir criar ele e add o timestemp de 1 hora atras 
    log " - primeira execusao - usando timestemp inicial : $FROM_TIMESTEMP "

    echo "$FROM_TIMESTEMP" > "$LAST_RUN_FILE"

fi


# atualiza o timestemp - pega o timestemp atual da hora da execusao 
# grava no arquivo de log
TO_TIMESTEMP=$(date "+%Y-%m-%d %H:%M:%S" )
log " - analisando logs do periodo [ ${FROM_TIMESTEMP} ] ate  [ ${TO_TIMESTEMP} ]"


#========================================================
# BUSCA LOGS APENAS NO INTERVALO DEFINIDO 
#========================================================


LINHAS_LOGS_SSH=$(journalctl -u sshd --since "$FROM_TIMESTEMP" --no-page 2>/dev/null ) # --until 

QTD_LINHAS=$(echo "$LINHAS_LOGS_SSH" | wc -l)


if [[ "$QTD_LINHAS" -lt 2  ]]; then 

    log " - nenhum log encontrado no periodo de [ $FROM_TIMESTEMP ] - [ $TO_TIMESTEMP ]"

    echo "$TO_TIMESTEMP" > "$LAST_RUN_FILE" # ATUALIZA O TIMESTEMP PRA AGORA ( HORA DESSA EXECUSAO )

    log " - Timestemp atualizado para [ $TO_TIMESTEMP ]"

else

    #===========================================================
    # ANALISANDO LINHAS E VERIFICANDO COMEXOES BEM-SUCEDIDAS
    #===========================================================

    log " - logs encontrados [ $QTD_LINHAS ] - linhas de log"

    CONEXOES=$(echo "$LINHAS_LOGS_SSH" | grep "Accepted ")


    if [[ -n "$CONEXOES" ]]; then 

      log " - Conexoes Bem-Sucedida no servico de SSH \u2714 "

      # abre apenas um processo

        while read -r linha; do

          # Usamos o 'read' para capturar a saída do awk em variáveis locais
          read -r DATE USUARIO IP PORT METODO <<< $(echo "$linha" | sed 's@::1@127.0.0.1@g' | awk '{print $3, $9, $11, $13, $7}')

          # Agora  montaMOS a mensagem usando as variáveis que acabou de preencher

          MENSAGEM=$(printf "\n[+] - CONEXOES SSH BEM-SUCEDIDA \U2705 \n[+] - Usuário: %s\n[+] - IP: %s\n[+] - Método: %s\n[+] - Porta: %s\n[+] - Horário: %s\n==============================" "$USUARIO" "$IP" "$METODO" "$PORT" "$DATE")
          
          log " - enviando msg para o bot "

          # funcao que envia dados pra o discord!
          messager_bot "$MENSAGEM"

          log "$MENSAGEM"

        done <<< "$CONEXOES"
    else

        log " - nenhuma conexao bem sucedida durante o periodo de $FROM_TIMESTEMP  a $TO_TIMESTEMP "

    fi


    #=============================================================
    # VERIFICAR TENTATIVAS DE FORCA BRUTA 
    #=============================================================

    log " - iniciando Teste de Tentativa de forca bruta"

    FALHAS=$( echo "$LINHAS_LOGS_SSH" | grep "Failed password")

    if [ -n "$FALHAS" ]; then 
      
      TENTATIVAS_FALHAS=$( echo "$FALHAS" | wc -l ) # linhas de erro em num ( 5 linhas com erro )

        log " - Foram encontrados $TENTATIVAS_FALHAS Failed password "

          echo "$FALHAS" | grep "Failed password" | grep -oP 'from \K[0-9.]+' | sort | uniq -c | while read tentativas ip;
            do

              if [ $tentativas -gt $LIMITE_TENTATIVAS ]; 
                then 
                    # coleta IP e  User que fez as tentativas 
                    USUARIO_ALVO=$( echo $FALHAS | grep  "$ip" | grep -oP 'for \K[^ ]+' | sort | uniq -u | tr '\n' ', ' | sed 's/, $//');
                    
                    #ALERT=$(echo "\U0001F6A8")

                    #ALERT_MENSAGEM="[+] - \U0001F6A8 \u26A0 ALERTA DE BRUTE FORCE SSH \U0001F6A8 \u26A0\\n[+] - Dados de User: $USUARIO_ALVO\\n[+] - IP: $ip\\n[+] - TENTATIVAS: $tentativas falhas " 

                    ALERT_MENSAGEM=$(printf "[+] - ALERTA DE BRUTE FORCE SSH \U0001F6A8 \u26A0\n[+] - Dados de User: %s\n[+] - IP: %s\n[+] - TENTATIVAS: %s falhas\n==============================" "$USUARIO_ALVO" "$ip" "$tentativas")

                    log " - Enviando Msg de Alerta pra o bot "

                    # chamar funcao de enviar msg pra o bot do Discord
                    messager_bot "$ALERT_MENSAGEM"

                    log " - $ALERT_MENSAGEM"

              else
                  log " - foi identificado erros de senha porem erros Comuns !"
              fi

            done
    else

        log " - Nao foi encontrado Nenhum erro de Password durante o periodo de -  [ $FROM_TIMESTEMP ] - [ $TO_TIMESTEMP ]" 

    fi

fi

#================================================================
# ATUALIZAR TIMESTEMP
#================================================================
 
DATE_NEXT_EXECUTION=$(date -d "1 hour" "+%H:%M:%S")

log " - Iniciando atualização..."
echo "$TO_TIMESTEMP" > "$LAST_RUN_FILE"
log " - timestemp atualizado para [$TO_TIMESTEMP]"
log " - Proxima execusao as [$DATE_NEXT_EXECUTION]"
log "=============================================="
log "."






