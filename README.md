# script notification server Verify 

## Pré-requisitos para execução do script
```
 # caminho do binario do programa 

 whereis crontab 

 # Instalar cronie pra usar crontab Arch Linux  

 sudo pacmna -S cronie 

 # Instalar cron pra usar crontab debian Linux
 
  sudo apt install cron 

# verificar versoes 

 cron --version 

 cronie --version

```
### Iniciar servico de crontab
```
 # iniciar servico de crontab no Arch Linux 

 sudo systemctl start cronie 

 # pra nao iniciar no boot 

 sudo systemctl enable cronie 

  # iniciar servico de crontab no Arch Linux  

 sudo systemctl start cron 

``` 

## Instalação ⚙️
```
    # clone repositorio 
    git clone "https://github.com/JaconiasDev/notification_activity_server.git"

    # acesse a estrutura do script 
    cd /script_alert_servidor  

    # Der permisao de execusao para o script 
    chmod +x script.sh  verify_so.sh

    # execute o escript 
    ./script_alert_servidor.sh 

    # adicionar ao binarios dos sistema 
    mv script_alert_servidor.sh  /usr/local/bin/script_alert_servidor 

    ativar_port_knocking

```

## Modo de Uso
```
    ./script_alert_servidor.sh  --arg1 --arg2 

    ./script_alert_servidor.sh --active-alert-so

    ./script_alert_servidor.sh --help
```

## Funcionalidades 
* verifica logs do sistema e avisar sobre possiveis tentativas de acesso  
* verifica logs do servidor e notifica possiveis ataques
* verifica servicos e avisar possiveis acesso a eles 


## aviso
> Esse script foi desevolvido por (***Jackal*** / Noob_x64)