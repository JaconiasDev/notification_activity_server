#! /bin/bash

# - ************************************************************
# - alert detection atacks 
# - Autor: NOOB_x64 - J4ck4l
# - Descrição: Script para automocao de alerta 
# - Licença: MIT License
# - Ano: 2026
# - ************************************************************

# - script de automocao
# - esse script tem como funcao avisar ou notificar voce sobre um possivel ataque ao seu Servidor 
# - tendo tambem funcao de notificar quando algum usuario Logar a servicos como SSH / SSHD ou FTP/SFTPD 
# - esse scrip usa de agendamento de verificacao (cronjob/crontab/cronie) para verificar partes do sistema ,  viu algo estrando notifica 

# funcoes 
# - verificar logs do sisteam e avisar sobre possiveis tentativas de acesso  (--active-alert-so)
# - verificar logs do servidor e verificar possiveis ataques (--active-alert-atack-server)
# - verificar servicos e avisar possiveis acesso a eles (--active-alert-acess-server)
# - etc ... 

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' 

args=("$@") 

token_discord_bot=''
recipient_id=''
communication_01_ID=''

banner_scritp() {
 source banner.sh 
}

#--------------------- funcao barra de Tarefas ----------------------------------

barra_tarefas(){
  local msg=$3 # mensagem personalizada
  local inicio=$1 # 10
  local final_l=$2 # 40 
  local total_barra=40 # total de barra [  ]

  local porcentagem=$(($inicio * 100 / $final_l))  # 10 * 100 = 1000 / 40 = 25

  preenchimento=$(($inicio * $total_barra / $final_l)) # 10 * 50 = 500 / 40 = 12 | 12 caracteres # 
  vazio=$(($total_barra - $preenchimento)) # 50 - 12 = 38  | 38 espacos vazios 

  barra=$(printf "%${preenchimento}s" | tr ' ' '#' ) # criamos 12 espacos e transformamos eles em # ou seja 12 #
  espacos=$(printf "%${vazio}s" | tr ' ' '-') # criamos 38 espacos vazios e depois substituimos por - ou seja 38 -

  echo -ne "$3  [${barra}${espacos}] ${porcentagem}%\r" # [############---------------------------------]
}


# --------------------- Funcao que ativa o modo de monitoramento no SO ------------------------------

active_monitoring_sistem_operation (){

  echo -e "${RED}[-] - Aplicando Script auxiliar em /usr/bin/__script_analise_so.sh${NC}"

  #aplicando script  esse script deve aparecer la em /usr/bin/nome do nosso script e ao executalo ele deve aparecer a msg "test deu certo !"
  
   cat << EOF > /usr/bin/__script_analise_so.sh
    #!/bin/bash
    TOKEN="$token_discord_bot"
    CHANNEL_ID="$communication_01_ID"
EOF
  
  
  cat << 'EOF' >> /usr/bin/__script_analise_so.sh

  #!/bin/bash

  #====================================================
  # ARQUIVOS DE CONTROLE
  #====================================================
  USER=$(whoami)    # usuario atual 

  if [ ! -d  "$HOME/logs_script_alert_server" ]; then mkdir $HOME/logs_script_alert_server ; fi

  LAST_RUN_FILE="$HOME/logs_script_alert_server/_ssh_monitor_last_run" # mude pra /tmp porem pode perder ref
  SCRIPT_LOG="$HOME/logs_script_alert_server/_ssh_monitor.log"
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

EOF


  sleep 1
  echo -e "${RED}[-] - Adicionando permissoes (write/read/execution) pra seu user apenas U+X${NC}"

  sudo chmod u+x /usr/bin/__script_analise_so.sh

  echo -e "${RED}[+] - Read  :${NC}${GREEN} \u2714 ${NC}"
  sleep 2
  echo -e "${RED}[+] - Write :${NC}${GREEN} \u2714 ${NC}"
  sleep 2
  echo -e "${RED}[+] - Exec  :${NC}${GREEN} \u2714 ${NC}\n"


  #=====================================================
  # DEFININDO ATIVIDADE DE CRONJOB
  #=====================================================
  # - VERIFICAR 
  # - SE NAO TIVER INSTAR
  # - DEFININIR O TEMPO PARA A EXECUSAO DO SCRIPT 
  # - PERSONALIZAR PRA DEFINIR O TEMPO EXATO PRA TEMPO QUE AS TAREFA SERA EXECUTADA!


  echo -e "${RED}[-]========== Configurando Agendamento com crontab ==========${NC}"

  # sudo /usr/bin/__script_analise_so.sh

  local total=20

  for i in $(seq 1 $total); do 
    barra_tarefas "$i" "$total" "${RED}[+]${NC} ${GREEN}verificando se voce possui o cronie... ${NC}"
    sleep 0.5
  done
  echo ""

  if pacman -Q cronie | grep -q cronie ; then 

    echo -e "${RED}[+]${NC}${GREEN} - cronie foi encontrado ✅ ${NC}"
    sleep 1

  else 

    echo -ne "${RED}[+]${NC}${GREEN} - cronie nao foi encontrado Deseja Instalar cronie ?(s/n) :   ${NC}"
    read resposta_cron 

    if [[ "$resposta_cron" =~ ^[sS] ]]; then
      
      sleep 1
      if sudo pacmna -S cronie --noconfirm > /dev/null 2>&1 ; then 

        for i in $(seq 1 $total); do 
          barra_tarefas $i $total "${GREEN}[+] - Instalando o cronie... ${NC}"
        done
        echo ""

        echo -e "${GREEN}[+] - Cronie instalado com sucesso ✅ !${NC}\n"

      else 
        echo -e "${RED}[+] - error ao instalar pacote , tente novamente${NC}"
        exit 0
      fi

    else 
        echo -e "${GREEN}[-] - Encerrando o Script ...${NC}"
        exit 0
    fi

  fi

  #==============================================
  # Adicionado config no crontab
  #==============================================


temp_cron=$(mktemp)

sudo crontab -l 2>/dev/null > "$temp_cron"


if ! grep -q "#adicionado script de automocao..." "$temp_cron" ; then 

    echo "#adicionado script de automocao..." >> "$temp_cron"
    echo "0 * * * *  /usr/bin/__script_analise_so.sh" >> "$temp_cron"

    sudo crontab "$temp_cron" 1>/dev/null 2>&1

else 
    echo -e "${YELLOW}[+] - Linhas ja adicionadas nada Mudado !${NC}\n"
fi 

rm $temp_cron

  echo -e "${GREEN}[+] - Script adicionado ao crontab com sucesso ✅  ${NC}"
  echo -e "${GREEN}[+] - scritp pronto pra uso ✅  ${NC}\n"



  if systemctl is-active --quiet cronie ; then 
    echo -e "${RED}[+] ${NC}${GREEN} - cronie em execusao✅  ${NC}\n"
  else
    echo -e "${RED}[+]${NC}${GREEN} - iniciando servico do Cronie ${NC}\n"

    systemctl start cronie 

  fi


}


