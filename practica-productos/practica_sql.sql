use Productos

/* 1) Mostrar el código, razón social de todos los clientes cuyo límite 
de crédito sea mayor o igual a $ 1000 ordenado por código de cliente. */
SELECT c.clie_codigo, c.clie_razon_social
FROM Cliente c
WHERE c.clie_limite_credito >= 1000
ORDER BY c.clie_codigo


/* 2) Mostrar el código, detalle de todos los artículos vendidos 
en el año 2012 ordenados por cantidad vendida. */
SELECT p.prod_codigo, p.prod_detalle, sum(i.item_cantidad) cantidad_vendida
FROM Producto p
JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
JOIN Factura f ON (f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero)
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY p.prod_codigo, p.prod_detalle
-- HAVING YEAR(f.fact_fecha) = 2012 --Para determinar donde poner el filtro depende del contexto.
-- Hay que tener en cuenta que si se pone en el HAVING el filtro, se va a hacer sobre TODO el grupo
ORDER BY cantidad_vendida


/* 3) Realizar una consulta que muestre código de producto, nombre de producto y el stock total, 
sin importar en que deposito se encuentre, los datos deben ser ordenados por nombre del artículo de menor a mayor. */
SELECT p.prod_codigo, p.prod_detalle, SUM(s.stoc_cantidad) stock_total
FROM Producto p
JOIN STOCK s ON (s.stoc_producto = p.prod_codigo)
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY p.prod_detalle ASC

/* 4) Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de artículos que lo componen. 
 Mostrar solo aquellos artículos para los cuales el stock promedio por depósito sea mayor a 100. */

-- Opcion 1: en este caso es necesario el DISTINCT ya que Stock amplia el resultado de los join (por la atomicidad)
-- Si hubiese pedido un SUM en ves de COUNT ya no se podria hacer porque daria cualquier cosa
SELECT p.prod_codigo, p.prod_detalle, COUNT(DISTINCT c.comp_componente) cant_componentes--, SUM(s.stoc_cantidad) stock_total
FROM Producto p
LEFT JOIN Composicion c ON (c.comp_producto = p.prod_codigo)
JOIN STOCK s ON (s.stoc_producto = p.prod_codigo)
GROUP BY p.prod_codigo, p.prod_detalle
HAVING AVG(s.stoc_cantidad) > 1
ORDER BY 3 DESC

-- Opcion 2: se usa un subselect para evitar que la atomicidad cambie al querer joinear con Stock
SELECT p.prod_codigo, p.prod_detalle, COUNT(c.comp_componente) cant_componentes--, (SELECT sum(s.stoc_cantidad) FROM STOCK s WHERE s.stoc_producto = p.prod_codigo) stock_total
FROM Producto p
LEFT JOIN Composicion c ON (c.comp_producto = p.prod_codigo)
GROUP BY p.prod_codigo, p.prod_detalle
HAVING p.prod_codigo in (SELECT s.stoc_producto FROM STOCK s GROUP BY s.stoc_producto HAVING AVG(s.stoc_cantidad) > 1) -- subselect estatico
--HAVING (SELECT AVG(s.stoc_cantidad) FROM STOCK s WHERE s.stoc_producto = p.prod_codigo ) > 1 -- subselect dinamico
ORDER BY 3 DESC

-- Opcion 3: sumando la cantidad que tiene cada componente
SELECT
 p.prod_codigo,
 p.prod_detalle,
 ISNULL(SUM(c.comp_cantidad),0) 
FROM Producto p LEFT JOIN Composicion c
ON c.comp_producto = p.prod_codigo
GROUP BY 
 p.prod_codigo, 
 p.prod_detalle
HAVING  
 (SELECT AVG(s.stoc_cantidad) 
 FROM STOCK s 
 WHERE s.stoc_producto = p.prod_codigo ) > 1
ORDER BY 3 DESC


