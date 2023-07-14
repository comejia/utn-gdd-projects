use Productos

-- Alumno: Cesar Mejia

-- Ej 1: SQL
-- Asumo que cuento con la siguiente tabla de hechos de compras que ya tiene los datos cargados con las dimensiones correspondiente
create table hecho_compras (
	anio int, -- FK
	semestre int, -- FK
	bimestre int, -- FK
	producto char(8), -- FK
	rubro char(4), -- FK
	cliente char(6), -- FK
	ventas int,
)

select 
	sum(h.ventas) ventas_totales,
	count(distinct h.rubro) rubros_distintos,
	count(distinct h.producto) productos_con_composicion,
	count(distinct h.cliente) cant_clientes
from hecho_compras h
join Composicion c on c.comp_producto = h.producto
group by h.anio

union

select 
	sum(h.ventas) ventas_totales,
	count(distinct h.rubro) rubros_distintos,
	count(distinct h.producto) productos_con_composicion,
	count(distinct h.cliente) cant_clientes
from hecho_compras h
join Composicion c on c.comp_producto = h.producto
group by h.semestre

union

select 
	sum(h.ventas) ventas_totales,
	count(distinct h.rubro) rubros_distintos,
	count(distinct h.producto) productos_con_composicion,
	count(distinct h.cliente) cant_clientes
from hecho_compras h
join Composicion c on c.comp_producto = h.producto
group by h.bimestre

order by h.anio, h.semestre, h.bimestre

go

-- Ej 2: TSQL
create procedure st_corregir_tabla
as
begin
	declare @tipo char(1), @sucursal char(4), 
			@numero char(8), @producto char(8), @cantidad decimal(12,2), @precio decimal(12,2)

	declare micursor cursor for
	select i.item_tipo,
		i.item_sucursal,
		i.item_numero,
		i.item_producto,
		i.item_cantidad,
		i.item_precio
	from Item_Factura i
	group by i.item_tipo, i.item_sucursal, i.item_numero, i.item_producto, i.item_cantidad, i.item_precio
	having count(*) > 1

	open micursor
	fetch micursor into @tipo, @sucursal, @numero, @producto, @cantidad, @precio

	while @@FETCH_STATUS = 0
	begin
		delete from Item_Factura
		where item_tipo = @tipo and item_sucursal = @sucursal and item_numero = @numero and item_producto = @producto

		insert into Item_Factura values (@tipo, @sucursal, @numero, @producto, @cantidad, @precio)

		fetch micursor into @tipo, @sucursal, @numero, @producto, @cantidad, @precio
	end

	close micursor
	deallocate micursor


	alter table Item_Factura
	add constraint pk_item primary key(item_tipo, item_sucursal, item_numero, item_producto)

	alter table Item_Factura
	add constraint fk_fact foreign key(item_tipo, item_sucursal, item_numero)
	references Factura(fact_tipo, fact_sucursal, fact_numero)

	alter table Item_Factura
	add constraint fk_prod foreign key(item_producto)
	references Producto(prod_codigo)
end

go


