-- SmartLar: execute uma vez no SQL Editor de um projeto Supabase novo.
begin;
create table public.clientes (
 id uuid primary key default gen_random_uuid(), nome text not null check(length(trim(nome))>0),
 telefone text not null check(length(regexp_replace(telefone,'\D','','g')) between 10 and 15),
 email text, endereco text not null check(length(trim(endereco))>0), created_at timestamptz not null default now()
);
create table public.tecnicos (id uuid primary key default gen_random_uuid(), nome text not null, telefone text not null, especialidade text not null);
create table public.produtos (id uuid primary key default gen_random_uuid(),nome text not null check(length(trim(nome))>0),categoria text not null,preco_unitario numeric(12,2) not null check(preco_unitario>=0),descricao text);
create table public.pedidos (
 id uuid primary key default gen_random_uuid(),numero bigint generated always as identity unique,
 cliente_id uuid not null references public.clientes(id),tecnico_id uuid references public.tecnicos(id),
 status text not null default 'orcamento' check(status in ('orcamento','aprovado','agendado','em_andamento','concluido','cancelado')),
 data_instalacao timestamptz,valor_total numeric(12,2) not null check(valor_total>=0),forma_pagamento text not null default 'A combinar',observacoes text,
 created_at timestamptz not null default now(),concluido_em timestamptz,
 check(status not in ('agendado','em_andamento','concluido') or (tecnico_id is not null and data_instalacao is not null))
);
create table public.itens_pedido (
 id uuid primary key default gen_random_uuid(),pedido_id uuid not null references public.pedidos(id),produto_id uuid not null references public.produtos(id),
 quantidade integer not null check(quantidade>0),preco_unitario numeric(12,2) not null check(preco_unitario>=0),
 subtotal numeric(12,2) generated always as (quantidade*preco_unitario) stored,unique(pedido_id,produto_id)
);
create table public.historico_status(id uuid primary key default gen_random_uuid(),pedido_id uuid not null references public.pedidos(id),status_anterior text,status_novo text not null,created_at timestamptz not null default now());
-- Outbox: evento inserido na mesma transação, após todos os itens.
create table public.eventos_automacao(id uuid primary key default gen_random_uuid(),pedido_id uuid not null references public.pedidos(id),tipo text not null,payload jsonb not null,created_at timestamptz not null default now());
create index on public.pedidos(cliente_id);
create index on public.pedidos(tecnico_id,data_instalacao);
create index on public.pedidos(status);
create index on public.itens_pedido(pedido_id);

create function public.validar_status() returns trigger language plpgsql set search_path='' as $$
begin
 if TG_OP='INSERT' then
  if new.status<>'orcamento' then raise exception 'Pedido deve começar como orçamento'; end if;
 elsif new.status<>old.status then
  if not ((old.status='orcamento' and new.status in ('aprovado','cancelado')) or (old.status='aprovado' and new.status in ('agendado','cancelado')) or (old.status='agendado' and new.status='em_andamento') or (old.status='em_andamento' and new.status='concluido')) then
   raise exception 'Transição de status não permitida';
  end if;
  if new.status='concluido' then new.concluido_em=now(); end if;
 end if;
 return new;
end $$;
create trigger validar_status before insert or update on public.pedidos for each row execute function public.validar_status();
create function public.registrar_status() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if TG_OP='INSERT' then insert into public.historico_status(pedido_id,status_novo) values(new.id,new.status);
 elsif new.status<>old.status then insert into public.historico_status(pedido_id,status_anterior,status_novo) values(new.id,old.status,new.status); end if;
 return new;
end $$;
create trigger registrar_status after insert or update on public.pedidos for each row execute function public.registrar_status();

