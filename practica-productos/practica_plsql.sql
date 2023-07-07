use Productos

/*
1) Hacer una funci�n que dado un art�culo y un deposito devuelva un string que
indique el estado del dep�sito seg�n el art�culo. Si la cantidad almacenada es 
menor al l�mite retornar �OCUPACION DEL DEPOSITO XX %� siendo XX el 
% de ocupaci�n. Si la cantidad almacenada es mayor o igual al l�mite retornar
�DEPOSITO COMPLETO�.
*/

create function FNC_estado_articulo (@articulo char(8), @deposito char(2)) returns char(100)
as
begin
	
	declare @estado char(100)
	declare @cantidad decimal(12,2)
	declare @maximo decimal(12,2)
	declare @porcentaje decimal(12,2)

	select @cantidad = s.stoc_cantidad, @maximo = s.stoc_stock_maximo from STOCK s
	where s.stoc_producto = @articulo and s.stoc_deposito = @deposito


	if @cantidad < @maximo
	begin
		set @porcentaje = (@cantidad*100)/@maximo
		set @estado = 'Ocupacion del deposito ' + @deposito + ' ' + cast(@porcentaje as varchar) + '%'
	end
	else
		set @estado = 'Deposito completo'

	return @estado
end

select dbo.FNC_estado_articulo('00000030', '00')


/*
3) Cree el/los objetos de base de datos necesarios para corregir la tabla empleado 
en caso que sea necesario. Se sabe que deber�a existir un �nico gerente general 
(deber�a ser el �nico empleado sin jefe). Si detecta que hay m�s de un empleado 
sin jefe deber� elegir entre ellos el gerente general, el cual ser� seleccionado por 
mayor salario. Si hay m�s de uno se seleccionara el de mayor antig�edad en la 
empresa. Al finalizar la ejecuci�n del objeto la tabla deber� cumplir con la regla 
de un �nico empleado sin jefe (el gerente general) y deber� retornar la cantidad 
de empleados que hab�a sin jefe antes de la ejecuci�n.
*/



/*
5) Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definici�n:
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
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)
*/

create table Fact_table
( anio char(4) not null,
mes char(2) not null,
familia char(3) not null,
rubro char(4) not null,
zona char(3) not null,
cliente char(6) not null,
producto char(8) not null,
cantidad decimal(12,2) not null,
monto decimal(12,2) not null
)

Alter table Fact_table
Add constraint pk_primary primary key (anio,mes,familia,rubro,zona,cliente,producto)

create procedure st_completar_fact_table
as
begin
	

	declare @cod char(6)
declare @rsocial char(100)

declare mi_cursor 
	CURSOR for
		select year(f.fact_fecha) anio, MONTH(f.fact_fecha) mes, p.prod_familia, p.prod_rubro,
				
		from Factura f
		join Item_Factura i on (f.fact_tipo = i .item_tipo and f.fact_sucursal = i.item_sucursal and f.fact_numero = i.item_numero)
		join Producto p on (p.prod_codigo = i.item_producto)
		join Empleado e on (e.empl_codigo = f.fact_vendedor)
		join Departamento d on (d.depa_codigo = e.empl_departamento)

		-- COMPLETARRRR
	open mi_cursor
	fetch mi_cursor into @cod, @rsocial

	while @@FETCH_STATUS = 0
	begin
		print @rsocial
		fetch mi_cursor into @cod, @rsocial
	end
	close mi_cursor
	deallocate mi_cursor
end






