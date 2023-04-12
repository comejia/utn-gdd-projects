use Productos

-- Clase 2: 08/04/2023

-- Obtener el detalle, familia y rubro de los productos
SELECT p.prod_codigo, p.prod_detalle, f.fami_detalle, r.rubr_detalle
FROM Producto p
JOIN Familia f ON (p.prod_familia = f.fami_id)
JOIN Rubro r ON (p.prod_rubro = r.rubr_id)

-- Obtener de la tabla Composicion el detalle de los productos y sus componentes, y la cantidad de componentes
SELECT p_prod.prod_detalle as detalle_producto, p_comp.prod_detalle as detalle_componente, c.comp_cantidad as cantidad
FROM Composicion c
INNER JOIN Producto p_prod ON (p_prod.prod_codigo = c.comp_producto)
INNER JOIN Producto p_comp ON (p_comp.prod_codigo = c.comp_componente)


-- Mostrar codigo y nombre de empleado y el nombre de su jefe
SELECT e.empl_codigo, e.empl_nombre as empleado_nombre, e.empl_apellido empleado_apellido, j.empl_nombre as jefe_nombre, j.empl_apellido as jefe_apellido
FROM Empleado e
JOIN Empleado j ON (e.empl_jefe = j.empl_codigo)
-- LEFT JOIN Empleado j ON (e.empl_jefe = j.empl_codigo) -- Muestra a Juan Perez como empleado por mas que no tenga jefe