# -------------------- VALIDACAO DE TOKEN E ID_DM ---------------------------------------------------

verify_token_bot_id_Dm() {


   echo -ne "${RED}[+] - PRECISAMOS DO TOKEN_BOT E DE SEU ID_DM PARA O BOM FUNCIONAMENTO DO SCRIPT\n${NC}\n" 
   sleep 2
   echo -ne "${RED}[+] - Token de Autenticacao do Seu Bot : ${NC}"
   
   read token_discord_bot

   if [[ -n "$token_discord_bot" && "${#token_discord_bot}" -gt 1  ]]; then
      echo -e "${RED}[+] - TOKEN Verificado  :${NC}${GREEN} $token_discord_bot ${NC}\n"
   else
      echo -ne "${RED}[+] - TOKEN Invalido Tente Novamente :${NC}${GREEN} $token_discord_bot ${NC}\n"
      exit 1
   fi

  echo -ne "${RED}[+] - seu Id_Dm/recipient_id : ${NC}"
  read recipient_id 
  
  if [[ -n "$recipient_id" && "${#recipient_id}" -gt 1 ]]; then
      echo -e "${RED}[+] - ID verificado :${NC}${GREEN} $recipient_id ${NC}\n"
  else 
      echo -ne "${RED}[+] - ID invalido :${NC}${GREEN} $recipient_id ${NC}\n"
      exit 1
  fi

}

# ------------------- ESTABELECIMENTO DE COMUNICACAO COM API E ENVIO DE MSG TEST --------------------

