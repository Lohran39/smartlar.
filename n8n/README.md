# Configuração das automações

Os JSONs são modelos importáveis. As versões configuradas na conta n8n foram publicadas e testadas em 04/10/2026; estes arquivos permanecem modelos sem configuração privada. Não contêm credenciais. Use somente dados fictícios no webhook de teste.

## 1. Novo orçamento

1. Importe `01_novo_orcamento.json` no n8n.
2. No nó Webhook, crie uma credencial Header Auth: nome `x-smartlar-secret`, valor aleatório forte. Não coloque esse valor no GitHub.
3. No nó de envio, substitua a URL pelo destino escolhido (por exemplo, sua URL exclusiva do webhook.site). As mensagens incluem event_id, pedido_id, cliente, valor_total e data.
4. Salve e publique/ative o workflow. Copie a URL de PRODUÇÃO do Webhook.
5. No Supabase, crie Database Webhook para INSERT na tabela `eventos_automacao`. Método POST, URL de produção do n8n, header `x-smartlar-secret` com o mesmo valor configurado no n8n.
6. Crie um orçamento pela aplicação. Confira o histórico de execuções e a mensagem no destino. Capture os dois prints.

A RPC grava o evento somente após os itens, dentro da mesma transação. Assim, o evento leva o total definitivo. Não use webhook diretamente no INSERT de pedidos se mudar esse fluxo para criar itens separadamente.

O envio ao destino repete até 3 vezes em falhas. O ID do evento permite deduplicação no destino, mas o modelo NÃO implementa deduplicação. A recepção responde imediatamente; falhas posteriores devem ser reexecutadas pelo histórico do n8n. Se o próprio webhook falhar, o evento permanece no Supabase: consulte os registros e faça reenvio manual. Entrega garantida com fila e reprocessamento automático fica como melhoria documentada.

## 2. Instalações de amanhã

1. Importe `02_instalacoes_amanha.json`.
2. Substitua `SEU-PROJETO` na URL da consulta.
3. Crie uma credencial HTTP Custom Auth no n8n com:
   `{"headers":{"apikey":"SUA_CHAVE_SB_SECRET"}}`
   Use uma chave sb_secret_ do Supabase SOMENTE nessa credencial privada, nunca no frontend, no JSON exportado ou no repositório. Essa chave identifica o papel service_role, autorizado a consultar a RPC.
4. Selecione a credencial no nó de consulta e configure a URL de destino no último nó.
5. Salve e publique/ative. O workflow está configurado para 18h, America/Sao_Paulo.
6. Tenha um pedido agendado para amanhã. Para evidência automática antes de 18h, ajuste temporariamente o cron para alguns minutos à frente, publique, aguarde a execução real e depois restaure `0 18 * * *`.
7. Teste também sem agendamentos: não deve enviar resumo vazio. Confira o histórico e capture os prints.

A consulta usa intervalo [00:00 amanhã, 00:00 depois de amanhã) em São Paulo, calculado pelo banco. Não usa dados fixos nem o fuso do servidor n8n. A ausência de resultados encerra o fluxo sem erro. Falhas HTTP são repetidas 3 vezes e ficam no histórico; configure notificações de erro se desejar.

Referências oficiais:
- https://supabase.com/docs/guides/database/webhooks
- https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
- https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.scheduletrigger/
