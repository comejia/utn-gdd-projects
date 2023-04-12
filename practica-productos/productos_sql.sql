use Productos

-- 1) Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o igual a $ 1000 ordenado por código de cliente.
SELECT c.clie_codigo, c.clie_razon_social
FROM Cliente c
WHERE c.clie_limite_credito >= 1000
ORDER BY c.clie_codigo

-- 2) Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por cantidad vendida.
SELECT p.prod_codigo, p.prod_detalle
FROM Factura f
INNER JOIN Item_Factura i_f ON (f.fact_tipo = i_f.item_tipo AND f.fact_sucursal = i_f.item_sucursal AND f.fact_numero = i_f.item_numero)
INNER JOIN Producto p ON (p.prod_codigo = i_f.item_producto)
WHERE YEAR(f.fact_fecha) = 2012
ORDER BY i_f.item_cantidad