verify_communication_bot(){

  # - "message": "Invalid Recipient(s)", = codigo de dm invalido 
  # - "message": "401: Unauthorized" = token invalido 
  sleep 1
  echo -e "${RED}[+] - ${NC}${GREEN}Estabelecendo comunicacao com API do Discord${NC}\n"

  communication_01_ID=$(
     curl -X POST "https://discord.com/api/v10/users/@me/channels" \
       -H "Authorization: Bot ${token_discord_bot}" \
       -H "Content-Type: application/json" \
       -d "{\"recipient_id\": \"${recipient_id}\"}" 2>/dev/null | jq -r .id  
  )

  if [[ "$communication_01_ID" == null ]]; then 
      echo -e "${RED}[+]${NC} - ${GREEN}Error ao estabelecer conexao com API verifique Token e ID ${NC}\n"
      sleep 2
      clear
      banner_scritp
      verify_token_bot_id_Dm
      verify_communication_bot
  fi

  if [[ "$communication_01_ID" =~ ^[0-9]{17,}$  ]]; then 
    sleep 1
    echo -e "${RED}[+] - ${NC}${GREEN}Conexao com a API estabelecida com Sucesso \u2714 ${NC}"
  fi 

  sleep 1 
  echo -e "${RED}[+] - ${NC}${GREEN}Abrindo canal de comunicacao com DM...${NC}\n"
  sleep 2
  echo -ne "${RED}[+] - ${NC}${GREEN}Digite uma mensagem Teste pra Seu Bot :  ${NC}"
  read message_bot


  communication_send_message=$(
    if curl -X POST "https://discord.com/api/v10/channels/${communication_01_ID}/messages" \
      -H "Authorization: Bot ${token_discord_bot}" \
      -H "Content-Type: application/json" \
      -d "{\"content\": \"${message_bot} \"}" 2>/dev/null | jq . | grep -q "channel_id" ; then 
      echo 0 # true
    else
      echo 1 # false
    fi
  )

 
  if [ "$communication_send_message" -eq  0  ]; then 
      echo -e "${RED}[+] - ${NC}${GREEN}Messagem enviada com Sucesso  ✅ ${NC}\n"
      echo -e "${RED}[+] - ${NC}${GREEN}Seu aplicativo foi Notificado ✅ ${NC}\n"
      echo -e "${RED}[+] - ${NC}${GREEN} Bot Pronto pra Uso   ✅ ${NC}\n"
      sleep 3
      clear
  else 
      echo -e "${RED}[+] - ${NC}${GREEN}Erro ao enviar Menssagem ${NC}\n"
      exit 1
  fi

}


# ------------------- VERIFICAO DE ARGUMENTOS DE ATIVACAO DE FUNCIONALIDADES POR FUNCAO -------------

validation_args_for_features (){

  banner_scritp

  while [[ $# -gt 0 ]]; do # pra cada arg ($#) se for maior q 0 faz o case
    
    case "$1" in
      --active-alert-so|--Al)

         active_monitoring_sistem_operation # estamos chamando a funcao q  vai depositar o script da real operacoa no nosso /usr/bin

        ;;
      --active-alert-atack-server|--As)
        #echo -e "chmar funcao de ativar akert 2 -active-alert-atack-servee\n"
        ;;
      --active-alert-acess-server|--Ass)
        #echo -e "chmar funcao de ativar akert 3 --active-alert-acess-server\n"
        ;;
      *)
        echo "args invalidos "
        ;;
    esac

    shift # apaga o arg atual e deixa o proximo como primeiro

  done


}


# -------------------- VALIDACAO E MODO DE USO  ------------------------------------------------------

if [[ "${#args[@]}" -gt 0 && ! "${args[0]}" =~ ^[0-9]+$ && "${args[0]}" =~ ^-- ]];
  then 
    banner_scritp
    verify_token_bot_id_Dm # verifica se passou token e Id_dm ! # ARRUMAR TA NA POSICAO ERRADA 
    clear
else 
    echo -e "${RED}\n[-] - By : Jackal (Noob_x64)${NC}"
    echo -e "${RED}[-] - github : https://github.com/JaconiasDev/notification_activity_server.git\n ${NC}"
    echo -e "${RED}[-] - Modo de Uso do Script : $0 --active-alert-so ${NC}"
    echo -e "${RED}[-] - Modo de Uso do Script : $0 --Arg1 --arg2 ${NC}"
    echo -e "${RED}[-] - Modo de Uso do Script : $0 --Arg1 --arg2 ${NC}\n"
    echo -e "${RED}[-] - Execute o Script com Privilegios Root para evitar erros no Script !${NC}\n"
    exit 1
fi

echo ""
echo -e "${RED}[+]============== INICIANDO TESTE DE COMUNICACAO COM O BOT ==============[+]${NC}"
echo -e "${RED}[+] - OBS :${NC} ${YELLOW} para essa etapa funcionar com sucesso voce deve ter feito o processo de OAuth2 que foi explicado no arquivo [config_api_Discord]${NC}\n"

echo -e "${RED}[+] - ${NC}${GREEN}Estabelecendo Comunicacao ... ${NC}"
sleep 2 
verify_communication_bot
validation_args_for_features "${args[@]}"


#so=$(cat /etc/os-release  | grep -v ".*_ID=" | grep "ID=" | cut -d '=' -f 2) 

#case $so in
#   "arch")   echo "is_arch" ;; # chama funcao que executa pra arch 
#  "debian") echo "is_debian" ;; # chama funcao que executa para debian 
#esac
