CREATE TABLE analise_dados_diversidade_backup AS
SELECT * FROM analise_dados_diversidade;

update analise_dados_diversidade add
set "GENERO" = INITCAP(TRIM("GENERO"));

update analise_dados_diversidade add
set "COR/RACA/ETNIA" = INITCAP(TRIM("COR/RACA/ETNIA"));

update analise_dados_diversidade add
set "PCD" = 
	case
		when LOWER(TRIM("PCD")) = 'sim' then 'Sim'
		when LOWER(TRIM("PCD")) = 'não' then 'Não'
		else 'Prefiro não informar'
end;
	
update analise_dados_diversidade
set "NIVEL_Júnior" =
    case
        when LOWER(TRIM("NIVEL_Júnior")) = 'true' then 'True'
        else 'False'
    end,
    "NIVEL_Pleno" =
    case
        when LOWER(TRIM("NIVEL_Pleno")) = 'true' then 'True'
        else 'False'
    end,
    "NIVEL_Sênior" =
    case
        when LOWER(TRIM("NIVEL_Sênior")) = 'true' then 'True'
        else 'False'
 end;


create or replace view V_NIVEL_POR_GENERO_ETNIA_E_DEFICIENCIA as
select
	"GENERO",
	"COR/RACA/ETNIA",
	SUM(case when "NIVEL_Júnior" = 'True' then 1 else 0 end) as total_junior,
 	SUM(case when "NIVEL_Pleno" = 'True' then 1 else 0 end) as total_pleno,
  	SUM(case when "NIVEL_Sênior" = 'True' then 1 else 0 end) as total_senior,
  	SUM(case when "PCD" = 'Sim' then 1 else 0 end) as total_pessoas_pcd_sim,
  	SUM(case when "PCD" = 'Sim' then 1 else 0 end) as total_pessoas_pcd_nao,
  	SUM(case when "PCD" = 'Prefiro não informar' then 1 else 0 end) as total_pessoas_pcd_prefiro_nao_informar,
  	SUM(
  		case 
    		when "NIVEL_Júnior" = 'True' 
		      or "NIVEL_Pleno" = 'True' 
		      or "NIVEL_Sênior" = 'True'
	    then 1 
	    else 0 
  end
) as total_pessoas_no_grupo
  from analise_dados_diversidade
  group by 
  	"GENERO", "COR/RACA/ETNIA"
  order by 
	"GENERO" asc, 
	case "COR/RACA/ETNIA"
		when 'Outra' then 1
		when 'Prefiro Não Informar' then 2
		else 0
	end asc,
	"COR/RACA/ETNIA" asc;
	

select *
from V_NIVEL_POR_GENERO_ETNIA_E_DEFICIENCIA
where "GENERO" = 'Feminino';

create or replace view v_estatisticas_salariais_por_demografia as
select
	"GENERO",
    "COR/RACA/ETNIA",
    UPPER("UF ONDE MORA") AS uf_limpa,
    
	SUM(CASE WHEN "NIVEL_Júnior" = 'True' THEN 1 ELSE 0 END) AS total_junior,
    SUM(CASE WHEN "NIVEL_Pleno" = 'True' THEN 1 ELSE 0 END) AS total_pleno,
    SUM(CASE WHEN "NIVEL_Sênior" = 'True' THEN 1 ELSE 0 END) AS total_senior,
    
    SUM(CASE WHEN "PCD" = 'Sim' THEN 1 ELSE 0 END) AS total_pessoas_pcd_sim,
    SUM(CASE WHEN "PCD" = 'Não' THEN 1 ELSE 0 END) AS total_pessoas_pcd_nao,
    SUM(CASE WHEN "PCD" = 'Prefiro não informar' THEN 1 ELSE 0 END) AS total_pessoas_pcd_prefiro_nao_informar,
    COUNT(*) AS total_pessoas_no_grupo,
    
    round(AVG(CASE WHEN "SALARIO" ~ '^[0-9]+(\.[0-9]+)?$' THEN CAST("SALARIO" AS NUMERIC) END), 2) AS salario_medio
from 
	analise_dados_diversidade
where 
	"SALARIO" is not null
	AND UPPER("UF ONDE MORA") ~ '^[A-Z]{2}$'
group by 
	"GENERO",
    "COR/RACA/ETNIA",
    UPPER("UF ONDE MORA")
order by
    "GENERO",
    "COR/RACA/ETNIA",
    UPPER("UF ONDE MORA");

//view ordenada por genero, deficiencia e por media de salario em desc
create or replace view V_MEDIA_SALARIAL_POR_GENERO_E_PCD as
select
    "GENERO",
    "PCD",
    ROUND(AVG(CAST("SALARIO" as NUMERIC)), 2) as media_salarial,
    COUNT(*) as total_pessoas
from
    analise_dados_diversidade
where
    "SALARIO" ~ '^[0-9]+(\.[0-9]+)?$'
group by
    "GENERO",
    "PCD"
order by
    case "GENERO"
        when 'Feminino' then 1
        when 'Masculino' then 2
        else 3
    end,
    media_salarial desc;


    
    
//media de salario por genero, etnia, uf e nivel
select
    "GENERO",
    "COR/RACA/ETNIA",
    uf_limpa,
    total_junior,
    total_pleno,
    total_senior,
    salario_medio
from
    v_estatisticas_salariais_por_demografia
where
    "GENERO" in ('Feminino')
order by
	uf_limpa,
    "GENERO",
    "COR/RACA/ETNIA" asc;


// maior salario por uf
select 
    uf_limpa, 
    ROUND(AVG(salario_medio), 2) as media_salarial_uf
from 
    v_estatisticas_salariais_por_demografia
group by 
    uf_limpa
order by 
    media_salarial_uf desc
limit 1;

// media salarial entre feminino e masculino
select 
    "GENERO", 
    ROUND(AVG(CAST("SALARIO" AS NUMERIC)), 2) as media_salarial
from 
    analise_dados_diversidade
where 
    "SALARIO" ~ '^[0-9]+(\.[0-9]+)?$'
    and "GENERO" in ('Masculino', 'Feminino')
group by 
    "GENERO"
order by 
    media_salarial desc;


// media de quem ganha melhor etre mulheres
select 
    "COR/RACA/ETNIA", 
    ROUND(AVG(CAST("SALARIO" AS NUMERIC)), 2) as media_salarial
from 
    analise_dados_diversidade
where 
    "SALARIO" ~ '^[0-9]+(\.[0-9]+)?$'
    and "GENERO" = 'Feminino'
    and "COR/RACA/ETNIA" in ('Amarela', 'Branca', 'Parda', 'Preta')
group by 
    "COR/RACA/ETNIA"
order by 
    media_salarial desc;

//media de quem ganha mais baseado em cor, raça, genero e etnia
select 
    "GENERO",
    "COR/RACA/ETNIA",
    ROUND(AVG(CAST("SALARIO" AS NUMERIC)), 2) as media_salarial
from 
    analise_dados_diversidade
where 
    "SALARIO" ~ '^[0-9]+(\.[0-9]+)?$'
group by 
    "GENERO", 
    "COR/RACA/ETNIA"
order by 
	case "GENERO"
		when 'Feminino' then 1
		when 'Masculino' then 2
		else 3
	end,
	case "COR/RACA/ETNIA"
		when 'Prefiro Não Informar' then 2
        when 'Outra' then 3
        else 1
	end,
	"COR/RACA/ETNIA";

