use Pruebas

-- Final 05/12/2023
-- 3)
create table juego(
	jugador int,
	jugada int,
	carta int,
	constraint pk_juego primary key (jugador, jugada)
)
insert into juego values
	(1, 1, 3), (2, 1, 5),
	(1, 2, 1), (2, 2, 6),
	(1, 3, 7), (2, 3, 7),
	(1, 4, 3), (2, 4, 1),
	(1, 5, 10), (2, 5, 4),
	(1, 6, 11), (2, 6, 9),
	(1, 7, 5), (2, 7, 8),
	(1, 8, 2), (2, 8, 5),
	(1, 9, 8), (2, 9, 7)
	truncate table juego
-- 3a)
select j1.jugada, j1.jugador, j1.carta
from juego j1
order by j1.jugada,
	(case when j1.jugador = (select top 1 j2.jugador from juego j2 where j2.jugada = j1.jugada - 1
							order by j2.carta desc)
	then 1 else 0 end) desc,
	j1.jugador asc

-- 3b)
select jugador, max(carta) mayor_carta
from juego
group by jugador
order by max(carta) desc, jugador asc


-- Final 27/09/2023
-- 3)
create table parametros(
	clave int primary key,
	valor varchar(100) null
)
-- 3a)
insert into parametros values 
	(1, '1'), (2, '2'), (3, '3'), (4, '4'), (5, '5'), (6, '6'), (7, '7'), (8, '8')

go
create procedure sp_increment_parametro(@id int)
as
begin transaction
	declare @valor varchar(100)
	select @valor = valor from parametros where clave = @id
	update parametros set valor = @valor + 1
	where clave = @id
commit

-- Test: hay problema de ejecucion si valor no tiene un numero como tal, osea tiene un char cualquiera
exec sp_increment_parametro 5
select * from parametros

-- 3b)
select min(f1.clave), max(f2.clave) from parametros f1, parametros f2
where f1.clave > f2.clave

-- Final 01/08/2023
-- 3)
create table Producto(
	id int primary key identity,
	descripcion varchar(100) not null
)

create table Deposito(
	id int primary key identity,
	descripcion varchar(100) not null
)

insert into Producto (descripcion) values
	('arroz'),
	('salchicha'),
	('papas')

insert into Deposito (descripcion) values
	('barracas'),
	('once'),
	('pompeya')

create table Stock(
	id int primary key identity,
	cantidad int not null,
	id_deposito int,
	id_producto int,
	constraint fk_depo foreign key (id_deposito) references Deposito(id),
	constraint fk_prod foreign key (id_producto) references Producto(id)
)

insert into Stock (cantidad, id_deposito, id_producto) values
	(10, 1, 1),
	(20, 1, 2),
	(50, 3, 3)

insert into Stock (cantidad, id_deposito, id_producto) values
	(10, 1, 1),
	(20, 1, 2)
go

-- 3b)
-- Eliminar duplicados
create procedure sp_limpiar_duplicados
as
begin
	declare @cantidad int, @id_depo int, @id_prod int

	declare mi_cursor cursor for
	select sum(cantidad) cantidad, id_deposito, id_producto from Stock
	group by id_deposito, id_producto
	having count(*) > 1

	open mi_cursor
	fetch mi_cursor into @cantidad, @id_depo, @id_prod

	while @@FETCH_STATUS = 0
	begin
		delete from Stock
		where id_deposito = @id_depo and id_producto = @id_prod

		insert into Stock values(@cantidad, @id_depo, @id_prod)
		fetch mi_cursor into @cantidad, @id_depo, @id_prod
	end

	close mi_cursor
	deallocate mi_cursor
end

go
-- Test
select * from Stock
exec sp_limpiar_duplicados
select * from Stock

-- Evitar que se agreguen duplicados
-- Solucion 1: Con unique no se pueden realizar inserts para un mismo id_deposito y id_producto pero si update 
alter table Stock
add constraint uq_depo_prod unique (id_deposito, id_producto)
-- Tests
insert into Stock (cantidad, id_deposito, id_producto) values -- error al ejecutar por la constraint
	(10, 1, 1),
	(20, 1, 2)

update Stock set cantidad = cantidad + 10 -- valido
where id_deposito = 1 and id_producto = 1

-- alter table Stock drop constraint uq_depo_prod
go

