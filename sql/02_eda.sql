/* =======================================================================
OBJETIVO:
   - Identificar patrones, valores nulos y anomalías en la capa Bronze.
   - Definir las reglas de limpieza que se aplicarán en la capa Silver.
   ======================================================================= */

USE proyectotesoreria_db;
GO
   
** 1.Presencia de valores nulos:
--En la tabla bz_invoices:    
SELECT COUNT(*) as 'total_filas',
       COUNT (invoice_amount) as 'filas_ok',
       COUNT(*)-COUNT(invoice_amount) as 'nulos'
FROM bz_invoices
  -- total_filas=6120
  -- filas_ok=5820
  -- nulos=300
--Identificamos 300 valores nulos.
   
--En la tabla bz_payments:   
SELECT COUNT(*) AS 'total_filas', 
       COUNT(payment_amount) as 'filas_ok',
       COUNT(*)-COUNT(payment_amount) as 'nulos'
FROM bz_payments
  -- total_filas=4580
  -- filas_ok=4449
  -- nulos=131
--Identificamos 131 valores nulos.

** 2.Presencia de valores duplicados: 
--En la tabla bz_invoices:
SELECT invoice_id, COUNT(*) as 'total_duplicado'
FROM bz_invoices
GROUP BY invoice_id
HAVING COUNT(*) > 1
--Detectamos 120 valores con invoice_id duplicados.120 filas completas repetidas
   
SELECT invoice_number, COUNT(*) as 'total_duplicado'
FROM bz_invoices
GROUP BY invoice_number
HAVING COUNT(*) > 1
--Detectamos 132 valores de invoice_number duplicados.
   
--Aislamos los valores:
SELECT invoice_number FROM bz_invoices
GROUP BY invoice_number
HAVING COUNT( DISTINCT(invoice_id)) > 1
--Nos quedamos con los 12 valores duplicados. Mismo invoice_number, distinta factura y monto.
   

--En la tabla bz_payments:   
SELECT payment_id, COUNT(*)
FROM bz_payments
GROUP BY payment_id
HAVING COUNT(*) > 1   
--Detectamos 80 valores de payment_id duplicados. 80 filas completas repetidas.  

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
-- 0 en los 3.Las fechas tienen formato correcto.
   
** 5.Conocer si hay pagos adelantados (anticipos)
SELECT COUNT(*) AS total_anticipos 
FROM bz_payments p JOIN bz_invoices i 
ON p.invoice_id=i.invoice_id
WHERE p.payment_date<i.issue_date
--Detectamos 2328 de pagos realizados antes de la fecha de emisión de la factura.

** 6.Integridad de referencia entre tablas
SELECT DISTINCT supplier_id 
FROM bz_invoices 
WHERE supplier_id NOT IN (SELECT supplier_id FROM bz_suppliers)
--No hay proveedores ajenos a su tabla de dimensiones en la tabla de bz_invoices.

SELECT COUNT(*) AS pagos_huerfanos
FROM bz_payments
WHERE invoice_id NOT IN (SELECT invoice_id FROM bz_invoices)
--No hay pagos ajenos a su tabla de dimensiones en la tabla de bz_invoices.
   
** 7.Verificar la validez de la columna "status"
select count(*) as casos_inconsistentes
from bz_invoices i left join bz_payments p on i.invoice_id=p.invoice_id
where i.status = 'pagado' and p.payment_id is null
-- Cuando la columna status marca como 'pagado' existen 976 valores con pago nulos, por tanto, la columna 'STATUS'no refleja el estado real de las facturas.

**8. Conciliación de monto pagado y monto factura
with temporal as (
SELECT 
    invoice_id, 
    SUM(CAST(payment_amount AS DECIMAL(8,2))) AS total_pagado
FROM bz_payments
GROUP BY invoice_id ),

resumen_estado as (
select case 
when total_pagado is null then 'sin_pago'
when abs(total_pagado-invoice_amount)<0.1 then 'conciliado'
when total_pagado>invoice_amount then 'sobrepagado'else 'subpagado' end as estado,
count(*) total_pagos
from bz_invoices i left join temporal p on p.invoice_id=i.invoice_id
where invoice_amount is not null
group by (case
when total_pagado is null then 'sin_pago'
when abs(total_pagado-invoice_amount)<0.1 then 'conciliado'
when total_pagado>invoice_amount then 'sobrepagado'else 'subpagado' end) )

select estado, total_pagos,
cast(total_pagos*100.00/sum(total_pagos)over() as decimal(8,2)) as 'porcentaje'
from resumen_estado
group by estado,total_pagos
--El 32.37% está con sobrepago, el 48.61% no tiene pago, el 19.02% tiene subpago y el 0% de las facturas están conciliadas.

**9. Medidas de la diferencia entre lo pagado y el monto de factura
with temporal as (
SELECT invoice_id, 
    SUM(CAST(payment_amount AS DECIMAL(8,2))) AS total_pagado
FROM bz_payments
GROUP BY invoice_id ),

conc as (
select t.total_pagado - i.invoice_amount as 'diferencia'
from bz_invoices i join temporal t on i.invoice_id=t.invoice_id )

select  distinct
PERCENTILE_CONT(0.5) within group (order by diferencia) over() as 'mediana', 
 max(diferencia) over () as 'maxima_diferencia',
 min(diferencia) over() as 'minima_ diferencia',
round(avg(diferencia) over() ,2) as 'diferencia_promedio'
from conc
--Tenemos una mediana de 3162.37, un valor máximo de diferencia de 59175.36 , un valor mínimo de diferencia de -19662.56 y un promedio de diferencia de 4480.63.

