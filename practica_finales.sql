use Pruebas

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

-- 3b) Resuelto en: Final 01/08/2023

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

-- 3a) Mostrar el ultimo que gano un mundial que solo tienen UNA conquista
--select pais_campeon from mundial_futbol
--group by pais_campeon
--having count(*) = 1
--order by anio desc -- error porque anio no esta en el group by. Se esta usando funciona agregada: count

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