use Productos

-- 2C2017
-- Ej SQL

select p.prod_detalle,
	r.rubr_detalle,
	(select count(*) from Item_Factura i_f where i_f.item_producto = p.prod_codigo) cant_ventas
from Composicion c
join Producto p on (p.prod_codigo = c.comp_producto)
join Rubro r on (r.rubr_id = p.prod_rubro)
--where c.comp_cantidad >= 2
group by
	p.prod_codigo,
	p.prod_detalle,
	r.rubr_detalle
--	(select count(*) from Item_Factura i_f where i_f.item_producto = p.prod_codigo)
having
	count(c.comp_componente) >= 2
order by sum(c.comp_cantidad)



-- Parcial 01/07/2023

-- Ej 1 SQL
select c.clie_codigo, 
	c.clie_razon_social,
	(select count(distinct p.prod_rubro) from Item_Factura i
	join Producto p on (p.prod_codigo = i.item_producto)
	join Factura f2 on (i.item_tipo+i.item_sucursal+i.item_numero=f2.fact_tipo+f2.fact_sucursal+f2.fact_numero)
	where f2.fact_cliente = c.clie_codigo) cant_rubros,
	(select count(distinct co.comp_producto) from Composicion co
	join Item_Factura i on (i.item_producto = co.comp_producto)
	join Factura f2 on (i.item_tipo+i.item_sucursal+i.item_numero=f2.fact_tipo+f2.fact_sucursal+f2.fact_numero)
	where f2.fact_cliente = c.clie_codigo and YEAR(f2.fact_fecha) = 2012) cant_prod_con_composicion
from Cliente c
join Factura f on (f.fact_cliente = c.clie_codigo)
where exists (select f1.fact_cliente from Factura f1 where f1.fact_cliente = c.clie_codigo and YEAR(f1.fact_fecha) in (YEAR(f.fact_fecha)-1, YEAR(f.fact_fecha)+1))
group by c.clie_codigo, c.clie_razon_social
order by (select count(*) from Factura f3 where f3.fact_cliente = c.clie_codigo) ASC



select c.clie_codigo, 
	c.clie_razon_social,
	count(distinct p.prod_rubro) cant_rubros,
	(select count(distinct co.comp_producto) from Composicion co
	join Item_Factura i2 on (i2.item_producto = co.comp_producto)
	join Factura f2 on (i2.item_tipo+i2.item_sucursal+i2.item_numero=f2.fact_tipo+f2.fact_sucursal+f2.fact_numero)
	where f2.fact_cliente = c.clie_codigo and YEAR(f2.fact_fecha) = 2012) cant_prod_con_composicion
from Cliente c
join Factura f on (f.fact_cliente = c.clie_codigo)
join Item_Factura i on (i.item_tipo+i.item_sucursal+i.item_numero=f.fact_tipo+f.fact_sucursal+f.fact_numero)
join Producto p on (p.prod_codigo = i.item_producto)
where exists (select f1.fact_cliente from Factura f1 where f1.fact_cliente = c.clie_codigo and YEAR(f1.fact_fecha) in (YEAR(f.fact_fecha)-1, YEAR(f.fact_fecha)+1))
group by c.clie_codigo, c.clie_razon_social
order by (select count(*) from Factura f3 where f3.fact_cliente = c.clie_codigo) ASC
go

-- Ej 2 TSQL
create table prod_vendidos(
	periodo char(6),
	cod_prod char(8),
	precio_max decimal(12,2),
	unidades_vendidas decimal(12,2)
	)
go

create trigger tg_prod_vendidos -- copiar solucion
on Item_Factura after update, insert, delete
as
begin
/*	if exists(select * from inserted i 
		join prod_vendidos pv on pv.cod_prod = i.item_producto)
	begin
		
	end
	*/
	insert into prod_vendidos
	select FORMAT(f.fact_fecha, 'yyyyMM'),
		i.item_producto,
		MAX(i.item_precio),
		sum(i.item_cantidad)
	from Item_Factura i
	join Factura f on (f.fact_tipo = i.item_tipo and f.fact_sucursal = i.item_sucursal and f.fact_numero = i.item_numero)
	group by FORMAT(f.fact_fecha, 'yyyyMM'),
		i.item_producto
