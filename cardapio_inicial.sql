-- Cardápio de exemplo do projeto Mesa do Vale.
insert into public.dishes(id,name,description,price,active) values
('20000000-0000-4000-8000-000000000001','Carne de sol do Vale','Carne de sol, arroz, feijão e mandioca dourada.',39.90,true),
('20000000-0000-4000-8000-000000000002','Prato da casa','Arroz, feijão, frango grelhado e salada fresca.',27.90,true),
('20000000-0000-4000-8000-000000000003','Vegetariano da horta','Legumes, arroz, feijão e salada fresca.',25.90,true),
('20000000-0000-4000-8000-000000000004','Feijão tropeiro','Feijão com farinha, ovos, couve e linguiça, acompanhado de arroz.',32.90,true),
('20000000-0000-4000-8000-000000000005','Frango com quiabo','Frango ao molho com quiabo, arroz e angu.',34.90,true),
('20000000-0000-4000-8000-000000000006','Escondidinho de carne','Carne desfiada sob purê de mandioca gratinado, com salada.',36.90,true)
on conflict(id) do nothing;
