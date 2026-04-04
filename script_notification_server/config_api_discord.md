
### Modo de USo do Script de Alerta Sobre ataques 

- Esse scritp e um script de automocao de alerta desevolvido por mim pra fins de Teste<br>
ele sera usado para alertar quando um usuario logar no seu servico de SSH ou FTP ou qualque outro tipo de  servico que voce queria configurar depois. <br>

<br>

- Nesse nosso scritp vamos usar a plataforma do discord para notificarnos quando algo desse tipo acontecer,<br>
usaremo a API do discord para gerar um token que ai vamos ter um channel_id que e onde poderemos usalos para ter acesso ao nossa DM onde a mensagem ira chegar . <br> 


 
 ### Passo a Passo para pegar o Token e o Channel_id

 - primeiro acessamos a URL **[https://docs.discord.com/developers/reference](https://docs.discord.com/developers/reference)** com isso estamos na api do Discord <br>
 logo depois temos que ir na opcao de **Developer-Portal** 
 seguindo em diante voce cria ou loga com sua conta do Discord , depois vai ate a opcao **Aplicacao/Aplication** <br> 
 e clique em **New-Aplication**  onde voce vai colocar o nome da sua aplicacao ou o nome do seu BOT que pode ser <br> 
 qualquer nome como ***bot-test-server*** por exemplo, em seguida clique sobre seu projeto onde voce vai ver varias opcoes <br> va ate a opcao de **BOT** pois e ai onde voce vai pegar seu token , com essa pagina aberta dentro dela va ate a opcao <br> **Refresh token** onde ele vai criar um novo token de autorizacao pra seu uso , pegue esse token e guarde ele pois iremos usar logo depois iremos na opcao 
 **OAuth2** onde vamos criar ou gerar um link de convite e permissao <br> para nosso aplicativo o **Discord** , vamos selecionar o escopo que esse nosso link vai ter , como se pode ver nessa etapa existe varias caixas com varias opcoes  e vamos nessa primeira caixa marcar a opcao **BOT** em seguida <br> 
 vai aparecer outro grupo de caixas que precisam serem marcadas e nessas vamos marcar a opcao **Administrator**  com isso vai ser gerado um link de convite abaixo com mais ou menos essa cara : **[https://discord.com/oauth2/authorize?client_id=11111111&permissions=8&integration_type=0&scope=bot]()**  voce vai pegar esse link e colar no seu Navegador <br>
 isso vai abrir o seu discord onde voce vai selecionar  o servidor que o bot ira mandar a msg com seu servidor aberto clique sobre seu perfil que estar provavelmente do lado esquerdo e copie seu **Id de Usuario** se voce nao ver esse ID de USuario e por que voce precisa ir em **configuracoes > avancado > ativar modo desenvolvedor**  com isso voce verar seu id de usuario no seu perfil . <br>
 seguindo agora voce ira mandar uma requisicao para a API do Discord onde ele vai nos dar o nosso ID do Nosso canal de mensagem , esse channel_Id usaremos para mandar mensagem pra nosso bot no Discord <br>
 pra fazer isso execute esse comando : 

    ```
    curl -X POST https://discord.com/api/v10/users/@me/channels \ 
    -H "Authorization: Bot <seu token aqui>" \ 
    -H "Content-Type: application/json" \
    -d '{"recipient_id": "id_do_seu_perfil_no_servidor"}'
    ```

    essa requisicao POST era nos retornar algo desse tipo :
    ```json
    "id": "1234567891011121",
    "type": 1,
    "last_message_id": "1111111111111111",
    "flags": 0,
    "recipients": [
      {
        "id": "222222222222222",
        "username": "seu.nome.nickname",
        "avatar": "seu-avatar",
        "global_name": "Nome-global"
      }
    ]
    ```

    vamos pegar esse primeiro ID pois e ele que usaremos como nosso **channel_id** , depois de obter o nosso id de canal vamos agora enviar uma requisicao POST onde enviaremos a mensagem pra nosso BOT <br> 
    com esse seguinte comando: 
    ```
    curl -X POST https://discord.com/api/v10/channels/{seu_id_chanell}/messages \
     -H "Authorization: Bot <seu Token aqui>" \
     -H "Content-Type: application/json" \
     -d '{"content": "Messager BOT !"}'
    ```
    como voce deve ter observado nos mudamos a url da api e passamos o nosso ID de canal diretamente na url ficando assim  ```  https://discord.com/api/v10/channels/1234567891011121/messages ``` esse POST enviado a esse endpoite na api vai disparar a mensagem no seu Discord e voce conseguirar ver a mensagem chegando na sua DM 