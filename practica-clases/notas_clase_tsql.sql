-- CLASE 6 - 06/05/2023

-- PL-SQL: Programing language SQL
-- En SQL Server se llama Transact SQL (TSQL)


BEGIN
	declare @prod		char(8)			-- declaro variables
	declare @detalle	char(100)

	set @prod = 'X'					-- asigno valor a una variable
	set @detalle = 'det X'

	print @prod
	print @detalle
END


BEGIN
	declare @prod2		char(8)			-- declaro variables
	declare @detalle2	char(100)
	declare @cant		integer

	set @prod2 = '00000030'					-- asigno valor a una variable
	set @detalle2 = ''

	select @prod2 = p.prod_detalle			-- utilizo las variables en un SELECT
	from Producto p
	where p.prod_codigo = @prod2
	--where p.prod_codigo != @prod2			-- esta condicion devolveria un array de valores, lo que se contrapone con el tipo de dato
											-- pero el motor solo almacena el ultimo valor

	print @prod2
	print @detalle2


	set @cant=2000
	while @cant <= (select count(*) from Cliente)
	BEGIN
		if @cant = 2000
		BEGIN
			print 'Dentro del IF'
		END

		set @cant = @cant + 1
		print @cant
	END
END


/* Transaction
Es un conjunto de instrucciones que cumple con las propiedades ACID:
	(A)TOMICIDAD: se ejecuta el bloque de codigo completo o nada
	(C)ONSISTENCIA: garantiza que los datos sean los mismos
	(I)SOLATION: se tiene capas de aislacion para manipular los datos
	(D)URABILIDAD: los datos se mantienen en el tiempo

BEGIN TRANSACTION

COMMIT

BEGIN TRANSACTION

ROLLBACK

*/


-- En una consola
begin transaction
	update Tipos set
		detalle = 'xxx'
	
-- commit
-- rollback

select @@TRANCOUNT


-- En otra pestaña
set transaction isolation level read committed -- el SELECT se bloquea hasta que la otra terminal termine el commit o rollback
set transaction isolation level read uncommitted -- el SELECT lee los cambios de la tabla original sin commitear, no se bloquea
set transaction isolation level snapshot -- el SELECT lee los valores 'viejos' de la copia (snapshot), no se bloquea


select * from Tipos


/* Lectura repetible: se da cuando en una transaccion se lee un valor y luego se lee el mismo
pero con otro valor.
Ocurre cuando se hacen UPDATEs o DELETEs en medio de una transaccion

Solucion: REPEATABLE READ, evita que una modificacion se haga mientras se esta consultando algo
*/
set transaction isolation level REPEATABLE READ


/* Dato fantasma: se da cuando se leen datos y luego se vuelve a leer pero aparecen otros.
Ocurre cuando se hacen INSERTs

Solucion: SERIALIZABLE, evita que una insercion se haga mientras se esta consultando algo
SERIALIZABLE genera una lectura compartida, por lo tanto todos pueden leer (acceder al dato) mientras no modiquen
*/
set transaction isolation level SERIALIZABLE


/* Deadlock: se da cuando dos transacciones se bloquean porque ambas quieren modificar algo pero el nivel de aislacion
no lo permite.

El motor resuelve el deadlock matando alguna transaccion (hace el rollback)

Otra solucion para evitar el deadlock es bloquear la tabla a nivel lectura tambien
*/



-- Ejercicio: descontar del stock en el deposito 00 del producto @codigo la cantidad @cant
-- siempre y cuando tenga stock suficiente

CREATE PROCEDURE SP_ACT_STOCK (@codigo char(8), @cant decimal(12,2))  AS
BEGIN

END



-- CLASE 7 05/13/2023
/*
VISTAS:
Una vista es una tabla virtual que tiene filas y columnas en la cual se le puede aplicar comandos como SELECT,
insert, update, delete.
Es virtual porque no tiene sus propios datos, sino que es de otras tablas
*/
use Productos

-- Vista DINAMICAS
create view V_DEPOSITO(COD, DETALLE, DOMI, TEL)
AS
	SELECT d.depo_codigo, d.depo_detalle, d.depo_domicilio, d.depo_telefono
	FROM DEPOSITO d

select * from V_DEPOSITO

/* Modificar vista:
Al modificar una vista se modifica tanto la vista como la tabla original. 
Los campos que no se usaron en la vista se llenan con null
*/
UPDATE V_DEPOSITO
SET DETALLE = 'X'
WHERE COD = '00'


/*
FUNCIONES:
- Escalares
- Tablas

Estas funciones se pueden usar tanto como las ya conocidas: sum, min, max, etc
La restriccion es que no pueden modificar datos en una tabla
*/
create function fun_ejemplo (@num integer) returns char(20)
as
begin
	declare @resultado char(20)
	if @num > 0
		set @resultado = 'Num Pos'
	else
		set @resultado = 'Num Neg'

	return @resultado
end

-- forma rapida de probar
select dbo.fun_ejemplo(-10)

create function fun_ejemplo02 (@num integer) returns table
as
	return select * from DEPOSITO d



/*
CURSOR:
Permite recorrer los registros de un query
*/
declare @cod char(6)
declare @rsocial char(100)

declare mi_cursor 
	CURSOR for
		select clie_codigo, clie_razon_social
		from Cliente
		order by clie_razon_social asc

	open mi_cursor
	fetch mi_cursor into @cod, @rsocial

	while @@FETCH_STATUS = 0
	begin
		print @rsocial
		fetch mi_cursor into @cod, @rsocial
	end
	close mi_cursor
	deallocate mi_cursor


-- INSENSITIVE: el cursor crear una copia cuando se tiene niveles de aislacion
DECLARE mi_cursor INSENSITIVE
CURSOR FOR ....