/* 5) Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de 
stock que se realizaron para ese artículo en el año 2012 (egresan los productos que 
fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011. */
SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) cant_vendida
FROM Producto p
JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
JOIN Factura f ON (f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero)
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY p.prod_codigo, p.prod_detalle
HAVING SUM(i.item_cantidad) >
	(SELECT ISNULL(SUM(i2.item_cantidad), 0)
	FROM Item_Factura i2
	JOIN Factura f2 ON (f2.fact_tipo + f2.fact_sucursal + f2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero)
	WHERE i2.item_producto = p.prod_codigo AND YEAR(f2.fact_fecha) = 2011)
ORDER BY 3


/* 6) Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese 
rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que 
tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’. */-- Opcion 1: solucion correcta, un subselect en una columna para no afectar el joinSELECT r.rubr_id, r.rubr_detalle, COUNT(p.prod_codigo) cant_articulos, 	((SELECT ISNULL(SUM(s1.stoc_cantidad), 0) FROM STOCK s1 JOIN Producto p1 ON s1.stoc_producto = p1.prod_codigo	WHERE p1.prod_rubro = r.rubr_id HAVING SUM(s1.stoc_cantidad) > 	(SELECT SUM(s2.stoc_cantidad) FROM STOCK s2 WHERE s2.stoc_producto = '00000000' AND s2.stoc_deposito= '00'))) stock_totalFROM Rubro rJOIN Producto p ON (p.prod_rubro = r.rubr_id)GROUP BY r.rubr_id, r.rubr_detalle-- Opcion 2: como lo hice yo, al joinear con Stock cambia la atomicidad por lo tanto los sum/count no es lo mismoSELECT r.rubr_id, r.rubr_detalle, COUNT(DISTINCT p.prod_codigo) cant_articulos, SUM(s.stoc_cantidad) stock_totalFROM Rubro rJOIN Producto p ON (p.prod_rubro = r.rubr_id)JOIN STOCK s ON (s.stoc_producto = p.prod_codigo)GROUP BY r.rubr_id, r.rubr_detalleHAVING SUM(s.stoc_cantidad) >	(SELECT SUM(s2.stoc_cantidad) FROM STOCK s2	WHERE s2.stoc_producto = '00000000' AND s2.stoc_deposito= '00')order by 1-- Opcion 3: otra solucion, mismo caso que 2. SELECT r.rubr_id, r.rubr_detalle, COUNT(DISTINCT p.prod_codigo) cant_articulos, SUM(s.stoc_cantidad) stock_totalFROM Rubro rJOIN Producto p ON (p.prod_rubro = r.rubr_id)JOIN STOCK s ON (s.stoc_producto = p.prod_codigo)WHERE (SELECT SUM(s1.stoc_cantidad) FROM STOCK s1 WHERE s1.stoc_producto = s.stoc_producto) >	(SELECT SUM(s2.stoc_cantidad) FROM STOCK s2 WHERE s2.stoc_producto = '00000000' AND s2.stoc_deposito= '00')GROUP BY r.rubr_id, r.rubr_detalle/* 7) Generar una consulta que muestre para cada artículo código, detalle, mayor precio 
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio = 10, 
mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean stock. */
SELECT p.prod_codigo, p.prod_detalle, MAX(i.item_precio) mayor_precio, MIN(i.item_precio) menor_precio,
	((MAX(i.item_precio) / MIN(i.item_precio) - 1) * 100) porcentaje_diferencia
FROM Producto p
JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
JOIN STOCK s ON (s.stoc_producto = p.prod_codigo)
WHERE s.stoc_cantidad > 0
GROUP BY p.prod_codigo, p.prod_detalle


-- Opcion alternativa: aca se considera que en todos los depositos la suma de la cantidad de stock de un producto sea mayor a 0
SELECT p.prod_codigo, p.prod_detalle, MAX(i.item_precio) mayor_precio, MIN(i.item_precio) menor_precio,
	((MAX(i.item_precio) - MIN(i.item_precio)) / MIN(i.item_precio)) * 100
