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
-- Resultado: 
-- total_invoices=6120
-- unique_invoices=6000
--Identificamos 120 invoice_id duplicados.

SELECT COUNT(*)as 'total_payments',COUNT(distinct(payment_id)) as 'unique_payments'
from stg_payments
-- Resultado: 
-- total_payments=6120
-- unique_payments=6000
--Identificamos 80 payment_id duplicados.

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
-- Resultado: 
-- total_rows=4580
-- non_nulls=4449
-- nulls=131
--Identificamos 131 valores nulos.
   
SELECT count(*) as 'total_rows',
      count (invoice_amount) as 'non_nulls',
      count(*)-count(invoice_amount) as 'nulls'
from stg_invoices
-- Resultado: 
-- total_rows=6120
-- non_nulls=5820
-- nulls=300
--Identificamos 300 valores nulos.

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
--El rango va desde el 2023-01-01(issue_date) hasta el 2025-05-30(due_date).
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

--9.Conocer la relación de facturas con pagos.
with invoice_temporal 
as (
select invoice_id,count (*) as 'cantidad_pagos'
from stg_payments
group by invoice_id
)
select cantidad_pagos, count(invoice_id) as 'total_facturas'
from invoice_temporal
group by cantidad_pagos
order by cantidad_pagos
--Resultado:
--1 cantidad_pagos = 2063 total_facturas
--2 cantidad_pagos = 780 total_facturas
--3 cantidad_pagos = 232 total_facturas
--4 cantidad_pagos = 50 total_facturas
--5 cantidad_pagos = 11 total_facturas
--6 cantidad_pagos = 1 total_facturas
--Se confirma que cada factura no siempre se cancela en 1 solo pago, existen 1074 facturas que se cancelan en 2, 3 , 4 , 5 y hasta 6 pagos.

--10.Conocer la relacion de pagos con facturas.
SELECT payment_id, COUNT(invoice_id) AS cantidad_facturas_por_pago
FROM stg_payments
GROUP BY payment_id
HAVING COUNT(invoice_id) > 1
ORDER BY cantidad_facturas_por_pago DESC
--Se detecto 80 valores con 2 facturas relacionadas correspondiente a los 80 duplicados ya encontrados. 
--Se confirma que no hay pagos relacionados a varias facturas.