end


-- Parcial 27/06/2023

-- Ej 1 SQL
select top 10 c.clie_codigo, 
	c.clie_razon_social,
	count(distinct i.item_producto) cant_prod_distintos,
	(select isnull(sum(i1.item_cantidad), 0) from Item_Factura i1
	join Factura f1 on (i1.item_tipo = f1.fact_tipo and i1.item_sucursal = f1.fact_sucursal and i1.item_numero = f1.fact_numero)
	where f1.fact_cliente = c.clie_codigo and year(f1.fact_fecha) = 2012 and month(f1.fact_fecha) <= 6) comprado_primer_semestre
from Cliente c
join Factura f on (f.fact_cliente = c.clie_codigo)
join Item_Factura i on (i.item_tipo = f.fact_tipo and i.item_sucursal = f.fact_sucursal and i.item_numero = f.fact_numero)
where year(f.fact_fecha) = 2012
group by c.clie_codigo, c.clie_razon_social
having count(distinct f.fact_vendedor) > 0
order by sum(i.item_cantidad) desc, c.clie_codigo asc

-- idem anterior sin subselect
select top 10 c.clie_codigo, 
	c.clie_razon_social,
	count(distinct i.item_producto) cant_prod_distintos,
	sum(case when month(f.fact_fecha) <= 6 then i.item_cantidad else 0 end) comprado_primer_semestre
from Cliente c
join Factura f on (f.fact_cliente = c.clie_codigo)
join Item_Factura i on (i.item_tipo = f.fact_tipo and i.item_sucursal = f.fact_sucursal and i.item_numero = f.fact_numero)
where year(f.fact_fecha) = 2012
group by c.clie_codigo, c.clie_razon_social
having count(distinct f.fact_vendedor) > 0
order by sum(i.item_cantidad) desc, c.clie_codigo asc



-- Parcial 12/11/2022

-- Ej 1 SQL
select c.clie_codigo,
	c.clie_razon_social,
	(select top 1 i1.item_producto from Item_Factura i1
	join Factura f1 on (f1.fact_tipo+f1.fact_sucursal+f1.fact_numero = i1.item_tipo+i1.item_sucursal+i1.item_numero)
	where f1.fact_cliente = c.clie_codigo and year(f1.fact_fecha) = 2012
	group by i1.item_producto
	order by sum(i1.item_cantidad) DESC) cod_prod_mas_comprado,
	(select top 1 p1.prod_detalle from Item_Factura i1
	join Factura f1 on (f1.fact_tipo+f1.fact_sucursal+f1.fact_numero = i1.item_tipo+i1.item_sucursal+i1.item_numero)
	join Producto p1 on (p1.prod_codigo = i1.item_producto)
	where f1.fact_cliente = c.clie_codigo and year(f1.fact_fecha) = 2012
	group by i1.item_producto, p1.prod_detalle
	order by sum(i1.item_cantidad) DESC) prod_mas_comprado,
	count(distinct i.item_producto) cant_prod_distintos,
	(select count(*) from Item_Factura i1
	join Factura f1 on (f1.fact_tipo+f1.fact_sucursal+f1.fact_numero = i1.item_tipo+i1.item_sucursal+i1.item_numero)
	where f1.fact_cliente = c.clie_codigo and year(f1.fact_fecha) = 2012 
			and i1.item_producto in (select c.comp_producto from Composicion c)) cant_prod_composicion
from Cliente c
join Factura f on (f.fact_cliente = c.clie_codigo)
join Item_Factura i on (f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero)
where year(f.fact_fecha) = 2012
group by c.clie_codigo,
	c.clie_razon_social
having sum(f.fact_total) > (select avg(f1.fact_total) from Factura f1 where year(f1.fact_fecha) = 2012)
order by case when count(distinct i.item_producto) between 5 and 10 then 1 else 0 end desc


-- Parcial 15/11/2022