FROM Producto p
JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
WHERE (SELECT SUM(s.stoc_cantidad) FROM STOCK s WHERE s.stoc_producto = p.prod_codigo) > 0
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY p.prod_codigo

-- Opcion alternativa 2: idem caso anterior
SELECT p.prod_codigo, p.prod_detalle, MAX(i.item_precio) mayor_precio, MIN(i.item_precio) menor_precio,
	((MAX(i.item_precio) - MIN(i.item_precio)) / MIN(i.item_precio)) * 100
FROM Producto p
JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
JOIN STOCK s ON (s.stoc_producto = p.prod_codigo)
GROUP BY p.prod_codigo, p.prod_detalle
HAVING SUM(ISNULL(s.stoc_cantidad, 0)) > 0
ORDER BY p.prod_codigo


/* 8) Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
artículo, stock del depósito que más stock tiene */
SELECT p.prod_codigo, p.prod_detalle, MAX(s.stoc_cantidad) stock_max
FROM Producto p
JOIN STOCK s ON (s.stoc_producto = p.prod_codigo)
WHERE s.stoc_cantidad > 0
GROUP BY p.prod_codigo, p.prod_detalle
HAVING COUNT(*) = (SELECT COUNT(*) FROM DEPOSITO)
-- no muestra nada porque no existe un producto que este en todos los depositos

-- Opcion alternativa: se muestra el producto que tiene stock mayor a 0 en todos los depositos donde se encuentre
SELECT p.prod_codigo, p.prod_detalle, MAX(s.stoc_cantidad) stock_max
FROM Producto p
JOIN STOCK s ON (s.stoc_producto = p.prod_codigo)
WHERE p.prod_codigo not in (select distinct s1.stoc_producto from STOCK s1 where s1.stoc_cantidad < 0)
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY p.prod_codigo


/* 9) Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de depósitos que ambos tienen asignados */
SELECT e.empl_jefe codigo_jefe, e.empl_codigo codigo_empleado, e.empl_apellido, COUNT(d.depo_codigo) depositos_a_cargo
FROM Empleado e
JOIN DEPOSITO d ON (d.depo_encargado = e.empl_codigo OR d.depo_encargado = e.empl_jefe)
GROUP BY e.empl_jefe, e.empl_codigo, e.empl_apellido

-- Opcion 2: si bien no es necesario el join empleado/emppleado esto permite tener los datos de ambos
SELECT j.empl_codigo codigo_jefe, j.empl_apellido jefe_apellido, 
	e.empl_codigo codigo_empleado, e.empl_apellido, COUNT(d.depo_codigo) depositos_a_cargo
FROM Empleado j
RIGHT JOIN Empleado e ON (e.empl_jefe = j.empl_codigo)
JOIN DEPOSITO d ON (d.depo_encargado = j.empl_codigo or d.depo_encargado = e.empl_codigo)
GROUP BY j.empl_codigo, j.empl_apellido, e.empl_codigo, e.empl_apellido


/* 10) Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos 
vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que mayor compra realizo. */
--SELECT i.item_producto, SUM(i.item_cantidad) cant_vendido,
SELECT i.item_producto, SUM(i.item_cantidad) cant_vendido,
	(SELECT TOP 1 f.fact_cliente FROM Factura f
	JOIN Item_Factura i3 ON (i3.item_tipo+i3.item_sucursal+i3.item_numero = f.fact_tipo+f.fact_sucursal+f.fact_numero)
	WHERE i3.item_producto = i.item_producto
	GROUP BY f.fact_cliente
	ORDER BY SUM(i3.item_cantidad) DESC
	) cliente_mayor_compra
FROM Item_Factura i
WHERE i.item_producto IN
		(SELECT TOP 10 i1.item_producto 
		FROM Item_Factura i1
		GROUP BY i1.item_producto 
		ORDER BY SUM(i1.item_cantidad) DESC)
	OR i.item_producto IN
		(SELECT TOP 10 i2.item_producto 
		FROM Item_Factura i2
		GROUP BY i2.item_producto 
		ORDER BY SUM(i2.item_cantidad) ASC)
