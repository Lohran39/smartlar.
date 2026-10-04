-- Execute após 001_schema.sql. Dados fictícios. Tudo na mesma transação.
begin;
insert into public.tecnicos(id,nome,telefone,especialidade) values
 ('20000000-0000-0000-0000-000000000001','Lucas','11900000001','Câmeras e sensores'),
 ('20000000-0000-0000-0000-000000000002','Pedro','11900000002','Fechaduras e iluminação');
insert into public.clientes(id,nome,telefone,email,endereco) values
 ('10000000-0000-0000-0000-000000000001','Marina Costa','11900000011','marina@example.com','Rua das Acácias, 120, São Paulo - SP'),
 ('10000000-0000-0000-0000-000000000002','André Santos','11900000012','andre@example.com','Av. dos Ipês, 450, apto 32, São Paulo - SP'),
 ('10000000-0000-0000-0000-000000000003','Beatriz Lima','11900000013','beatriz@example.com','Rua das Palmeiras, 85, São Paulo - SP'),
 ('10000000-0000-0000-0000-000000000004','Carlos Almeida','11900000014','carlos@example.com','Rua dos Jardins, 210, São Paulo - SP'),
 ('10000000-0000-0000-0000-000000000005','Fernanda Rocha','11900000015','fernanda@example.com','Av. Central, 700, apto 81, São Paulo - SP');
insert into public.produtos(id,nome,categoria,preco_unitario,descricao) values
 ('30000000-0000-0000-0000-000000000001','Câmera IP','Segurança',450,'Câmera de monitoramento com acesso remoto'),
 ('30000000-0000-0000-0000-000000000002','Sensor de presença','Segurança',180,'Detecção de movimento para automações'),
 ('30000000-0000-0000-0000-000000000003','Fechadura digital','Segurança',890,'Controle de acesso por senha'),
 ('30000000-0000-0000-0000-000000000004','Lâmpada inteligente','Iluminação',95,'Ajuste de cor e intensidade pelo aplicativo'),
 ('30000000-0000-0000-0000-000000000005','Interruptor inteligente','Iluminação',160,'Controle de iluminação integrado'),
 ('30000000-0000-0000-0000-000000000006','Assistente de voz','Automação',350,'Controle de dispositivos por voz');
-- Autoriza as RPCs somente nesta transação administrativa.
select set_config('request.jwt.claims','{"role":"service_role"}',true);
do $$ declare v uuid; c uuid; i int; etapa text; when_at timestamptz; begin
 for i in 1..8 loop
 c=('10000000-0000-0000-0000-'||lpad((((i-1)%5)+1)::text,12,'0'))::uuid;
 v=public.criar_pedido(c,'[{"produto_id":"30000000-0000-0000-0000-000000000001","quantidade":2},{"produto_id":"30000000-0000-0000-0000-000000000002","quantidade":1}]'::jsonb,'Dados fictícios para avaliação','Pix');
 if i=8 then perform public.avancar_pedido(v,'cancelado');
 elsif i>=3 then
 perform public.avancar_pedido(v,'aprovado');
 if i>=4 then
 when_at=(((now() at time zone 'America/Sao_Paulo')::date+case when i=4 then 1 when i=5 then 3 else 0 end)::timestamp+interval '10 hours') at time zone 'America/Sao_Paulo';
 perform public.avancar_pedido(v,'agendado',case when i%2=0 then '20000000-0000-0000-0000-000000000001'::uuid else '20000000-0000-0000-0000-000000000002'::uuid end,when_at);
 if i>=6 then perform public.avancar_pedido(v,'em_andamento'); end if;
 if i=7 then perform public.avancar_pedido(v,'concluido'); end if;
 end if;
 end if;
 end loop;
end $$;
commit;
