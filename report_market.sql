/*
============================================================================
Market Report | key metrics and behaviors
============================================================================

Puntos:
 1. Campos escenciales: tipo de tienda,distrito, ciudad,pais fecha de transaccion
 2. segmentacion de productos (alta venta, media y baja prioridad),por ventas y revenue
 3. tienda metrics:
	- numero de compras
	- productos vendidos
	- numero de clientes
	- ingresos totales
	- utilidad bruta	
	- ticket promedio
4. calculo de KPI's
	- promedio de compras mensuales
	- promedio ingresos mensuales
	- promedio utilidad bruta mensuales
	*/

	/* 
	---------------------------------------------------------------------------------
	BASE QUERY: union de tablas y extracción de campos relevantes
	---------------------------------------------------------------------------------
	*/
CREATE VIEW dbo.report_market AS

WITH primary_base AS(
SELECT
	v.id_tienda,
	t.tipo_tienda,
	t.ciudad_tienda, 
	t.pais_tienda,
	v.fecha_transaccion,
	v.id_producto,
	v.id_cliente,
	v.cantidad_vendida,
	p.precio,
	p.costo
FROM (
SELECT*
FROM [Ventas 2027]
UNION 
SELECT*
FROM [Ventas 2028]) v
LEFT JOIN Tiendas t
ON t.id_tienda=v.id_tienda
LEFT JOIN Productos p 
ON p.id_producto=v.id_producto)


/* ---------------------------------------------------------------------------------
	Aggegations: calculos basicos agregados por tienda
------------------------------------------------------------------------------------*/
,agregation AS(
SELECT
	id_tienda,
	tipo_tienda,
	ciudad_tienda,
	pais_tienda,
	COUNT(fecha_transaccion) num_compras,
	count(DISTINCT id_producto) num_productos,
	COUNT(DISTINCT id_cliente) num_clientes,
	ROUND(SUM(cantidad_vendida*precio),0) ingresos,
	ROUND(AVG(cantidad_vendida*precio),2) ticket_promedio,
	ROUND(SUM(cantidad_vendida*precio)-SUM(cantidad_vendida*costo),0) AS utilidad_bruta,
	DATEDIFF(month, MIN(fecha_transaccion),MAX(fecha_transaccion)) AS lifespan
FROM primary_base
GROUP BY 
	id_tienda,
	tipo_tienda,
	ciudad_tienda,
	pais_tienda)

/* ---------------------------------------------------------------------------------
	KPI's
------------------------------------------------------------------------------------*/
/*  - promedio de compras mensuales
	- promedio ingresos mensuales
	- promedio utilidad bruta mensuales*/
SELECT
	id_tienda,
	tipo_tienda,
	ciudad_tienda,
	pais_tienda,
	num_compras,
	num_productos,
	num_clientes,
	ingresos,
	ticket_promedio,
	utilidad_bruta,
	ROUND(num_compras/lifespan,2) AS compras_mensual,
	ROUND(ingresos/lifespan,2)  AS ingresos_mensual,
	ROUND(utilidad_bruta/lifespan,2) AS utilidad_mensual,
	CONCAT(ROUND(utilidad_bruta/ingresos*100,0),' %') AS margen_utilidad
FROM agregation
