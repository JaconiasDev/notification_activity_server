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


sudo -v

# - CORES 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' #  sem cor

args=("$@") 

banner_scritp() {
    echo -e "${RED}"   
    cat << 'EOF'                            
                                 __       
                               .d$$b      
                             .' TO$;\     
                            /  : TP._;    
                           / _.;  :Tb|    
                          /   /   ;j$j  
                      _.-"       d$$$$   
                    .' ..       d$$$$;    
                   /  /P'      d$$$$P. |\ 
                  /   "      .d$$$P' |\^"l
                .'           `T$P^"""""  :
           ._.'      _.'                ;
         `-.-".-'-' ._.       _.-"    .-" 
       `.-" _____  ._              .-"    
      -(.g$$$$$$$b.              .'       
        ""^^T$$$P^)            .(:        
          _/  -"  /.'         /:/;        
       ._.'-'`-'  ")/         /;/;        
    `-.-"..--""   " /         /  ;        
   .-" ..--""        -'          :        
   ..--""--.-"         (\      .-(\       
     ..--""              `-\(\/;`         
       _.                      :          
                               ;`-        
                              :\          
                              ;  bug        
EOF
 echo -e "${NC}"

}


if [ "${#args[@]}" -lt  1 ];
  then 
    banner_scritp
    echo -e "${RED}[-] - By : Jackal (Noob_x64)${NC}"
    echo -e "${RED}[-] - github : https://github.com/JaconiasDev/notification_activity_server.git\n ${NC}"
    echo -e "${RED}[-] - Modo de Uso do Script : $1 --active-alert-so ${NC}"
    echo -e "${RED}[-] - Modo de Uso do Script : $1 --Arg1 --arg2 ${NC}"
    echo -e "${RED}[-] - Modo de Uso do Script : $1 --Arg1 --arg2 ${NC}\n"

else 

    banner_scritp

    for n in "${args[@]}"; do 
        echo $n 
    done

fi