-- Ej 1 SQL
select f.fact_cliente,

	(select top 1 i2.item_producto from Item_Factura i2 
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	where f2.fact_cliente = f.fact_cliente and YEAR(f2.fact_fecha) = 2012
	group by i2.item_producto
	order by sum(i2.item_cantidad) desc) cod_prod_mas_comprado,

	(select top 1 p2.prod_detalle from Item_Factura i2 
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	join Producto p2 on (p2.prod_codigo = i2.item_producto)
	where f2.fact_cliente = f.fact_cliente and YEAR(f2.fact_fecha) = 2012
	group by i2.item_producto, p2.prod_detalle
	order by sum(i2.item_cantidad) desc) prod_mas_comprado,

	count(distinct i.item_producto) cant_prod_distintos,

	(select count(distinct co.comp_producto) from Composicion co
	join Item_Factura i2 on (i2.item_producto = co.comp_producto)
	join Factura f2 on (i2.item_tipo+i2.item_sucursal+i2.item_numero=f2.fact_tipo+f2.fact_sucursal+f2.fact_numero)
	where f2.fact_cliente = f.fact_cliente and YEAR(f2.fact_fecha) = 2012) cant_prod_con_composicion

from Factura f
join Item_Factura i on (i.item_tipo = f.fact_tipo and i.item_sucursal = f.fact_sucursal and i.item_numero = f.fact_numero)
join Producto p on (p.prod_codigo = i.item_producto)
join Cliente c on (c.clie_codigo = f.fact_cliente)
where year(f.fact_fecha) = 2012
group by f.fact_cliente, c.clie_razon_social
having count(distinct p.prod_rubro) = (select count(*) from Rubro) -- nadie compro todos los rubros
order by c.clie_razon_social asc,
	case when sum(f.fact_total) between (select sum(f2.fact_total) from Factura f2)*0.2
								and (select sum(f2.fact_total) from Factura f2)*0.3 then 1 else 0 end desc


-- Parcial 19/11/2022

-- Ej 1 SQL
select f.fact_cliente,

	(select top 1 i2.item_producto from Item_Factura i2 
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero) 
	where f2.fact_cliente = f.fact_cliente and year(f2.fact_fecha) = 2012
	group by i2.item_producto
	order by sum(i2.item_cantidad) desc) cod_prod_mas_comprado,

	ROW_NUMBER() OVER (order by c.clie_razon_social asc,
						case when sum(f.fact_total) between (select sum(fact_total) from Factura) * 0.2
									and (select sum(fact_total) from Factura) * 0.3
									then 1 else 0 end desc) ordinal,

	count(distinct i.item_producto) cant_prod_distintos,

	sum(f.fact_total) monto_total

from Factura f
join Item_Factura i on (i.item_tipo = f.fact_tipo and i.item_sucursal = f.fact_sucursal and i.item_numero = f.fact_numero)
join Cliente c on (c.clie_codigo = f.fact_cliente)
left join Composicion co on (co.comp_producto = i.item_producto)
where year(f.fact_fecha) = 2012
group by f.fact_cliente, c.clie_razon_social
having count(distinct co.comp_producto) = (select count(distinct comp_producto) from Composicion) -- nadie compro todos los productos de composicion
order by c.clie_razon_social asc,
		case when sum(f.fact_total) between (select sum(fact_total) from Factura) * 0.2
									and (select sum(fact_total) from Factura) * 0.3
									then 1 else 0 end desc


-- Parcial 22/11/2022

-- Ej 1 SQL
select p.prod_codigo,
	
	p.prod_detalle,

	(select isnull(sum(i2.item_cantidad), 0) from Item_Factura i2
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	join Composicion co2 on (co2.comp_producto = p.prod_codigo)
	where i2.item_producto = co2.comp_componente and year(f2.fact_fecha) = 2012
	) cant_veces_comp_vendido,

	(select isnull(sum(i2.item_cantidad * i2.item_precio), 0) from Item_Factura i2
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	where i2.item_producto = p.prod_codigo) monto_total

from Producto p
join Composicion c on (c.comp_producto = p.prod_codigo)
group by p.prod_codigo, p.prod_detalle
having count(distinct c.comp_componente) = 2 -- pongo 2 porque no hay productos con 3 componentes
		and
		(select count(distinct p2.prod_rubro)
		from Producto p2
		join Composicion c2 on (c2.comp_componente = p2.prod_codigo)
		where c2.comp_producto = p.prod_codigo) = 2