create function public.criar_pedido(p_cliente uuid,p_itens jsonb,p_observacoes text default '',p_pagamento text default 'A combinar') returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_total numeric(12,2); v_count int; v_nome text;
begin
 if auth.uid() is null and coalesce(auth.role(),'')<>'service_role' then raise exception 'Autenticação necessária'; end if;
 if jsonb_typeof(p_itens)<>'array' or jsonb_array_length(p_itens)=0 then raise exception 'Adicione pelo menos um produto'; end if;
 if exists(select 1 from jsonb_array_elements(p_itens) x where (x->>'quantidade') is null or (x->>'quantidade')!~'^[1-9][0-9]*$' or (x->>'produto_id') is null) then raise exception 'Itens inválidos'; end if;
 if (select count(distinct x->>'produto_id') from jsonb_array_elements(p_itens) x)<>jsonb_array_length(p_itens) then raise exception 'Produto repetido'; end if;
 -- Bloqueia preços durante o cálculo e cópia para os itens.
 perform 1 from public.produtos where id in(select (x->>'produto_id')::uuid from jsonb_array_elements(p_itens) x) order by id for share;
 select sum(p.preco_unitario*(x->>'quantidade')::int),count(*) into v_total,v_count from jsonb_array_elements(p_itens) x join public.produtos p on p.id=(x->>'produto_id')::uuid;
 if v_count<>jsonb_array_length(p_itens) then raise exception 'Produto inexistente'; end if;
 select nome into strict v_nome from public.clientes where id=p_cliente;
 insert into public.pedidos(cliente_id,valor_total,observacoes,forma_pagamento) values(p_cliente,v_total,p_observacoes,p_pagamento) returning id into v_id;
 insert into public.itens_pedido(pedido_id,produto_id,quantidade,preco_unitario) select v_id,p.id,(x->>'quantidade')::int,p.preco_unitario from jsonb_array_elements(p_itens) x join public.produtos p on p.id=(x->>'produto_id')::uuid;
 insert into public.eventos_automacao(pedido_id,tipo,payload) values(v_id,'novo_orcamento',jsonb_build_object('pedido_id',v_id,'cliente',v_nome,'valor_total',v_total,'data',now()));
 return v_id;
end $$;
create function public.avancar_pedido(p_id uuid,p_status text,p_tecnico uuid default null,p_data timestamptz default null) returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null and coalesce(auth.role(),'')<>'service_role' then raise exception 'Autenticação necessária'; end if;
 if p_status='agendado' and (p_tecnico is null or p_data is null) then raise exception 'Informe técnico e data'; end if;
 update public.pedidos set status=p_status,tecnico_id=case when p_status='agendado' then p_tecnico else tecnico_id end,data_instalacao=case when p_status='agendado' then p_data else data_instalacao end where id=p_id;
 if not found then raise exception 'Pedido não encontrado'; end if;
end $$;
create function public.instalacoes_amanha() returns table(pedido_id uuid,cliente text,endereco text,tecnico text,horario text) language sql security invoker set search_path='' as $$
 select p.id,c.nome,c.endereco,t.nome,to_char(p.data_instalacao at time zone 'America/Sao_Paulo','DD/MM/YYYY HH24:MI')
 from public.pedidos p join public.clientes c on c.id=p.cliente_id join public.tecnicos t on t.id=p.tecnico_id
 where p.status='agendado' and p.data_instalacao >= (((now() at time zone 'America/Sao_Paulo')::date+1)::timestamp at time zone 'America/Sao_Paulo') and p.data_instalacao < (((now() at time zone 'America/Sao_Paulo')::date+2)::timestamp at time zone 'America/Sao_Paulo') order by p.data_instalacao;
$$;
-- Sem acesso anônimo. Usuários são criados pelo administrador, sem cadastro público.
do $$ declare t text; begin
 foreach t in array array['clientes','tecnicos','produtos','pedidos','itens_pedido','historico_status','eventos_automacao'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from anon, authenticated',t);
 if t<>'eventos_automacao' then
 execute format('grant select on public.%I to authenticated',t);
 execute format('create policy leitura_equipe on public.%I for select to authenticated using (true)',t);
 end if;
 end loop;
end $$;
grant insert on public.clientes,public.produtos to authenticated;
grant update(preco_unitario) on public.produtos to authenticated;
create policy inserir_cliente on public.clientes for insert to authenticated with check(true);
create policy inserir_produto on public.produtos for insert to authenticated with check(true);
create policy editar_preco on public.produtos for update to authenticated using(true) with check(true);
revoke all on function public.criar_pedido(uuid,jsonb,text,text),public.avancar_pedido(uuid,text,uuid,timestamptz),public.instalacoes_amanha(),public.validar_status(),public.registrar_status() from public,anon;
grant execute on function public.criar_pedido(uuid,jsonb,text,text),public.avancar_pedido(uuid,text,uuid,timestamptz) to authenticated,service_role;
grant execute on function public.instalacoes_amanha() to service_role;
commit;
