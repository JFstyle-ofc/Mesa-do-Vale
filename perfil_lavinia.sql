-- Execute após criar as tabelas, para atualizar o perfil no banco.
insert into public.site_content(site_key,content_key,payload)
values ('portfolio','profile','{"name": "Lavínia Oliveira", "instagram": "https://www.instagram.com/laviniasoarews/", "schoolName": "Escola Estadual Dr. João Beraldo", "schoolUrl": "https://escolaestadualdrjoaoberaldo.com/", "biography": "Sou Lavínia Oliveira e estudo na Escola Estadual Dr. João Beraldo desde o 8º ano. Ao longo dessa trajetória, aprendi Excel, HTML e CSS e concluí cursos nessas áreas. Também desenvolvi vários projetos, como sites de restaurantes, uma lanchonete escolar e uma empresa de TI. Este portfólio reúne parte do que aprendi e construí na escola."}'::jsonb)
on conflict(site_key,content_key) do update set payload=excluded.payload;
