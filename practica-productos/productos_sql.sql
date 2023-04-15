use Productos

-- 1) Mostrar el c�digo, raz�n social de todos los clientes cuyo l�mite de cr�dito sea mayor o igual a $ 1000 ordenado por c�digo de cliente.
SELECT c.clie_codigo, c.clie_razon_social
FROM Cliente c
WHERE c.clie_limite_credito >= 1000
ORDER BY c.clie_codigo

-- 2) Mostrar el c�digo, detalle de todos los art�culos vendidos en el a�o 2012 ordenados por cantidad vendida.
SELECT p.prod_codigo, p.prod_detalle, sum(i_f.item_cantidad) cantidad_vendida
FROM Factura f
INNER JOIN Item_Factura i_f ON (f.fact_tipo = i_f.item_tipo AND f.fact_sucursal = i_f.item_sucursal AND f.fact_numero = i_f.item_numero)
INNER JOIN Producto p ON (p.prod_codigo = i_f.item_producto)
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY p.prod_codigo, p.prod_detalle
-- HAVING YEAR(f.fact_fecha) = 2012 Para determinar donde poner el filtro depende del contexto.
-- Hay que tener en cuenta que si se pone en el HAVING el filtro, se va a hacer sobre TODO el grupo
ORDER BY cantidad_vendida ASC

-- 3) Realizar una consulta que muestre c�digo de producto, nombre de producto y el stock total, 
-- sin importar en que deposito se encuentre, los datos deben ser ordenados por nombre del art�culo de menor a mayor.
SELECT p.prod_codigo, p.prod_detalle, SUM(s.stoc_cantidad) cantidad
FROM Producto p
INNER JOIN STOCK s ON s.stoc_producto = p.prod_codigo
INNER JOIN DEPOSITO d ON d.depo_codigo = s.stoc_deposito
GROUP BY p.prod_codigo, p.prod_detalle


-- 4) Realizar una consulta que muestre para todos los art�culos c�digo, detalle y cantidad de art�culos que lo componen. 
-- Mostrar solo aquellos art�culos para los cuales el stock promedio por dep�sito sea mayor a 100.