GROUP BY i.item_producto
ORDER BY 2 DESC

-- Idem anterior pero usando tabla Producto en ves de Item_Factura
SELECT p.prod_codigo, p.prod_detalle,
	(SELECT TOP 1 f.fact_cliente FROM Factura f
	JOIN Item_Factura i3 ON (i3.item_tipo+i3.item_sucursal+i3.item_numero = f.fact_tipo+f.fact_sucursal+f.fact_numero)
	WHERE i3.item_producto = p.prod_codigo
	GROUP BY f.fact_cliente
	ORDER BY SUM(i3.item_cantidad) DESC
	) cliente_mayor_compra
FROM Producto p
WHERE p.prod_codigo IN
		(SELECT TOP 10 i1.item_producto 
		FROM Item_Factura i1
		GROUP BY i1.item_producto 
		ORDER BY SUM(i1.item_cantidad) DESC)
	OR p.prod_codigo IN
		(SELECT TOP 10 i2.item_producto 
		FROM Item_Factura i2
		GROUP BY i2.item_producto 
		ORDER BY SUM(i2.item_cantidad) ASC)


/* 11) Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán 
ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga, 
solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para 
el año 2012 */

-- Para resolver esto se debe considerar que hay que mostrar TODAS las familias del historial
-- y por ultimo considerar solo aquellas que superan 20000 en el 2012

-- Opcion 1: subselect estatico
SELECT f.fami_id, f.fami_detalle, COUNT(DISTINCT i.item_producto) cant_deferentes, SUM(i.item_cantidad*i.item_precio) total_sin_impuestos
FROM Familia f
JOIN Producto p ON (p.prod_familia = f.fami_id)
JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
GROUP BY f.fami_id, f.fami_detalle
HAVING f.fami_id IN (SELECT p2.prod_familia FROM Factura fa2
					JOIN Item_Factura i2 ON (fa2.fact_tipo + fa2.fact_sucursal + fa2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero)
					JOIN Producto p2 ON (p2.prod_codigo = i2.item_producto)
					WHERE  YEAR(fa2.fact_fecha) = 2012
					GROUP BY p2.prod_familia
					HAVING SUM(i2.item_cantidad * i2.item_precio) > 20000)
ORDER BY 3 DESC

-- Opcion 2: correlacion en subselect
SELECT f.fami_id, f.fami_detalle, COUNT(DISTINCT i.item_producto) cant_deferentes, SUM(i.item_cantidad*i.item_precio) total_sin_impuestos
FROM Familia f
JOIN Producto p ON (p.prod_familia = f.fami_id)
JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
GROUP BY f.fami_id, f.fami_detalle
HAVING (
	SELECT SUM(i2.item_cantidad*i2.item_precio) FROM Factura fa2
	JOIN Item_Factura i2 ON (fa2.fact_tipo + fa2.fact_sucursal + fa2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero)
	JOIN Producto p2 ON (p2.prod_codigo = i2.item_producto)
	WHERE p2.prod_familia = f.fami_id AND YEAR(fa2.fact_fecha) = 2012
) > 20000
ORDER BY 3 DESC

-- Opcion 3: subselect en el where, menos performante
SELECT f.fami_id, f.fami_detalle, COUNT(DISTINCT i.item_producto) cant_deferentes, SUM(i.item_cantidad*i.item_precio) total_sin_impuestos
FROM Familia f
JOIN Producto p ON (p.prod_familia = f.fami_id)
JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
WHERE (
	SELECT SUM(i2.item_cantidad*i2.item_precio) FROM Factura fa2
	JOIN Item_Factura i2 ON (fa2.fact_tipo + fa2.fact_sucursal + fa2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero)
	JOIN Producto p2 ON (p2.prod_codigo = i2.item_producto)
	WHERE p2.prod_familia = f.fami_id AND YEAR(fa2.fact_fecha) = 2012
) > 20000
GROUP BY f.fami_id, f.fami_detalle
ORDER BY 3 DESC


