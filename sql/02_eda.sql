/* =======================================================================
OBJETIVO:
   - Identificar patrones, valores nulos y anomalías en la capa Bronze.
   - Definir las reglas de limpieza que se aplicarán en la capa Silver.
   ======================================================================= */

USE proyectotesoreria_db;
GO
** 1. Volumen y presencia de valores duplicados:   
--En la tabla bz_invoices:
SELECT COUNT(*) as 'total_filas',
      COUNT(distinct invoice_id)as'facturas_unicas'
FROM bz_invoices
  -- total_filas=6120
  -- facturas_unicas=6000

--En la tabla bz_payments:
SELECT COUNT(*) as 'total_filas',
      COUNT(distinct payment_id)as 'pagos_unicos'
FROM bz_payments
  -- total_filas=4580
  -- pagos_unicos=4500

** 2.Determinar presencia de valores nulos:
--En la tabla bz_invoices:    
SELECT COUNT(*) as 'total_rows',
       COUNT (invoice_amount) as 'non_nulls',
       COUNT(*)-COUNT(invoice_amount) as 'nulls'
FROM bz_invoices
  -- total_rows=6120
  -- non_nulls=5820
  -- nulls=300
--Identificamos 300 valores nulos.
   
--En la tabla bz_payments:   
SELECT COUNT(*) AS 'total_rows', 
       COUNT(payment_amount) as 'non_nulls',
       COUNT(*)-COUNT(payment_amount) as 'nulls'
FROM bz_payments
  -- total_rows=4580
  -- non_nulls=4449
  -- nulls=131
--Identificamos 131 valores nulos.

** 3.Conocer los valores duplicados: 
--En la tabla bz_invoices:
SELECT invoice_id, COUNT(*)
FROM bz_invoices
GROUP BY invoice_id
HAVING COUNT(*) > 1
--Detectamos 120 valores de invoice_id duplicados.
   
SELECT invoice_number, COUNT(*) as 'veces_repetido'
FROM bz_invoices
GROUP BY invoice_number
HAVING COUNT(*) > 1
--Detectamos 132 valores de invoice_number duplicados. 

--En la tabla bz_payments:   
SELECT payment_id, COUNT(*)
FROM bz_payments
GROUP BY payment_id
HAVING COUNT(*) > 1   
--Detectamos 80 valores de payment_id duplicados.  

** 4. Revisión del formato en Fechas
--En la tabla bz_invoices:
SELECT issue_date
FROM bz_invoices
WHERE ISDATE(issue_date)=0

SELECT due_date
FROM bz_invoices
WHERE ISDATE(due_date)=0

--En la tabla bz_payments: 
SELECT payment_date
FROM bz_payments
WHERE ISDATE(payment_date)=0
--Todas las fechas tienen formato correcto (DATE).

** 5.Conocer el rango de fechas.
select max(cast(payment_date as date)) AS 'max_date',
       min (cast (payment_date as date)) as 'min_date'
from bz_payments

select max(cast(issue_date as date)) AS 'max_date',
       min (cast (issue_date as date)) as 'min_date'
from bz_invoices

select max(cast(due_date as date)) AS 'max_date',
       min (cast (due_date as date)) as 'min_date'
from bz_invoices
--El rango va desde el 2023-01-01(issue_date) hasta el 2025-05-30(due_date).
--No presentan datos absurdos, ni nulos, ni outliers.

** 6.Verificar si existen proveedores en facturas que no esten en su tabla de proveedores.
SELECT DISTINCT supplier_id 
FROM bz_invoices 
WHERE supplier_id NOT IN (SELECT supplier_id FROM bz_suppliers)
--No existe ningún proveedor en la tabla Invoices ajeno a la tabla stg_suppliers.

** 7.Conocer si hay pagos adelantados (anticipos)
select invoice_id,due_date,issue_date
from bz_invoices
where cast(due_date as date)< cast (issue_date as date)
--Detectamos que hay 2328 pagos realizados antes de la fecha de emision de la factura.

** 8.Conocer la relación de facturas con pagos.
with invoice_temporal 
as (
select invoice_id,count (*) as 'cantidad_pagos'
from bz_payments
group by invoice_id
)
select cantidad_pagos, count(invoice_id) as 'total_facturas'
from invoice_temporal
group by cantidad_pagos
order by cantidad_pagos
  --1 cantidad_pagos = 2063 total_facturas
  --2 cantidad_pagos = 780 total_facturas
  --3 cantidad_pagos = 232 total_facturas
  --4 cantidad_pagos = 50 total_facturas
  --5 cantidad_pagos = 11 total_facturas
  --6 cantidad_pagos = 1 total_facturas
--Se confirma que cada factura no siempre se cancela en 1 solo pago, existen 1074 facturas que se cancelan en 2, 3 , 4 , 5 y hasta 6 pagos.