-- Solucion 2: Con trigger
create trigger tg_evitar_duplicados on Stock
instead of insert
as
	--select * from inserted
	print 'trigger disparado'

	declare @cantidad int, @id_depo int, @id_prod int

	declare tg_mi_cursor cursor for
	select cantidad, id_deposito, id_producto from inserted

	open tg_mi_cursor
	fetch tg_mi_cursor into @cantidad, @id_depo, @id_prod

	while @@FETCH_STATUS = 0
	begin
		if (select count(*) from Stock 
			where @id_depo = Stock.id_deposito and  @id_prod = Stock.id_producto) > 0
			begin
				print 'Ya existe una fila para el deposito y producto en Stock. Se suma la cantidad'
				update Stock set cantidad = cantidad + @cantidad
				where id_deposito = @id_depo and id_producto = @id_prod
			end
		else
			begin
				insert into Stock (cantidad, id_deposito, id_producto) 
				values (@cantidad, @id_depo, @id_prod)
			end

		fetch tg_mi_cursor into @cantidad, @id_depo, @id_prod
	end

	close tg_mi_cursor
	deallocate tg_mi_cursor

-- Solucion 3: Con trigger (mas simple), si se inserta un duplicado directamente se hace un rollback
go
alter trigger tg_evitar_duplicados_v2 on Stock
after insert
as
	-- select * from inserted
	if exists(select 1 from Stock i 
			group by i.id_deposito, i.id_producto
			having count(*) > 1)
	begin
		raiserror('Ya existe una fila para el deposito y producto insertado. Se debe actualizar', 1, 1)
		rollback transaction
		return
	end


-- Final 25/07/2023
-- 3)
create table numeros (
	clave int primary key,
	valor int
)

insert into numeros(clave, valor) values
	(1, 100),
	(3, 300),
	(4, 400),
	(6, 600),
	(10, 1000)

-- 3a) Al utilizar left si no se cumple el on, entonces n2.clave va a ser null lo que indica
-- que no hay una clave siguiente (hay un hueco)
select top 1 (n1.clave + 1) clave from numeros n1
left join numeros n2 on (n2.clave = n1.clave + 1)
where n2.clave is null

-- 3b)
insert into numeros(clave)
select top 1 (n1.clave + 1) clave from numeros n1
left join numeros n2 on (n2.clave = n1.clave + 1)
where n2.clave is null

select * from numeros


-- Final 23/05/2023
-- 3)
create table T1(
	id int primary key,
	valor int
)

create table T3(
	id int primary key,
	valor int
)

create table T2(
	t1_id int,
	t3_id int,

	constraint pk_t2 primary key (t1_id, t3_id),
	constraint fk_t1 foreign key (t1_id) references T1(id),
	constraint fk_t3 foreign key (t3_id) references T3(id)
)

insert into T1 (id, valor) values
	(1, 10),
	(2, 10),
	(3, 10),
	(4, 10),
	(5, 10)

insert into T3 (id, valor) values
	(21, 10),
	(22, 10),
	(23, 10),
	(24, 10)

insert into T2 (t1_id, t3_id) values
	(1, 21),
	(1, 22),
	(1, 23),
	(1, 24)
insert into T2 (t1_id, t3_id) values
	(2, 21),
	(3, 22),
	(4, 23),
	(4, 24)

-- 3a) Devuelve las ocurrencias de T1.id en T2
select T1.id, (select count(distinct T2.t3_id) from T2 where T2.t1_id = T1.id)
from T1

-- 3b) Solucion con join
select T1.id, isnull(count(distinct T2.t3_id), 0) from T1 
left join T2 on T2.t1_id = T1.id
group by T1.id

-- 3c) No cambia en nada porque T2.t3_id es PK, no hay repeticion para un mismo T2.t1_id
select T1.id, (select count(T2.t3_id) from T2 where T2.t1_id = T1.id)
from T1


-- Final 07/03/2023
create table Secuencias (
	clave int not null
)

insert into Secuencias (clave) values
	(5), (2), (3), (4), (5), (6), (7), (8), (9), (10),
	(11), (12), (13), (14), (15), (16), (17), (18), (19), (20)

-- 3a)
select clave from Secuencias
where clave in (select top 5 clave from Secuencias order by clave) or
	clave in (select top 5 clave from Secuencias order by clave desc)
order by 1

-- Como minimo devuelve 10 registros y como maximo 11 (4 match + 2 por duplicado). 
-- Los casos bordes estan en si se duplica el 5 o el 15

