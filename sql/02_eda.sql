/* =======================================================================
OBJETIVO:
   - Identificar patrones, valores nulos y anomalías en la capa Bronze.
   - Definir las reglas de limpieza que se aplicarán en la capa Silver.
   ======================================================================= */

USE proyectotesoreria_db;
GO

--1.Determinar presencia de valores duplicados:
SELECT count(*) as 'total_invoices', count(distinct invoice_id) as 'unique_invoices'
from stg_invoices
--Identificamos 120 invoice_id duplicados.

SELECT COUNT(*)as 'total_payments',COUNT(distinct(payment_id)) as 'unique_payments'
from stg_payments
--Identificamos 80 invoice_id duplicados.

--2.Conocer los valores duplicados:
SELECT payment_id, COUNT(*)
FROM stg_payments
GROUP BY payment_id
HAVING COUNT(*) > 1
--Se confirma filas duplicadas en la tabla stg_payments, se eliminará la fila repetida en la capa silver.
SELECT invoice_id, COUNT(*)
FROM stg_invoices
GROUP BY invoice_id
HAVING COUNT(*) > 1
--Se confirma filas duplicadas en la tabla stg_invoices, se eliminará la fila repetida en la capa silver.

--3.Determinar presencia de valores nulos:
SELECT COUNT(*) AS 'total_rows', 
       count(payment_amount) as 'non_nulls',
       count(*)-count(payment_amount) as 'nulls'
FROM stg_payments
--Del total de 4580 filas en la columna payment_amount, 131 tiene valores nulos.
SELECT count(*) as 'total_rows',
      count (invoice_amount) as 'non_nulls',
      count(*)-count(invoice_amount) as 'nulls'
from stg_invoices
--Del total de 6120 filas en la columna invoice_amount, 300 tiene valores nulos.

--4.Conocer si todas las fechas tienen el formato correcto.
select issue_date
from stg_invoices
where ISDATE(issue_date)=0

select due_date
from stg_invoices
where ISDATE(due_date)=0

select payment_date
from stg_payments
where ISDATE(payment_date)=0
--Todas las fechas tienen formato correcto (DATE).

--5.Conocer el rango de fechas.
select max(cast(payment_date as date)) AS 'max_date',
       min (cast (payment_date as date)) as 'min_date'
from stg_payments

select max(cast(issue_date as date)) AS 'max_date',
       min (cast (issue_date as date)) as 'min_date'
from stg_invoices

select max(cast(due_date as date)) AS 'max_date',
       min (cast (due_date as date)) as 'min_date'
from stg_invoices
--El rango va desde el 2023-01-01(issue_date) hasta el 2025-05-30(due_date)
--No presentan datos absurdos, ni nulos, ni outliers.

--6.Verificar si existen proveedores en facturas que no esten en su tabla de proveedores.
SELECT DISTINCT supplier_id 
FROM stg_invoices 
WHERE supplier_id NOT IN (SELECT supplier_id FROM stg_suppliers)
--No existe ningún proveedor en la tabla Invoices ajeno a la tabla stg_suppliers.

--7.Verificar la consistencia de los datos.
select invoice_id,due_date,issue_date
from stg_invoices
where cast(due_date as date)< cast (issue_date as date)
--Confirmamos que no existe ningun caso donde la feha de emision sea posterior a la de vencimiento.

--8.Conocer si hay pagos adelantados (anticipos)
select invoice_id,due_date,issue_date
from stg_invoices
where cast(due_date as date)< cast (issue_date as date)
--Detectamos que hay 2328 pagos realizados antes de la fecha de emision de la factura.

--9.Conocer si hay facturas relacionadas a varios pagos.
with invoice_temporal 
as (
select invoice_id,count (*) as 'cantidad_pagos'
from stg_payments
group by invoice_id
)
select cantidad_pagos, count(invoice_id) as total_facturas
from invoice_temporal
group by cantidad_pagos
order by cantidad_pagos
--Se descubrió que son 2063 facturas que fueron pagados en 1 pago, 780 facturas en 2 pagos, 232 en 3 pagos, 
--50 en 4 pagos, 11 en 5 pagos y 1 factura en 6 pagos.

--10.Conocer si hay pagos relacionados a varias facturas.
SELECT payment_id, COUNT(invoice_id) AS cantidad_facturas_por_pago
FROM stg_payments
GROUP BY payment_id
HAVING COUNT(invoice_id) > 1
ORDER BY cantidad_facturas_por_pago DESC
--Se detecto 80 valores con 2 facturas relacionadas correspondiente a los 80 duplicados ya encontrados. 
--Se confirma que no hay pagos relacionados a varias facturas.