use Productos
go

/* 1) Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es 
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el 
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”. */

create function fn_estado_deposito (@articulo char(8), @deposito char(2)) 
returns char(255)
as
begin
	declare @estado char(255)
	declare @cant_almacenada decimal(12,2)
	declare @stock_maximo decimal(12,2)
	declare @porcentaje decimal(12,2)

	select @cant_almacenada=s.stoc_cantidad, @stock_maximo=s.stoc_stock_maximo 
	from STOCK s 
	where s.stoc_producto = @articulo and s.stoc_deposito = @deposito

	if (@cant_almacenada < @stock_maximo)
	begin
		set @porcentaje = (@cant_almacenada * 100) / @stock_maximo
		set @estado = 'Ocupacion del deposito ' + @deposito + ': ' + cast(@porcentaje as varchar) + '%'
	end
	else
		set @estado='Deposito completo'

	return @estado
end
go

select dbo.fn_estado_deposito('00000102', '00')
go

DROP FUNCTION fn_estado_deposito
GO


/* 2) Realizar una función que dado un artículo y una fecha, retorne el stock que 
existía a esa fecha */
create function fn_stock_disponible (@articulo char(8), @fecha smalldatetime) 
returns decimal(12,2)
as
begin
	declare @stock decimal(12,2)

	set @stock = (select sum(s.stoc_cantidad) from STOCK s where s.stoc_producto = @articulo) 
				+
				(select isnull(sum(i.item_cantidad), 0)
				from Factura f
				join Item_Factura i ON (i.item_tipo+i.item_sucursal+i.item_numero = f.fact_tipo+f.fact_sucursal+f.fact_numero)
				where f.fact_fecha < @fecha and i.item_producto = @articulo)

	return @stock
end
go

select dbo.fn_stock_disponible('00000102', '2011-12-19 00:00:00')
go

DROP FUNCTION fn_stock_disponible
GO

/* Ejemplo
select sum(s.stoc_cantidad) from STOCK s where s.stoc_producto = '00000102' 
-- +
select f.fact_fecha, sum(i.item_cantidad)
				from Factura f
				join Item_Factura i ON (i.item_tipo+i.item_sucursal+i.item_numero = f.fact_tipo+f.fact_sucursal+f.fact_numero)
				where i.item_producto = '00000102'
group by f.fact_fecha
order by 1*/


/* 3) Cree el/los objetos de base de datos necesarios para corregir la tabla empleado 
en caso que sea necesario. Se sabe que debería existir un único gerente general 
(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado 
sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por 
mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la 
empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla 
de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad 
de empleados que había sin jefe antes de la ejecución. */
create procedure st_gerente_general (@cant_sin_jefe integer output)
as
begin
	set @cant_sin_jefe = (select count(*) from Empleado e where e.empl_jefe is null)

	if @cant_sin_jefe > 1
	begin
		declare @gerente numeric(6)
		set @gerente = (select top 1 e.empl_codigo
						from Empleado e
						where e.empl_jefe is null
						order by e.empl_salario desc, e.empl_ingreso asc)	

		update Empleado set empl_jefe = @gerente
		where empl_jefe is null and empl_codigo != @gerente
	end
end
go

declare @sin_jefes integer
exec dbo.st_gerente_general @cant_sin_jefe=@sin_jefes output
print(@sin_jefes)
go

drop procedure st_gerente_general
go


/* 4) Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor 
que más vendió (en monto) a lo largo del último año. */

alter table Empleado add new_comision decimal(12,2)
go

create procedure st_actulizar_comision (@mejor_vendedor numeric(6) output)
as
begin
	declare @ultimo_anio int
	
	set @ultimo_anio = (select MAX(YEAR(f.fact_fecha)) from Factura f)

	update Empleado set new_comision = 
									(select isnull(sum(f.fact_total), 0)
									from Factura f
									where year(f.fact_fecha) = @ultimo_anio and f.fact_vendedor = empl_codigo)

	set @mejor_vendedor = (select top 1 f.fact_vendedor from Factura f
							where year(f.fact_fecha) = @ultimo_anio
							group by f.fact_vendedor
							order by sum(f.fact_total) DESC)
end
go

declare @el_mejor numeric(6)
exec dbo.st_actulizar_comision @el_mejor output
print(@el_mejor)
go

drop procedure st_actulizar_comision
go


/* 5) Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
Create table Fact_table
( anio char(4),
mes char(2),
familia char(3),
rubro char(4),
zona char(3),
cliente char(6),
producto char(8),
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto) */
drop table Fact_table

create table Fact_table( 
	anio char(4) not null,
	mes char(2) not null,
	familia char(3) not null,
	rubro char(4) not null,
	zona char(3) not null,
	cliente char(6) not null,
	producto char(8) not null,
	cantidad decimal(12,2),
	monto decimal(12,2)
)
Alter table Fact_table
Add constraint pk_primary primary key(anio,mes,familia,rubro,zona,cliente,producto)
go

create procedure st_completar_fact_table as
begin
	delete Fact_table

	insert into Fact_table
	select year(f.fact_fecha),
		month(f.fact_fecha),
		p.prod_familia,
		p.prod_rubro,
		d.depa_zona,
		f.fact_cliente,
		p.prod_codigo,
		sum(i.item_cantidad),
		sum(i.item_cantidad * i.item_precio)
	from Factura f
	join Item_Factura i on (i.item_tipo+i.item_sucursal+i.item_numero = f.fact_tipo+f.fact_sucursal+f.fact_numero)
	join Producto p on (p.prod_codigo = i.item_producto)
	join Empleado e on (e.empl_codigo = f.fact_vendedor)
	join Departamento d on (d.depa_codigo = e.empl_departamento)
	group by year(f.fact_fecha),
		month(f.fact_fecha),
		p.prod_familia,
		p.prod_rubro,
		d.depa_zona,
		f.fact_cliente,
		p.prod_codigo