-- 3b)
delete from Secuencias
where clave in (select clave from Secuencias group by clave having count(*) > 1)


-- Final 28/02/2023
-- 1a) Hay interbloqueo si ambas transacciones intentan actualizar
set transaction isolation level repeatable read

begin transaction
	select * from tabla
	update tabla set valor=20
	-- insert into tabla values (16)
commit

begin transaction
	select * from tabla
	update tabla set valor=30
	-- insert into tabla values (15)
commit

-- 3b) Idem Final 01/08/2023


-- Final 22/02/2023
-- 1b)
create table tabla_final(
	campo varchar(5)
)
insert into tabla_final values
	('hola'),
	(null),
	('chau'),
	('hello')

select count(campo) from tabla_final -- count no considera null si se especifica un atributo
select count(*) from tabla_final -- cuenta las filas, no importa si es null

-- 3)
create table final(
	numero int unique
)

-- 3a)
insert into final values (1)
insert into fiNAl (NumEro) values (3)
insert into final values (null)
update final set numero = isnull(numero, 5) + 1 where 1 = 1 or numero is not null and numero > 0
insert into final values (null)

commit

select * from final -- al tener unique, los valores de la tabla se ordenan: null, 2, 4, 6


-- Final 22/12/2022
-- 1b)
create table borrar(
	numero int
)
go

create trigger tg_1 on borrar
after insert
as
	print 'Trigger 1'

go
create trigger tg_2 on borrar
after insert
as
	print 'Trigger 2'

-- Test: se ejecuta ambos triggers. Puede haber mas de una trigger after para la misma tabla y evento
insert into borrar values (10), (11)

-- 3)
create table mundial_futbol(
	id int primary key,
	anio int not null,
	pais_campeon varchar(50) not null,
	pais_subcampeon varchar(50) not null
)
insert into mundial_futbol (id, anio, pais_campeon, pais_subcampeon) values
	(1, 1930, 'uruguay', 'argentina'),
	(2, 1934, 'italia', 'checoslovaquia'),
	(3, 1938, 'italia', 'hungria'),--
	(4, 1950, 'brasil', 'uruguay'),
	(5, 1954, 'alemania', 'hungria'),
	(6, 1958, 'brasil', 'suecia'),--
	(7, 1962, 'brasil', 'checoslovaquia'),--
	--(8, 1966, 'inglaterra', 'alemania'),
	--(9, 1970, 'brasil', 'italia'),
	(10, 1974, 'alemania', 'holanda'),--
	(22, 2022, 'argentina', 'francia')

-- 3a) Interprete mal, pero lo dejo para tenerlo en cuenta. La solucion es para algo como:
-- "Mostrar el ultimo que gano un mundial que solo tienen UNA conquista"
--select pais_campeon from mundial_futbol
--group by pais_campeon
--having count(*) = 1
--order by anio desc -- error porque anio no esta en el group by. Se esta usando funciona agregada: count
					-- Si pongo anio en el group by, el conjunto se vuelve a abrir por lo que el resultado es incorrecto
					-- Una solucion es haciendo una subconsulta
select top 1 pais_campeon, anio from mundial_futbol
where pais_campeon in 
	(select m.pais_campeon from mundial_futbol m
	group by m.pais_campeon
	having count(*) = 1)
order by anio desc

-- Solucion que cumple con el enunciado
select top 1 pais_campeon, anio from mundial_futbol m
where not exists 
	(select m1.pais_campeon from mundial_futbol m1
	where m.anio > m1.anio and m.pais_campeon = m1.pais_campeon)
order by anio desc
go

-- 3b)
alter trigger tg_futbol on mundial_futbol
after insert
as
	if (select count(*) from inserted where pais_campeon = pais_subcampeon) > 0
		begin
			raiserror('El pais campeon y el sub campeon no pueden ser el mismo.', 1, 1)
			rollback transaction
			return
		end

	if (select count(*) from mundial_futbol m1, inserted i
		where abs(m1.anio - i.anio) < 4 and m1.id != i.id) > 0
		begin
			raiserror('La diferencia entre cada mundial no puede ser menor a 4 años', 1, 1)
			rollback transaction
			return
		end

-- Tests
insert into mundial_futbol (id, anio, pais_campeon, pais_subcampeon) values
	(30, 2000, 'peru', 'peru'),
	(31, 2024, 'argentina', 'brasil')

select * from mundial_futbol