order by (select count(distinct f2.fact_tipo+f2.fact_sucursal+f2.fact_numero) from Item_Factura i2
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	join Composicion co2 on (co2.comp_producto = p.prod_codigo)
	where i2.item_producto = co2.comp_componente and year(f2.fact_fecha) = 2012) desc

select * from Composicion join Producto on prod_codigo = comp_componente


-- Parcial 27/06/2023

-- Ej 1 SQL
select top 10
	c.clie_razon_social,

	count(distinct i.item_producto) cant_prod_distintos,

	(select sum(i2.item_cantidad) from Item_Factura i2 
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	where f2.fact_cliente = c.clie_codigo 
		and year(f2.fact_fecha) = 2012 and month(f2.fact_fecha) <= 6) cant_unidades_compradas_primer_semestre

from Factura f
join Cliente c on (c.clie_codigo = f.fact_cliente)
join Item_Factura i on (i.item_tipo = f.fact_tipo and i.item_sucursal = f.fact_sucursal and i.item_numero = f.fact_numero)
where year(f.fact_fecha) = 2012
group by c.clie_codigo, c.clie_razon_social
having count(distinct f.fact_vendedor) >= 1 --3 -- no hay 3 vendedores distintos en 2012
order by sum(i.item_cantidad) desc, c.clie_codigo asc


-- Parcial 28/06/2023

-- Ej 1 SQL
select f.fact_cliente,
	
	(select sum(f2.fact_total) from Item_Factura i2
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	where f2.fact_cliente = f.fact_cliente and year(f2.fact_fecha) = 2012) monto_total_comprado_2012,

	(select sum(i2.item_cantidad) from Item_Factura i2
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	where f2.fact_cliente = f.fact_cliente and year(f2.fact_fecha) = 2012) cant_unidadades_comprado_2012

from Factura f
join Item_Factura i on (i.item_tipo = f.fact_tipo and i.item_sucursal = f.fact_sucursal and i.item_numero = f.fact_numero)
where (select count(distinct i2.item_producto) from Factura f2
		join Item_Factura i2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero) 
		where f2.fact_cliente = f.fact_cliente and year(f2.fact_fecha) = year(f.fact_fecha)) >= 5
		and
		(select count(distinct i2.item_producto) from Factura f2
				join Item_Factura i2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero) 
			where f2.fact_cliente = f.fact_cliente and year(f2.fact_fecha) = year(f.fact_fecha) + 1) >= 5
group by f.fact_cliente
order by case when f.fact_cliente in 
		(select distinct f2.fact_cliente from Item_Factura i2
		join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
		join Composicion co2 on (co2.comp_producto = i2.item_producto)) then 1 else 0 end


-- Parcial 01/07/2023

-- Ej 1 SQL
select c.clie_codigo,
	
	c.clie_razon_social,
	
	(select count(distinct p2.prod_rubro) from Item_Factura i2
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	join Producto p2 on (p2.prod_codigo = i2.item_producto)
	where f2.fact_cliente = c.clie_codigo) cant_rubros_distintos,

	(select count(distinct c2.comp_producto) from Item_Factura i2
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	join Composicion c2 on (c2.comp_producto = i2.item_producto)
	where f2.fact_cliente = c.clie_codigo and year(f2.fact_fecha) = 2012) cant_prod_compuestos

from Cliente c
join Factura f on (f.fact_cliente = c.clie_codigo)
where exists (select * from Factura f2 where f2.fact_cliente = c.clie_codigo and year(f2.fact_fecha) = year(f.fact_fecha))
		and
	exists (select * from Factura f2 where f2.fact_cliente = c.clie_codigo and year(f2.fact_fecha) = year(f.fact_fecha) + 1)
group by c.clie_codigo, c.clie_razon_social
order by (select count(distinct f2.fact_tipo+f2.fact_sucursal+f2.fact_numero) from Factura f2 where f2.fact_cliente = c.clie_codigo) asc


-- Parcial 08/07/2023

-- Ej 1 SQL
select 1, concat('Anio ', year(f.fact_fecha)) periodo,
	sum(f.fact_total) ventas_totales,
	count(distinct p.prod_rubro) cant_rubros_distintos,
	(select count(distinct c2.comp_producto) from Item_Factura i2
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	join Composicion c2 on (c2.comp_producto = i2.item_producto)
	where year(f2.fact_fecha) = year(f.fact_fecha)) cant_prod_composicion_distintos,
	count(distinct f.fact_cliente) cant_clientes_compraron
