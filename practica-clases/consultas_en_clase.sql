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

-- Clase 3: 15/04/2023

-- Alternativa al uso de JOIN
SELECT p.prod_codigo, p.prod_detalle, f.fami_id, f.fami_detalle
FROM Producto p, Familia f
WHERE p.prod_familia = f.fami_id
ORDER BY p.prod_codigo
-- Nota: no poner el WHERE va a hacer el producto cartesiano de ambas tablas. Pero si se agrega la condicion entonces
-- el motor realiza la optimizacion necesario para que la consulta sea igual que con un JOIN

-- Right join: trae la interseccion y las filas de la tabla derecha
SELECT p.prod_codigo, p.prod_detalle, f.fami_id, f.fami_detalle
FROM Producto p
RIGHT JOIN Familia f ON (p.prod_familia = f.fami_id)
ORDER BY p.prod_codigo 


-- Funciones de grupo VERRRRRR VIDEOOOOOOOOOOOOOOO
SELECT f.fami_id, f.fami_detalle, count(*)
FROM Producto p
JOIN Familia f ON p.prod_familia = f.fami_id
GROUP BY f.fami_id, f.fami_detalle

-- count(campo): cuenta solo si el campo es no nulo
-- count(*): cuenta si hay al menos un campo no nulo
-- count(constante): cuenta las filas sin importar si hay todo nulo

-- Otras funciones de grupo:
-- SUM(campo)
-- AVG(campo)
-- MIN(campo)
-- MAX(campo)
-- COUNT(DISTINCT campo)

-- HAVING
-- Sirve para filtrar a nivel de grupo, es decir se usa en conjunto con el GROUP BY (el WHERE filtra a nivel de filas de las tablas
-- del producto cartesiano)