-- Final 16/12/2022
-- 3)
create table envases(
	enva_codigo int primary key,
	enva_detalle varchar(20)
)
create table productos (
	prod_codigo int primary key,
	prod_envase int foreign key references envases(enva_codigo),
	prod_detalle varchar(20)
)
create table depositos(
	depo_codigo int primary key,
	depo_nombre varchar(20)
)
create table stocks(
	stoc_producto int,
	stoc_deposito int,
	stoc_cantidad int

	constraint pk_stock primary key (stoc_producto, stoc_deposito),
	constraint fk_producto foreign key (stoc_producto) references productos(prod_codigo),
	constraint fk_deposito foreign key (stoc_deposito) references depositos(depo_codigo)
)
-- llenar tablas para probar!!
-- 3a)
select p.prod_codigo, 
	p.prod_envase,
	(select top 1 s1.stoc_deposito from stocks s1 where s1.stoc_producto = p.prod_codigo
		order by s1.stoc_cantidad desc),
	(select sum(s2.stoc_cantidad) from stocks s2 where s2.stoc_producto = p.prod_codigo)
from productos p
join stocks s on (s.stoc_producto = p.prod_codigo)
where s.stoc_cantidad > 0 and p.prod_envase in
	(select top 3 e1.enva_codigo from envases e1 join productos p1 on e1.enva_codigo = p1.prod_envase
	group by e1.enva_codigo
	order by count(e1.enva_codigo) desc)
group by p.prod_codigo, p.prod_envase
having count(p.prod_codigo) > ((select count(*) from depositos) / 2)
order by case when p.prod_codigo in 
	(select s3.stoc_producto from stocks s3 
	group by s3.stoc_producto 
	having count(s3.stoc_producto) = (select count(*) from depositos))
then 1 else 0 end

-- 3b)
create table borrar(
	codigo int primary key,
	detalle varchar(10)
)
insert into borrar values(1, 'X')

-- Proceso A
begin transaction
	set transaction isolation level repeatable read
	
	select * from borrar where codigo = 1

	update borrar set detalle='A'
	where codigo = 1
commit

-- Proceso B
begin transaction
	set transaction isolation level read committed
	
	select * from borrar where codigo = 1

	update borrar set detalle='B'
	where codigo = 1
commit


-- Final 06/12/2022
-- 3a)
select p.prod_codigo, 
	(select top 1 s1.stoc_deposito from stocks s1 where s1.stoc_producto = p.prod_codigo
		order by s1.stoc_cantidad desc),
	(select sum(s2.stoc_cantidad) from stocks s2 where s2.stoc_producto = p.prod_codigo) -- Verificar si con hacer sum(stoc_cantidad) funciona igual
from productos p
join stocks s on (s.stoc_producto = p.prod_codigo)
where s.stoc_cantidad > 0
group by p.prod_codigo
having count(p.prod_codigo) > ((select count(*) from depositos) / 2)
order by case when p.prod_codigo in 
	(select s3.stoc_producto from stocks s3 
	where s3.stoc_cantidad > 0
	group by s3.stoc_producto 
	having count(s3.stoc_producto) = (select count(*) from depositos))
then 1 else 0 end

-- 3b: Ambos procesos se bloquean. Con nivel Repeatable read sucede lo mismo
-- Proceso A
begin transaction
	set transaction isolation level serializable
	select * from borrar where codigo = 1
	update borrar set detalle='A'
	where codigo = 1
commit

-- Proceso B
begin transaction
	set transaction isolation level serializable
	select * from borrar where codigo = 1
	update borrar set detalle='B'
	where codigo = 1
commit


-- Final 09/09/2022
-- 3a) No importa el nivel de aislamiento, el resultado es el mismo
create table prueba (col int not null)

-- Proceso 1
begin transaction
	set transaction isolation level serializable
	declare @a as int
	declare @b as int
	select @a=count(*) from prueba
	select @b=count(*) from prueba

	print @a
	print @b
commit

-- Proceso 2
begin transaction
	set transaction isolation level serializable
	
	insert into prueba (col)
	select max(col)+1 from prueba -- El max devuelve null, y +1 sigue siendo null
commit

-- 3b) Se obtienen los dos numeros mas grandes
create table tablita(
	numero int unique
)
insert into tablita values
	(1), (4), (100), (5), (2), (null), (20), (30), (10), (69), (8)

select max(t1.numero), max(t2.numero) from tablita t1, tablita t2 where t1.numero > t2.numero


