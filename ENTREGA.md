# SmartLar — roteiro de entrega

Status atualizado em 04/10/2026 após a execução programada das 18h. Pendências continuam identificadas.

## Links
- Aplicação acessível à banca: PENDENTE
- Repositório público GitHub: https://github.com/Lohran39/smartlar.
- Supabase (link ou prints): PENDENTE
- Acesso de avaliação: criar usuário dedicado e compartilhar credencial por canal privado, nunca em repositório público.

## Evidências
- [ ] Diagrama com tabelas e foreign keys.
- [ ] Dados: 5 clientes, 2 técnicos, 6 produtos em 3 categorias, 8 pedidos.
- [ ] Cada uma das seis telas com dados do Supabase.
- [ ] Novo orçamento com vários itens e total correto.
- [x] Workflow 1: execução #8, 04/10/2026 às 11:55:59; origem Supabase, production, André Santos, R$ 160,00.
- [x] Workflow 2: execução automática #12, 04/10/2026 às 18:00:00; quatro etapas concluídas, 3,203 s; Lucas, André Santos, instalação em 05/10 às 10h.
- [ ] Destino externo mostrando os dados recebidos.

## Teste ponta a ponta
1. Entrar com conta de avaliação.
2. Cadastrar novo cliente e conferir persistência no Supabase.
3. Criar pedido com três produtos e conferir total.
4. Em outro pedido, verificar 2 × câmera (450) + 1 × sensor (180) = 1.080.
5. Editar preço do catálogo e confirmar que pedidos antigos mantêm o preço original.
6. Tentar pular de orçamento para concluído por RPC: deve falhar.
7. Aprovar e tentar agendar sem data/técnico: deve falhar.
8. Agendar para amanhã, abrir agenda, iniciar e concluir.
9. Conferir faturamento e a receber no dashboard.
10. Confirmar workflow 1 por criação real de orçamento.
11. Criar outro agendamento para amanhã e comprovar execução programada do workflow 2.
12. Testar dia sem instalações, erro HTTP e reexecução.
13. Sair e verificar que dados não podem ser acessados anonimamente.
14. Abrir link e repositório pela conta que a banca usará.

## Explicação técnica
Use o README como base, explicando com suas palavras: relacionamentos, preço histórico, transação de pedido, status, RLS, evento após itens e fuso de amanhã.

## Limitações a declarar
Sem renovação automática de sessão, sem papéis distintos por técnico, sem garantia automática de reentrega/deduplicação no destino. Sem edição de itens após criação, não exigida no teste. A chave sb_secret_ usada no n8n é privilegiada e deve permanecer em credencial privada.

## Melhorias com mais tempo
Renovação de sessão, controle de acesso por papel, idempotência na criação, deduplicação e reprocessamento de eventos, alerta de falhas, validação de conflitos de agenda e paginação de grandes listas.

## Onde houve apoio de IA
Estrutura inicial, SQL, componentes, automações e documentação gerados com apoio de ChatGPT/Codex. Complete com suas revisões, testes realizados e decisões próprias.

## Pendência de credencial
Substituir o segredo do primeiro webhook que foi exposto durante o suporte, em n8n e Supabase, e verificar novo evento. Não incluir headers de autenticação nas evidências públicas.