/* 12) Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe 
promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del 
producto y stock actual del producto en todos los depósitos. Se deberán mostrar 
aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán 
ordenarse de mayor a menor por monto vendido del producto. */

-- NOTA: al igual que el ej 11) hay que mostrar todo el historial pero considerando
-- aquellos que se vendio en 2012. NO se puede o no se debe filtrar en el WHERE del select principal

-- Opcion 1: subselect estatico
SELECT p.prod_codigo, p.prod_detalle, COUNT(DISTINCT fa.fact_cliente) cant_clientes, AVG(i.item_precio) precio_promedio, 
	(SELECT COUNT(DISTINCT s.stoc_deposito) from stock s WHERE s.stoc_producto = p.prod_codigo AND s.stoc_cantidad > 0) cant_depositos,
	(SELECT SUM(s.stoc_cantidad) FROM stock s WHERE s.stoc_producto = p.prod_codigo AND s.stoc_cantidad > 0) stock_total
FROM Producto p
JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
JOIN Factura fa ON fa.fact_tipo + fa.fact_sucursal + fa.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
WHERE p.prod_codigo IN (
	SELECT i1.item_producto FROM Item_Factura i1
	JOIN Factura f1 ON f1.fact_tipo + f1.fact_sucursal + f1.fact_numero = i1.item_tipo + i1.item_sucursal + i1.item_numero
	WHERE YEAR(f1.fact_fecha) = 2012
	GROUP BY i1.item_producto
)
GROUP BY p.prod_codigo, p.prod_detalle
order by SUM(i.item_cantidad * i.item_precio) DESC

-- Opcion 2: subselect correlacionado
SELECT p.prod_codigo, p.prod_detalle, COUNT(DISTINCT fa.fact_cliente) cant_clientes, AVG(i.item_precio) precio_promedio, 
	(SELECT COUNT(DISTINCT s.stoc_deposito) from stock s WHERE s.stoc_producto = p.prod_codigo AND s.stoc_cantidad > 0) cant_depositos,
	(SELECT SUM(s.stoc_cantidad) FROM stock s WHERE s.stoc_producto = p.prod_codigo AND s.stoc_cantidad > 0) stock_total
FROM Producto p
JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
JOIN Factura fa ON fa.fact_tipo + fa.fact_sucursal + fa.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
WHERE EXISTS (
	SELECT 1 FROM Item_Factura i1
	JOIN Factura f1 ON f1.fact_tipo + f1.fact_sucursal + f1.fact_numero = i1.item_tipo + i1.item_sucursal + i1.item_numero
	WHERE i1.item_producto = p.prod_codigo AND YEAR(f1.fact_fecha) = 2012
)
GROUP BY p.prod_codigo, p.prod_detalle
order by SUM(i.item_cantidad * i.item_precio) DESC


/* 13) Realizar una consulta que retorne para cada producto que posea composición nombre 
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad 
de los productos que lo componen. Solo se deberán mostrar los productos que estén 
compuestos por más de 2 productos y deben ser ordenados de mayor a menor por 
cantidad de productos que lo componen */

-- Opcion 1: subselect correlacionado
SELECT p.prod_codigo, p.prod_detalle, p.prod_precio, 
	(SELECT SUM(p1.prod_precio * c1.comp_cantidad)
	FROM Composicion c1
	JOIN Producto p1 ON (p1.prod_codigo = c1.comp_componente)
	WHERE c1.comp_producto = p.prod_codigo) precio_componentes
FROM Producto p
JOIN Composicion c ON (c.comp_producto = p.prod_codigo)
GROUP BY p.prod_codigo, p.prod_detalle, p.prod_precio
HAVING SUM(c.comp_cantidad) > 2
ORDER BY SUM(c.comp_cantidad) DESC