-- Final XX/YY/2022 **
-- 3a)
use Productos -- DB que usa Reinosa en la practica

select p.prod_detalle nombre_producto,
	isnull((select p2.prod_detalle from Producto p2 where p2.prod_codigo = c.comp_componente), 'sin compuesto') nombre_componente,
	isnull(c.comp_cantidad, 0) cant_unidades
from Producto p
left join Composicion c on (c.comp_producto = p.prod_codigo)

-- Otra solucion (con 2 join)
select p.prod_detalle nombre_producto,
	isnull(p2.prod_detalle, 'sin compuesto') nombre_componente,
	isnull(c.comp_cantidad, 0) cant_unidades
from Producto p
left join Composicion c on (c.comp_producto = p.prod_codigo)
left join Producto p2 on (p2.prod_codigo = c.comp_componente)

create table borrar(
	clave varchar(50)
)

-- 3b)
go
alter trigger tg_validar_precio on Composicion
after insert, update
as	
	if exists(select i.comp_producto
		from inserted i
		join Producto p1 on (i.comp_producto = p1.prod_codigo)
		join Producto p2 on (i.comp_componente = p2.prod_codigo)
		group by i.comp_producto, p2.prod_precio, p1.prod_precio
		having sum(i.comp_cantidad * p2.prod_precio) != p1.prod_precio)
	begin
		raiserror('Precio incorrecto', 1, 1)
		rollback transaction
		return
	end

-- Para que sea mas robusto, tambien habria que crear un trigger sobre Producto cuando se actualiza
-- Si se actualiza un producto compuesto, se debe validar que siga cumpliendo la regla del precio


-- Final XX/YY/2022 ****
-- 3)
create table pais(
	id int primary key,
	detalle varchar(20)
)
insert into pais values (1, 'austria'), (2, 'venezuela'), (3, 'zamoa'), (4, 'inglaterra'), 
	(5, 'argentina'), (6, 'chile'), (7, 'paraguay'), (8, 'uruguay'), (9, 'mexico'), 
	(10, 'eeuu'), (11, 'marruecos'), (12, 'belgica'), (13, 'francia'), (14, 'lituania')

-- 3a) No me queda claro el enunciado, por lo que devuelvo los primeros 5 paises, ordenados por detalle,
-- y los ultimos 5, tambien ordenados por detalle
select id, detalle from pais
where id in (select top 5 id from pais order by detalle asc) or
		id in (select top 5 id from pais order by detalle desc)
order by detalle

-- 3b)
create table provincia(
	id int primary key,
	id_pais int foreign key references pais(id),
	habitantes int
)
insert into provincia values 
	(1, 5, 10), (2, 5, 1000), (3, 5, 100), 
	(6, 2, 10), (8, 2, 10),
	(25, 9, 55)

select pa.id, sum(pr.habitantes), count(*)
from pais pa, provincia pr
where pa.id = pr.id_pais
group by pa.id


-- Final 21/02/2018
-- 3) Tablas idem Final XX/YY/2022 ****
create table ciudad(
	id int primary key,
	id_provincia int foreign key references provincia(id),
	nombre varchar(20)
)
insert into ciudad values
	(1, 1, 'caba'), (2, 1, 'lanus'), (3, 1, 'tigre')

-- 3a)
go
alter trigger tg_negocio on provincia
after insert, update
as
	if not exists(select c.id from ciudad c, inserted i where c.id_provincia = i.id)
	begin
		update provincia set habitantes = null
		where id in (select id from inserted)
	end
	else
	begin
		if exists(select * from inserted where habitantes <= 0)
		begin
			raiserror('Lo habitantes deben ser mayor a 0', 1, 1)
			rollback transaction
			return
		end
	end

-- Tests: Siempre que se crea una provincia, no va a tener ciudades
insert into provincia values (50, 5, 10) -- provincia sin ciudades --> el trigger deja habitantes en null
select * from provincia

insert into ciudad values (99, 50, 'tierra') -- creo una ciudad para la nueva provincia

update provincia set habitantes = -10 -- habitantes <= 0 --> error
where id = 50

update provincia set habitantes = 10 -- habitantes > 0 --> Ok
where id = 50

-- 3b)
select p.id, isnull(p.habitantes, 0), pa.detalle
from provincia p join pais pa on (p.id_pais = pa.id)
where p.habitantes = (select max(p2.habitantes) from provincia p2 where p2.id_pais = pa.id)
order by p.habitantes

select * from provincia