end
go

exec dbo.st_completar_fact_table
select * from Fact_table

drop procedure st_completar_fact_table

/* 6) Realizar un procedimiento que si en alguna factura se facturaron componentes 
que conforman un combo determinado (o sea que juntos componen otro 
producto de mayor nivel), en cuyo caso deberá reemplazar las filas 
correspondientes a dichos productos por una sola fila con el producto que 
componen con la cantidad de dicho producto que corresponda. */


/* 7) Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por 
las ventas entre esas fechas. La tabla se encuentra creada y vacía. */
create table ventas (
	codigo char(8),
	detalle char(50),
	cant_movimientos int,
	precio_venta decimal(12,2),
	renglon int identity(1,1) not null,
	ganancia decimal(12,2)
	)
go

alter table ventas
add constraint pk_ventas primary key(renglon)
go
-- drop table ventas

create procedure st_ventas (@fecha_inicio smalldatetime, @fecha_fin smalldatetime) as
begin
	insert into ventas
	select p.prod_codigo,
		p.prod_detalle,
		sum(i.item_cantidad),
		avg(i.item_precio),
		sum(i.item_cantidad * i.item_precio)
	from Producto p
	join Item_Factura i on (i.item_producto = p.prod_codigo)
	join Factura f on (i.item_tipo+i.item_sucursal+i.item_numero = f.fact_tipo+f.fact_sucursal+f.fact_numero)
	where f.fact_fecha between @fecha_inicio and @fecha_fin
	group by p.prod_codigo,
		p.prod_detalle
end

exec dbo.st_ventas '2011-11-25 00:00:00', '2011-11-28 00:00:00'
--select * from ventas

/* 8) Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por 
cantidad de sus componentes, se aclara que un producto que compone a otro, 
también puede estar compuesto por otros y así sucesivamente, la tabla se debe 
crear y está formada por las siguientes columnas: */
create table diferencias (
	codigo char(8),
	detalle char(50),
	cantidad int,
	precio_generado decimal(12,2),
	precio_facturado decimal(12,2)
	)
go


/* 9) Crear el/los objetos de base de datos que ante alguna modificación de un ítem de 
factura de un artículo con composición realice el movimiento de sus 
correspondientes componentes */
create trigger tg_item 
on Item_factura for update 
as
begin
	if (select count(*) from inserted i
		where i.item_producto in (select c.comp_producto from Composicion c)) > 0
	begin
		update STOCK set stoc_cantidad = stoc_cantidad -
									((select i.item_cantidad
									from inserted i
									where stoc_producto = i.item_producto) - 
									(select d.item_cantidad
									from deleted d
									where stoc_producto = d.item_producto))
		where stoc_deposito = (select top 1 s.stoc_deposito from STOCK s
								join inserted i on (i.item_producto = s.stoc_producto)
								order by s.stoc_cantidad DESC)
	end
end
go

drop trigger tg_item

/*select * from Item_Factura where item_producto = '00001707'
order by item_numero desc
-- tipo A, sucursal 0003, numero 00100053

select * from Item_Factura join Composicion on comp_producto = item_producto
-- 00001707
-- cant 50

select * from STOCK where stoc_producto = '00001707'
-- depo 3, cant 7

update Item_Factura set item_cantidad = item_cantidad + 1
where item_tipo = 'A' and item_sucursal = '0003' and item_numero = '00100053'

select * from STOCK*/
go

/* 10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo 
verifique que no exista stock y si es así lo borre en caso contrario que emita un 
mensaje de error. */
create trigger tg_borrar_articulo 
on Producto instead of delete
as
begin
	if exists (select * from deleted d
				join STOCK s on (s.stoc_producto = d.prod_codigo)
				where s.stoc_cantidad > 0)
	begin
		rollback transaction
		print('El articulo posee stock, no se puede eliminar')
		return
	end

	delete from STOCK where stoc_producto in (select prod_codigo from deleted)
	delete from Composicion where comp_producto in (select prod_codigo from deleted)
	delete from Producto where prod_codigo in (select prod_codigo from deleted)
end
go

drop trigger tg_borrar_articulo

delete from Producto
where prod_codigo = '00002508'

/*
-- determino que producto no tiene stock en ningun deposito donde se encuentre
SELECT s.stoc_producto, count(*) from STOCK s
WHERE s.stoc_cantidad <= 0
	--and s.stoc_producto not in (select distinct i.item_producto from Item_factura i) -- busco un producto que no se vendio (evito la FK)
GROUP BY s.stoc_producto
HAVING COUNT(*) = (SELECT COUNT(*) FROM STOCK s1 where s1.stoc_producto = s.stoc_producto group by s1.stoc_producto)

select * from Item_Factura i where i.item_producto = '00002508'
*/
go

/* 11. Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que 
tengan un código mayor que su jefe directo. */
create function fn_cant_empleados (@cod_empleado numeric(6))
returns int
as
begin
	declare @cant int = 0

	if not exists (select * from Empleado where empl_jefe = @cod_empleado)
		return @cant
	
	select @cant = @cant + count(dbo.fn_cant_empleados(e.empl_codigo))
	from Empleado e
	where e.empl_jefe = @cod_empleado and e.empl_codigo > @cod_empleado

	return @cant
end
go

select dbo.fn_cant_empleados(1) -- no funciona, probar con cursores

drop function fn_cant_empleados
go