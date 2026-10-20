-- Execute no SQL Editor de um projeto Supabase novo.
begin;
create table if not exists public.site_members (
 site_key text not null check(site_key in ('portfolio','food','ti','city')),
 user_id uuid not null references auth.users(id) on delete cascade,
 primary key(site_key,user_id)
);
create or replace function public.is_editor(key text)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.site_members where site_key=key and user_id=auth.uid()) $$;
revoke all on function public.is_editor(text) from public;
grant execute on function public.is_editor(text) to anon,authenticated;
create table if not exists public.site_content (
 site_key text not null check(site_key in ('portfolio','food','ti','city')),
 content_key text not null,
 payload jsonb not null,
 primary key(site_key,content_key)
);
create table if not exists public.projects (
 id uuid primary key default gen_random_uuid(),
 site_key text not null default 'portfolio' check(site_key='portfolio'),
 title text not null check(length(title) between 1 and 200),
 description text not null check(length(description) between 1 and 5000),
 link text not null check(link ~ '^(https?://|/[^/])'),
 category text not null default 'Projeto',
 created_at timestamptz not null default now()
);
create table if not exists public.dishes (
 id uuid primary key default gen_random_uuid(),
 name text not null check(length(name) between 1 and 200),
 description text not null,
 price numeric(10,2) not null check(price>0 and price<=100000),
 active boolean not null default true
);
create table if not exists public.orders (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id),
 customer_name text not null check(length(customer_name) between 1 and 100),
 total numeric(12,2) not null default 0 check(total>=0),
 status text not null default 'received' check(status in ('received','preparing','done','cancelled')),
 created_at timestamptz not null default now()
);
create table if not exists public.order_items (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete cascade,
 dish_id uuid not null references public.dishes(id),
 dish_name text not null,
 quantity integer not null check(quantity between 1 and 20),
 unit_price numeric(10,2) not null check(unit_price>0)
);
alter table public.site_members enable row level security;
alter table public.site_content enable row level security;
alter table public.projects enable row level security;
alter table public.dishes enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
drop policy if exists members_self on public.site_members;
create policy members_self on public.site_members for select to authenticated using(user_id=auth.uid());
drop policy if exists content_read on public.site_content;
create policy content_read on public.site_content for select to anon,authenticated using(true);
drop policy if exists content_edit on public.site_content;
create policy content_edit on public.site_content for all to authenticated using(public.is_editor(site_key)) with check(public.is_editor(site_key));
drop policy if exists projects_read on public.projects;
create policy projects_read on public.projects for select to anon,authenticated using(true);
drop policy if exists projects_edit on public.projects;
create policy projects_edit on public.projects for all to authenticated using(public.is_editor(site_key)) with check(public.is_editor(site_key));
drop policy if exists dishes_read on public.dishes;
create policy dishes_read on public.dishes for select to anon,authenticated using(active or public.is_editor('food'));
drop policy if exists dishes_edit on public.dishes;
create policy dishes_edit on public.dishes for all to authenticated using(public.is_editor('food')) with check(public.is_editor('food'));
drop policy if exists orders_read on public.orders;
create policy orders_read on public.orders for select to authenticated using(user_id=auth.uid() or public.is_editor('food'));
drop policy if exists orders_status on public.orders;
create policy orders_status on public.orders for update to authenticated using(public.is_editor('food')) with check(public.is_editor('food'));
drop policy if exists items_read on public.order_items;
create policy items_read on public.order_items for select to authenticated using(exists(select 1 from public.orders o where o.id=order_id and (o.user_id=auth.uid() or public.is_editor('food'))));
-- Privilégios: clientes não criam permissões nem modificam preços dos pedidos.
revoke all on public.site_members,public.site_content,public.projects,public.dishes,public.orders,public.order_items from anon,authenticated;
grant select on public.site_members to authenticated;
grant select on public.site_content,public.projects,public.dishes to anon,authenticated;
grant insert,update,delete on public.site_content,public.projects,public.dishes to authenticated;
grant select on public.orders,public.order_items to authenticated;
grant update(status) on public.orders to authenticated;
create index if not exists orders_user_idx on public.orders(user_id);
create index if not exists items_order_idx on public.order_items(order_id);
-- Preços são obtidos no servidor. Pedido e itens são gravados na mesma transação.
create or replace function public.place_order(customer text,items jsonb)
returns uuid language plpgsql security definer set search_path=public
as $$
declare order_uuid uuid; entry jsonb; dish public.dishes%rowtype; qty int; total_value numeric:=0;
begin
 if auth.uid() is null then raise exception 'Entre na sua conta para pedir.'; end if;
 if customer is null or length(trim(customer)) not between 1 and 100 then raise exception 'Nome inválido.'; end if;
 if items is null or jsonb_typeof(items)<>'array' then raise exception 'Pedido inválido.'; end if;
 if jsonb_array_length(items) not between 1 and 30 then raise exception 'Escolha entre 1 e 30 itens.'; end if;
 insert into public.orders(user_id,customer_name) values(auth.uid(),trim(customer)) returning id into order_uuid;
 for entry in select * from jsonb_array_elements(items) loop
  if (entry->>'quantity') is null or (entry->>'quantity') !~ '^[0-9]+$' then raise exception 'Quantidade inválida.'; end if;
  qty:=(entry->>'quantity')::integer;
  if qty not between 1 and 20 then raise exception 'Quantidade inválida.'; end if;
  select * into dish from public.dishes where id=(entry->>'dish_id')::uuid and active for share;
  if not found then raise exception 'Prato indisponível.'; end if;
  insert into public.order_items(order_id,dish_id,dish_name,quantity,unit_price) values(order_uuid,dish.id,dish.name,qty,dish.price);
  total_value:=total_value+dish.price*qty;
 end loop;
 update public.orders set total=total_value where id=order_uuid;
 return order_uuid;
