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

banner_scritp() {
 source banner.sh 
}

# --------------------- Funcao que ativa o modo de monitoramento no SO ------------------------------

active_monitoring_sistem_operation (){
  sudo -v 
  echo -e "${RED}[-] - Aplicando Script auxiliar em /usr/bin/__script_analise_so.sh${NC}"

  #aplicando script  esse script deve aparecer la em /usr/bin/nome do nosso script e ao executalo ele deve aparecer a msg "test deu certo !"
  cat << EOF | sudo tee /usr/bin/__script_analise_so.sh > /dev/null

  #!/bin/bash

    echo -e "teste que deu certo!\n"

EOF

  sleep 1
  echo -e "${RED}[-] - Adicionando permissoes (write/read/execution) pra seu user apenas U+X${NC}"

  sudo chmod u+x /usr/bin/__script_analise_so.sh

  echo -e "${RED}[+] - Read  :${NC}${GREEN} \u2714 ${NC}"
  sleep 2
  echo -e "${RED}[+] - Write :${NC}${GREEN} \u2714 ${NC}"
  sleep 2
  echo -e "${RED}[+] - Exec  :${NC}${GREEN} \u2714 ${NC}\n"

  echo -e "${RED}[-] - ${NC}${GREEN}Configurando Agendamento com crontab...${NC}"

  # sudo /usr/bin/__script_analise_so.sh


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
    sudo -v
    banner_scritp
    verify_token_bot_id_Dm # verifica se passou token e Id_dm ! # ARRUMAR TA NA POSICAO ERRADA 
    clear
else 
    echo -e "${RED}\n[-] - By : Jackal (Noob_x64)${NC}"
    echo -e "${RED}[-] - github : https://github.com/JaconiasDev/notification_activity_server.git\n ${NC}"
    echo -e "${RED}[-] - Modo de Uso do Script : $0 --active-alert-so ${NC}"
    echo -e "${RED}[-] - Modo de Uso do Script : $0 --Arg1 --arg2 ${NC}"
    echo -e "${RED}[-] - Modo de Uso do Script : $0 --Arg1 --arg2 ${NC}\n"
    exit 1
fi

echo ""
echo -e "${RED}[+]============== INICIANDO TESTE DE COMUNICACAO COM O BOT ==============[+]${NC}"
echo -e "${RED}[+] - OBS :${NC} ${YELLOW} para essa etapa funcionar com sucesso voce deve ter feito o processo de OAuth2 que foi explicado no arquivo [config_api_Discord]${NC}\n"

echo -e "${RED}[+] - ${NC}${GREEN}Estabelecendo Comunicacao ... ${NC}"
sleep 2 
verify_communication_bot
validation_args_for_features "${args[@]}"


so=$(cat /etc/os-release  | grep -v ".*_ID=" | grep "ID=" | cut -d '=' -f 2) 

case $so in
    "arch")   echo "is_arch" ;; # chama funcao que executa pra arch 
    "debian") echo "is_debian" ;; # chama funcao que executa para debian 
esac

# funcao de verificacao de args