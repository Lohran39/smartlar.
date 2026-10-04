# SmartLar

Sistema de gestão de clientes, equipamentos, orçamentos e instalações residenciais. Projeto para o teste prático Dev No-Code Junior.

## Estado da entrega

As seis telas estão integradas ao Supabase real. Aplicação implantada: https://smartlar-gestao.lohranpaula.chatgpt.site (acesso externo do avaliador ainda pendente de validação).

As duas automações foram verificadas por evidências de execução em 04/10/2026, no horário de Brasília:
- Novo orçamento: execução #8 às 11:55:59, evento INSERT originado no Supabase, modo production, André Santos, R$ 160,00, envio concluído.
- Instalações de amanhã: execução programada #12 às 18:00:00, concluída em 3,203 s. Consulta e envio da instalação de André Santos com Lucas em 05/10/2026 às 10h.

Pendências de entrega: repositório GitHub público, acesso externo e usuário do avaliador, organização das evidências e substituição do segredo do primeiro webhook exposto durante a configuração. Os arquivos n8n são modelos sem credenciais; a configuração efetiva está na conta n8n.

## Começar pelo Supabase

1. Crie um projeto Supabase dedicado ao teste.
2. Execute `supabase/001_schema.sql` uma vez no SQL Editor.
3. Execute `supabase/002_seed.sql` uma vez. São 5 clientes fictícios, 2 técnicos, 6 produtos em 3 categorias e 8 pedidos em diferentes status.
4. Execute `supabase/003_checks.sql` e confira resultados.
5. Desabilite cadastro público em Authentication. Crie e confirme um usuário para a equipe. Toda conta autenticada nesse projeto representa um membro da equipe com o mesmo nível de acesso.
6. Configure `SUPABASE_URL` e `SUPABASE_ANON_KEY` no ambiente de execução (ou `.env` local conforme `.env.example`). Use a chave pública anon/publishable; nunca a service_role no frontend.
7. Entre pela aplicação e teste criação de cliente, produto, orçamento e evolução até conclusão.

## Fluxo e decisões

- Relações por UUID e foreign keys. `numeric(12,2)` para dinheiro; data de instalação e conclusão com fuso.
- `criar_pedido` é uma RPC transacional: bloqueia os produtos para leitura estável de preço, calcula o total, grava pedido, itens e evento. Falhas desfazem tudo.
- Quantidade precisa ser inteira positiva. Produtos duplicados são agregados pela interface e rejeitados na RPC se enviados repetidos.
- Itens guardam o preço do momento do orçamento. Alterar preço no catálogo não muda pedidos existentes.
- `avancar_pedido` é a única forma exposta de mudar pedidos. Trigger permite apenas orçamento → aprovado → agendado → em andamento → concluído; cancelamento só de orçamento ou aprovado.
- Agendamento exige técnico e data. A data/hora digitada na interface é interpretada como Brasília (UTC-3).
- RLS bloqueia acesso anônimo; pedidos e itens são somente leitura direta para usuários. RPCs autorizadas criam e mudam status. Clientes e produtos têm gravação controlada. Histórico registra cada mudança.
- Indicadores: pedidos criados no mês corrente de São Paulo; faturamento dos concluídos no mês por `concluido_em`; a receber = aprovados + agendados + em andamento em qualquer mês; pendentes de agendamento = aprovados.
- Próximas instalações: agendadas entre agora e 7 dias à frente. Agenda do técnico exibe agendadas e em andamento, inclusive atrasadas.
- Login por Supabase Auth. Token mantido apenas em memória; recarregar exige entrar novamente. Renovação de sessão é melhoria futura.
- Todos os membros autenticados veem a operação completa. Separação de permissões entre gestor e técnicos é melhoria futura.

## Frontend e execução

React + TypeScript, componentes acessíveis Shadcn e Vinext (API compatível com Next.js) para execução em Sites/Cloudflare. Comunicação com Supabase via REST e RPC. `app/api/config/route.ts` expõe apenas URL e chave pública.

Use a versão de Node e o gerenciador declarados em `package.json`. Instale as dependências pelo script `install:ci`, depois execute `dev` ou `build` com o gerenciador declarado. Fora do ambiente Sites, consulte os scripts de execução e configure o perfil portátil antes de hospedar em outro provedor.

Arquivos principais:
- `app/page.tsx`: as seis telas, formulários e ações.
- `app/globals.css`: tema e responsividade.
- `lib/smartlar.ts`: cliente HTTP e formatação.
- `supabase/`: schema, dados de exemplo e conferências.
- `n8n/`: dois fluxos importáveis e instruções.
- `ENTREGA.md`: roteiro de documentação e teste.

## GitHub

Crie um repositório público e envie o código com histórico de commits. Não envie `.env`, tokens, credenciais n8n, arquivos de execução ou dados reais de clientes. Mantenha `.env.example`. Faça commits por marco (banco, telas, automações, correções). O histórico gerado no início do projeto não é uma evidência de teste real do sistema.

## Automações

Leia `n8n/README.md`. Os workflows precisam de credenciais, URLs de destino e publicação/ativação. Não marque as automações como concluídas antes de obter execuções reais. O evento do orçamento usa uma tabela outbox para não notificar antes de salvar os itens.

## Verificações executadas

Compilação TypeScript aprovada. Schema e seed executados em PostgreSQL embarcado PGlite com simulação das funções de identidade do Supabase; passaram os testes de totais, consulta de amanhã, transições, campos de agendamento, preservação de preços, acesso autenticado e bloqueio anônimo. Isso não substitui validação em Supabase real ou execuções n8n.

## Uso de IA

ChatGPT/Codex auxiliou na interpretação do enunciado, geração de schema, telas, fluxos e documentação. O candidato deve revisar e conseguir explicar cada decisão, executar o sistema e registrar honestamente o que foi validado e o que ficou pendente.

## Referências

- https://supabase.com/docs/guides/database/functions
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/guides/database/webhooks
- https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.scheduletrigger/
