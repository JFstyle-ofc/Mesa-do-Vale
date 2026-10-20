# Mesa do Vale

Site independente do restaurante escolar de Lavínia Oliveira. Inclui cardápio, carrinho, login por e-mail, pedidos e dashboard.

## Conectar

1. Se você já executou o SQL do portfólio no mesmo Supabase, use o mesmo banco; não precisa executá-lo novamente. Caso contrário, execute supabase.sql no SQL Editor de um projeto novo.
2. Preencha assets/config.js com supabaseUrl e a chave pública supabaseKey (publishable ou anon). Nunca use sb_secret ou service_role.
3. Crie sua conta em Entrar → Criar conta e confirme o e-mail.
4. Em Authentication → Users, copie o UUID do usuário. No SQL Editor execute:

```sql
insert into public.site_members(site_key,user_id)
values ('food','COLE-SEU-UUID-AQUI'::uuid)
on conflict do nothing;
```

Clientes podem fazer pedidos e ver os próprios. Só quem foi autorizado em food pode alterar cardápio e gerenciar pedidos. O cálculo do valor ocorre na função place_order no banco.

## Publicar na Vercel

Publique esta pasta com index.html e assets na raiz. Use Framework Preset Other, sem build, e saída na raiz (.). Pelo terminal, dentro desta pasta: npx vercel --prod.

Após publicar, configure Authentication → URL Configuration no Supabase com o endereço publicado. Se usar o banco do portfólio, o Site URL pode continuar sendo o portfólio: a confirmação retorna a esse endereço e depois o cliente pode entrar no restaurante.

Envie o endereço publicado para atualizar o link Mesa do Vale no portfólio. O link atual do portfólio continua /restaurante/.

## Verificar

Teste login, cadastro de um prato, criação de pedido, visualização no dashboard e alteração de situação. Teste também com cliente sem permissão administrativa. Sem configuração, o cardápio mostra três exemplos e o carrinho funciona, mas o site não confirma pedidos fictícios. Preços e pratos são exemplos; o restaurante é fictício.

A imagem de apresentação é ilustrativa. Os testes locais de interface usam um servidor simulado; a integração real exige configurar seu Supabase.

## Páginas e carrinho

index.html é o início; cardapio.html, pedido.html, sobre.html e gestao.html são páginas separadas. O carrinho é mantido neste navegador ao trocar de página. Publique a pasta inteira com assets; não envie apenas index.html. Se o JavaScript estiver desativado, o cardápio inicial continua visível, mas o carrinho exige JavaScript.

## Dados personalizados

Instagram, escola e trajetória de Lavínia foram preenchidos. A chave pública também foi configurada. Falta preencher supabaseUrl em assets/config.js com a URL do projeto. Execute perfil_lavinia.sql se já instalou o banco e quer atualizar o perfil salvo anteriormente. A chave secreta enviada não foi incluída.

## Carlos Chagas, MG

Site adaptado para Carlos Chagas com seis pratos de exemplo. A fotografia é ilustrativa. Nenhum telefone, endereço ou horário foi inventado. O início, cardápio, pedido, sobre e gestão são páginas independentes.

Se já instalou as tabelas, execute apenas cardapio_inicial.sql para adicionar os exemplos que ainda não existirem. Não há conexão real verificada: ainda falta a URL do projeto Supabase em assets/config.js. A chave pública é a anteriormente fornecida; confirme se continua válida.