from Factura f
join Item_Factura i on (i.item_tipo = f.fact_tipo and i.item_sucursal = f.fact_sucursal and i.item_numero = f.fact_numero)
join Producto p on (p.prod_codigo = i.item_producto)
group by year(f.fact_fecha)

union

select 2, concat('Semestre ', (case when month(f.fact_fecha) <= 6 then 1 else 2 end)) periodo,
	sum(f.fact_total) ventas_totales,
	count(distinct p.prod_rubro) cant_rubros_distintos,
	(select count(distinct c2.comp_producto) from Item_Factura i2
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	join Composicion c2 on (c2.comp_producto = i2.item_producto)
	where year(f2.fact_fecha) = year(f.fact_fecha)) cant_prod_composicion_distintos,
	count(distinct f.fact_cliente) cant_clientes_compraron
from Factura f
join Item_Factura i on (i.item_tipo = f.fact_tipo and i.item_sucursal = f.fact_sucursal and i.item_numero = f.fact_numero)
join Producto p on (p.prod_codigo = i.item_producto)
group by year(f.fact_fecha), (case when month(f.fact_fecha) <= 6 then 1 else 2 end)

union

select 3, concat('Bimestre', (case when month(f.fact_fecha) between 1 and 2 then 1
							when month(f.fact_fecha) between 3 and 4 then 2
							when month(f.fact_fecha) between 5 and 6 then 3
							when month(f.fact_fecha) between 7 and 8 then 4
							when month(f.fact_fecha) between 9 and 10 then 5
							else 6 end)) periodo,
	sum(f.fact_total) ventas_totales,
	count(distinct p.prod_rubro) cant_rubros_distintos,
	(select count(distinct c2.comp_producto) from Item_Factura i2
	join Factura f2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	join Composicion c2 on (c2.comp_producto = i2.item_producto)
	where year(f2.fact_fecha) = year(f.fact_fecha)) cant_prod_composicion_distintos,
	count(distinct f.fact_cliente) cant_clientes_compraron
from Factura f
join Item_Factura i on (i.item_tipo = f.fact_tipo and i.item_sucursal = f.fact_sucursal and i.item_numero = f.fact_numero)
join Producto p on (p.prod_codigo = i.item_producto)
group by year(f.fact_fecha), (case when month(f.fact_fecha) between 1 and 2 then 1
							when month(f.fact_fecha) between 3 and 4 then 2
							when month(f.fact_fecha) between 5 and 6 then 3
							when month(f.fact_fecha) between 7 and 8 then 4
							when month(f.fact_fecha) between 9 and 10 then 5
							else 6 end)

order by 1, 2 -- orderna por anio, semestre y bimestre


-- Parcial 12/07/2023

-- Ej 1 SQL
select c.clie_codigo,
	c.clie_razon_social,
	
	(select sum(f2.fact_total) 
	from Factura f2 
	where f2.fact_cliente = c.clie_codigo) total_comprado,
	
	(select count(distinct p2.prod_rubro) from Factura f2
	join Item_Factura i2 on (i2.item_tipo = f2.fact_tipo and i2.item_sucursal = f2.fact_sucursal and i2.item_numero = f2.fact_numero)
	join Producto p2 on (p2.prod_codigo = i2.item_producto)
	where f2.fact_cliente = c.clie_codigo) cant_rubros_distintos

from Factura f
join Cliente c on (c.clie_codigo = f.fact_cliente)
where not exists (select * from Factura f2 where f2.fact_cliente = c.clie_codigo and year(f2.fact_fecha) = year(f.fact_fecha))
		and
	 not exists (select * from Factura f2 where f2.fact_cliente = c.clie_codigo and year(f2.fact_fecha) = year(f.fact_fecha) + 1)
group by c.clie_codigo,
	c.clie_razon_social
order by case when c.clie_codigo in (select f2.fact_cliente from Factura f2 where year(f2.fact_fecha) = 2012) then 1 else 0 end



