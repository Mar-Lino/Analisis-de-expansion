/*
============================================================================
Customer Report | key customer metrics and behaviors
============================================================================

Puntos:
 1. Campos escenciales: nombre, edad y transacciones
 2. segmentacion de clientes (alta, media y baja prioridad)
 3. customer metrics:
	- total orders
	- total sales
	- ventas totales
	- devoluciones
	- lifespan
4. calculo de KPI's
	-  percevy months since last order
	- promedio de compras
	- promedio mensual de ticket
	*/

	/* 
	---------------------------------------------------------------------------------
	BASE QUERY: union de tablas y extracción de campos relevantes
	---------------------------------------------------------------------------------
	*/
CREATE VIEW dbo.report_customer AS

WITH base AS(
SELECT
	ventas.fecha_transaccion,
	ventas.id_producto,
	p.precio,
	ventas.cantidad_vendida,
	p.precio*ventas.cantidad_vendida AS venta,
	p.nombre_producto,
	ventas.id_cliente,
	ventas.id_tienda,
	CONCAT(c.nombre,' ',c.apellido) nombre,
	c.fecha_nacimiento,
	DATEDIFF(year,c.fecha_nacimiento,GETDATE()) edad,
	c.pais_cliente,
	c.ingreso_anual,
	c.fecha_apertura_cuenta,
	c.tipo_membresia
FROM (SELECT*
FROM [Ventas 2027]
UNION ALL
SELECT*
FROM [Ventas 2028]) ventas
LEFT JOIN Clientes c
ON c.id_cliente=ventas.id_cliente
LEFT JOIN Productos p 
ON ventas.id_producto=p.id_producto)

/* ---------------------------------------------------------------------------------
	Aggegations: calculos basicos agregados por cliente
------------------------------------------------------------------------------------*/
,calculos AS(
SELECT
	id_cliente,
	nombre,
	edad,
	pais_cliente,
	tipo_membresia,
	ingreso_anual,
	COUNT(DISTINCT fecha_transaccion) ordenes_totales,
	ROUND(SUM(venta),2) compra_total,
	SUM(cantidad_vendida) unidades_vendidas,
	COUNT(DISTINCT id_producto) productos_vendidos,
	DATEDIFF(month, MIN(fecha_transaccion),MAX(fecha_transaccion)) AS lifespan
FROM base
GROUP BY 
	id_cliente,
	nombre,
	edad,
	pais_cliente,
	tipo_membresia,
	ingreso_anual)

/* ---------------------------------------------------------------------------------
	segmentación y KPI's: 
------------------------------------------------------------------------------------*/

SELECT
	id_cliente,
	nombre,
	edad,
	pais_cliente,
	tipo_membresia,
	ingreso_anual,
	ordenes_totales,
	compra_total,
	unidades_vendidas,
	productos_vendidos,
	CASE 
		WHEN edad<25 THEN 'menor de 25'
		WHEN edad BETWEEN 25 AND 40 THEN '25 a 40'
		WHEN edad BETWEEN 41 AND 60 THEN '41 a 60'
		ELSE 'mayor de 60' END rango_edad,
	CASE
		WHEN tipo_membresia= 'Premium' OR compra_total>=2000 THEN 'Alta'
		WHEN tipo_membresia<> 'Premium' AND compra_total BETWEEN 1000 AND 1999 THEN 'Media'
		ELSE 'Baja' END prioridad,
	CASE
		WHEN lifespan>=18 THEN 'frecuente'
		WHEN lifespan BETWEEN 12 AND 18 THEN 'promedio'
		WHEN lifespan <12 THEN 'ocasional' END lealtad,
		compra_total/ordenes_totales AS ticket_promedio
FROM calculos