end $$;
revoke all on function public.place_order(text,jsonb) from public,anon;
grant execute on function public.place_order(text,jsonb) to authenticated;
insert into public.projects(id,title,description,link,category) values
 ('10000000-0000-4000-8000-000000000001','Mesa do Vale','Restaurante: cardápio, pedidos e dashboard com Supabase.','/restaurante/','Restaurante'),
 ('10000000-0000-4000-8000-000000000002','Nexo Tecnologia','Empresa fictícia de TI com serviços e apresentação editáveis. Nova versão para o portfólio.','/empresa-ti/','Tecnologia'),
 ('10000000-0000-4000-8000-000000000003','Carlos Chagas: raízes e futuro','História, economia, agropecuária e comércio de carne com a China.','https://capital-do-boi.vercel.app/','Projeto em grupo')
on conflict(id) do nothing;
-- Cardápio de exemplo do projeto Mesa do Vale.
insert into public.dishes(id,name,description,price,active) values
('20000000-0000-4000-8000-000000000001','Carne de sol do Vale','Carne de sol, arroz, feijão e mandioca dourada.',39.90,true),
('20000000-0000-4000-8000-000000000002','Prato da casa','Arroz, feijão, frango grelhado e salada fresca.',27.90,true),
('20000000-0000-4000-8000-000000000003','Vegetariano da horta','Legumes, arroz, feijão e salada fresca.',25.90,true),
('20000000-0000-4000-8000-000000000004','Feijão tropeiro','Feijão com farinha, ovos, couve e linguiça, acompanhado de arroz.',32.90,true),
('20000000-0000-4000-8000-000000000005','Frango com quiabo','Frango ao molho com quiabo, arroz e angu.',34.90,true),
('20000000-0000-4000-8000-000000000006','Escondidinho de carne','Carne desfiada sob purê de mandioca gratinado, com salada.',36.90,true)
on conflict(id) do nothing;

update public.projects set link='https://capital-do-boi.vercel.app/' where id='10000000-0000-4000-8000-000000000003';
-- Execute após criar as tabelas, para atualizar o perfil no banco.
insert into public.site_content(site_key,content_key,payload)
values ('portfolio','profile','{"name": "Lavínia Oliveira", "instagram": "https://www.instagram.com/laviniasoarews/", "schoolName": "Escola Estadual Dr. João Beraldo", "schoolUrl": "https://escolaestadualdrjoaoberaldo.com/", "biography": "Sou Lavínia Oliveira e estudo na Escola Estadual Dr. João Beraldo desde o 8º ano. Ao longo dessa trajetória, aprendi Excel, HTML e CSS e concluí cursos nessas áreas. Também desenvolvi vários projetos, como sites de restaurantes, uma lanchonete escolar e uma empresa de TI. Este portfólio reúne parte do que aprendi e construí na escola."}'::jsonb)
on conflict(site_key,content_key) do update set payload=excluded.payload;

commit;
-- DEPOIS DE CRIAR SUA CONTA, autorize seu UUID no SQL Editor:
-- insert into public.site_members(site_key,user_id)
-- select key,'COLE-SEU-UUID-AQUI'::uuid from unnest(array['portfolio','food','ti','city']) as key
-- on conflict do nothing;
-- Para colegas do grupo, autorize apenas 'city'. Não forneça chaves secretas.