-- Opcion 2: realizando un join mas
SELECT p.prod_codigo, p.prod_detalle, p.prod_precio, SUM(p2.prod_precio * c.comp_cantidad) precio_componentes
FROM Producto p -- Combo
JOIN Composicion c ON (c.comp_producto = p.prod_codigo)
JOIN Producto p2 ON (p2.prod_codigo = c.comp_componente) -- Componente
GROUP BY p.prod_codigo, p.prod_detalle, p.prod_precio
HAVING SUM(c.comp_cantidad) > 2
ORDER BY SUM(c.comp_cantidad) DESC

/* 14) Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que debe retornar son:
Código del cliente
Cantidad de veces que compro en el último año
Promedio por compra en el último año
Cantidad de productos diferentes que compro en el último año
Monto de la mayor compra que realizo en el último año
Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en el último año.
No se deberán visualizar NULLs en ninguna columna */
SELECT f.fact_cliente, COUNT(DISTINCT f.fact_tipo + f.fact_sucursal + f.fact_numero) cant_compras, AVG(f.fact_total) promedio_compra, 
	COUNT(DISTINCT i.item_producto) cant_prod_diferentes, MAX(f.fact_total) monto_mayor_compra
FROM Cliente c
JOIN Factura f ON (f.fact_cliente = c.clie_codigo)
JOIN Item_Factura i ON f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
WHERE YEAR(f.fact_fecha) = (SELECT TOP 1 YEAR(f2.fact_fecha) FROM Factura f2 ORDER BY f2.fact_fecha DESC)
GROUP BY f.fact_cliente
UNION
SELECT c1.clie_codigo, 0, 0, 0, 0 FROM Cliente c1
WHERE c1.clie_codigo NOT IN (SELECT f1.fact_cliente FROM Factura f1
	WHERE YEAR(f1.fact_fecha) = (SELECT TOP 1 YEAR(f2.fact_fecha) FROM Factura f2 ORDER BY f2.fact_fecha DESC))
ORDER BY 2 DESC


/* 15) Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos 
(en la misma factura) más de 500 veces. El resultado debe mostrar el código y 
descripción de cada uno de los productos y la cantidad de veces que fueron vendidos 
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron 
juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
Ejemplo de lo que retornaría la consulta:
PROD1	DETALLE1			PROD2	DETALLE2				VECES
1731	MARLBORO KS			1718	PHILIPS MORRIS KS		507
1718	PHILIPS MORRIS KS	1705	PHILIPS MORRIS BOX 1	562   */SELECT p1.prod_codigo prod1, p1.prod_detalle detalle1, p2.prod_codigo prod1, p2.prod_detalle detalle2, COUNT(*) veces_vendidos_juntosFROM Producto p1 JOIN Item_Factura i1 ON (i1.item_producto = p1.prod_codigo)JOIN Item_Factura i2 ON (i2.item_tipo = i1.item_tipo AND i2.item_sucursal = i1.item_sucursal AND i2.item_numero = i1.item_numero)JOIN Producto p2 ON (p2.prod_codigo = i2.item_producto)WHERE p2.prod_codigo > p1.prod_codigoGROUP BY p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalleHAVING COUNT(*) > 500ORDER BY 5 DESC-- Esta solucion realiza el producto cartesiano, lo cual no esta del todo bien-- ya que despues se filtra en el whereSELECT p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle, count(*) cant_vendidad_en_conjFROM Producto p1 JOIN Item_Factura i1 ON (i1.item_producto = p1.prod_codigo),	Producto p2 JOIN Item_Factura i2 ON (i2.item_producto = p2.prod_codigo)WHERE i1.item_tipo = i2.item_tipo AND i1.item_sucursal = i2.item_sucursal AND i1.item_numero = i2.item_numero	AND p1.prod_codigo > p2.prod_codigoGROUP BY p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalleHAVING count(*) > 500