-- Verificações de leitura, após o seed. Esperado: 5, 2, 6, 8.
select (select count(*) from public.clientes) clientes,(select count(*) from public.tecnicos) tecnicos,(select count(*) from public.produtos) produtos,(select count(*) from public.pedidos) pedidos;
-- Esperado: zero linhas (nenhum total divergente).
select p.id,p.valor_total,sum(i.subtotal) soma from public.pedidos p join public.itens_pedido i on i.pedido_id=p.id group by p.id having p.valor_total<>sum(i.subtotal);
-- Um agendamento amanhã, se executado no mesmo dia do seed.
select * from public.instalacoes_amanha();
