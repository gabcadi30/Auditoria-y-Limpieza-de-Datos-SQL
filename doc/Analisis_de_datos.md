# Pipeline y análisis de datos 

Este El presente documento mostrará el paso a paso del flujo de datos, el proceso de limpieza y calidad, los hallazgos encontrados y la lógica de negocio aplicado en la resolución del repositorio.documento registra paso a paso el flujo de trabajo técnico, las decisiones de arquitectura, los hallazgos de calidad de datos y la lógica de negocio aplicada durante la resolución del desafío.


## Fase Bronce: Ingesta y almacenamiento 

### 1.1. Preparación de la Base de Datos
   La conexión a SQL Server fue mediante un servidor local, usando la autentificación personal de Windows.

**Creación de la base de datos:**

```sql
CREATE DATABASE proyectotesoreria_db
GO;
```

**Creación de tablas:**

Se crea las 5 tablas mediante el comando **DDL**, además, usamos el formato _VARCHAR(MAX)_ para los datos y así  asegurar una ingesta íntegra y sin errores de carga.

```sql
DROP TABLE IF EXISTS bz_invoices;
CREATE TABLE dbo.bz_invoices (
    invoice_id VARCHAR(MAX),
    supplier_id VARCHAR(MAX),
    department_id VARCHAR(MAX),
    invoice_number VARCHAR(MAX),
    issue_date VARCHAR(MAX),
    due_date VARCHAR(MAX),
    invoice_amount VARCHAR(MAX),
    currency VARCHAR(MAX),
    [status] VARCHAR(MAX)  );
```

```sql
DROP TABLE IF EXISTS bz_payments;
CREATE TABLE dbo.bz_payments (
    payment_id VARCHAR(MAX),
    invoice_id VARCHAR(MAX),
    payment_date VARCHAR(MAX),
    payment_amount VARCHAR(MAX),
    method_id VARCHAR(MAX),
    processed_by VARCHAR(MAX) );
```

```sql
DROP TABLE IF EXISTS bz_payment_methods;
CREATE TABLE dbo.bz_payment_methods (
    method_id VARCHAR(MAX),
    method_name VARCHAR(MAX) );
```

```sql
DROP TABLE IF EXISTS bz_departments;
CREATE TABLE dbo.bz_departments (
    department_id VARCHAR(MAX),
    department_name VARCHAR(MAX),
    budget_owner VARCHAR(MAX) );
```

```sql
DROP TABLE IF EXISTS bz_suppliers;
CREATE TABLE dbo.bz_suppliers (
    supplier_id VARCHAR(MAX),
    supplier_name VARCHAR(MAX),
    category VARCHAR(MAX),
    country VARCHAR(MAX),
    rating VARCHAR(MAX) );
```

**Carga de datos:**

La ingesta de datos crudos (archivos CSV) se realizó mediante el asistente de SQL Server "Importa Flat File" a las tablas.


## Fase EDA: Análisis Exploratorio de Datos
Se utiliza esta fase para conocer la data. Encontrar patrones, datos nulos, duplicados y detectar errores si los hubiera.

### 2.1. Determinar el volumen y unicidad de las tablas

```sql
select count(*) as 'total_filas',
      count(distinct invoice_id)as 'facturas_unicas',

from bz_invoices
```

| total_filas  | facturas_unicas|
|--------------|--------------- |
| 6120         |           60000|

Se detecta 120 valores con registros dobles en la tabla bz_invoices.

```sql
select count(*) as 'total_filas',
      count(distinct payment_id)as 'pagos_unicos'
from bz_payments
```
| total_filas  | pagos_unicos |
|--------------|--------------|
| 4580        |           4500|

Se detecta 80 valores con registros dobles en la tabla bz_payments.


### 2.2.Búsqueda de valores nulos

```sql
select top 5 * from bz_invoices
where invoice_amount is null
```
| invoice_id | supplier_id | department_id | invoice_number | issue_date | due_date | invoice_amount | currency | status |
|------------:|-------------:|---------------:|----------------|-------------|-----------|----------------|----------|---------|
| 5   | 111 | 3  | F111-6442 | 2025-03-30 | 2025-04-29 | NULL | USD | Vencido |
| 57  | 77  | 1  | F77-4750  | 2024-03-18 | 2024-05-02 | NULL | PEN | Vencido |
| 90  | 39  | 7  | F39-9071  | 2023-04-30 | 2023-05-30 | NULL | PEN | Pendiente |
| 146 | 66  | 10 | F66-6780  | 2023-09-05 | 2023-10-05 | NULL | PEN | Vencido |
| 172 | 80  | 10 | F80-1744  | 2023-12-12 | 2023-12-27 | NULL | USD | Vencido |

Para determinar la cantidad exacta de valores nulos:

```sql
select count(*) as 'total_nulos'
from bz_invoices
where invoice_amount is null
```
| total_nulos  | 
|--------------|
| 300      |



```sql
select top 5 * from bz_payments
where payment_amount is null
```

 | payment_id | invoice_id | payment_date | payment_amount | method_id | processed_by |
|-------------|------------:|---------------|----------------|-----------:|---------------|
| 163 | 1892 | 2024-08-05 | NULL | 3 | María |
| 168 | 4590 | 2024-09-17 | NULL | 2 | Ana |
| 187 | 2338 | 2023-05-19 | NULL | 3 | Luis |
| 190 | 4881 | 2024-03-31 | NULL | 1 | José |
| 206 | 2782 | 2024-04-27 | NULL | 1 | Ana |


Para determinar la cantidad exacta de valores nulos:

```sql
select count(*) as 'total_nulos'
from bz_payments
where payment_amount is null
```
| total_nulos  | 
|--------------|
| 131          |

------

### 2.3. Búsqueda de duplicados
```sql
select invoice_id, count( invoice_id) as 'facturas'
from bz_invoices
group by invoice_id
having count(invoice_id)>1
```
| invoice_id | facturas |
|------------:|----------:|
| 10   | 2 |
| 1030 | 2 |
| 1062 | 2 |
| 1162 | 2 |
| 117  | 2 |
| 1179 | 2 |
| 1213 | 2 |
| 1218 | 2 |
| 1315 | 2 |
| 1525 | 2 |
| 1556 | 2 |
| 1601 | 2 |
| 1611 | 2 |
| ... | ...

Se hallaron 120 facturas duplicadas, cada una con doble registro asociado.

```sql
select payment_id, count( payment_id) as 'pagos'
from bz_payments
group by payment_id
having count(payment_id)>1
```
| payment_id | pagos |
|------------:|----------:|
| 1020   | 2 |
| 1064 | 2 |
| 1130 | 2 |
| 1185 | 2 |
| 1198 | 2 |
| 1267 | 2 |
| 1483 | 2 |
| 1489 | 2 |
| 1685 | 2 |
| 1711 | 2 |
| 1761 | 2 |
| 1768 | 2 |
| 1847 | 2 |
| ... | ...

Se hallaron 80 pagos duplicados, cada una con doble registro asociados.

### 2.4 Búsqueda de valores anómalos


---
```sql
select invoice_number, count(*) as 'veces_repetido'
from bz_invoices
group by invoice_number
having count(*) > 1
```
| invoice_number | veces_repetido |
|---------------|---------------:|
| F100-7417 | 2 |
| F102-7978 | 2 |
| F103-2902 | 2 |
| F105-2856 | 2 |
| F10-6453  | 2 |
| F107-5225 | 2 |
| F107-6590 | 2 |
| F108-9922 | 2 |
| F109-3534 | 2 |
| F110-6071 | 2 |
| F110-6973 | 2 |
| F113-5937 | 2 |
| ... | ... |

-Se detectaron 132 invoice_number con doble registro, descartando a invoice_number como una 'primary key' de valor único. 

-Ya se encontraba mapeado 120 duplicados exactos en bz_invoices, quedando estos 12 valores con invoice_number duplicado pendiente de revisión.

```sql
SELECT *
FROM bz_invoices
WHERE invoice_number IN (
    SELECT invoice_number
    FROM bz_invoices
    GROUP BY invoice_number
    HAVING COUNT(DISTINCT invoice_id) > 1 )
ORDER BY invoice_number desc
```
| invoice_id | supplier_id | department_id | invoice_number | issue_date | due_date | invoice_amount | currency | status |
|------------:|-------------:|--------------:|----------------|-------------|-----------|---------------:|----------|----------|
| 367  | 8  | 3 | F8-9871  | 2025-02-09 | 2025-02-24 | 1805.58  | USD | Vencido |
| 2657 | 8  | 9 | F8-9871  | 2023-12-08 | 2024-01-22 | 14731.29 | PEN | Pagado |
| 586  | 84 | 1 | F84-6901 | 2023-03-10 | 2023-05-09 | 13241.42 | PEN | Pendiente |
| 5662 | 84 | 8 | F84-6901 | 2023-06-07 | 2023-07-07 | 5203.75  | PEN | Pendiente |
...
| 1911 | 33 | 9 | F33-3907 | 2023-05-08 | 2023-05-23 | 5306.00  | USD | Pagado |
| 1471 | 33 | 3 | F33-3907 | 2024-12-07 | 2025-01-06 | 4643.96  | PEN | Vencido |
| 239  | 1  | 9 | F1-5501  | 2024-07-18 | 2024-09-16 | 335.83   | USD | Pendiente |
| 513  | 1  | 9 | F1-5501  | 2023-02-13 | 2023-04-14 | 7486.81  | USD | Pendiente |
| 1237 | 15 | 1 | F15-3741 | 2023-01-18 | 2023-03-04 | 16723.64 | PEN | Pendiente |
| 4314 | 15 | 8 | F15-3741 | 2024-01-05 | 2024-03-05 |**NULL**   | PEN | Pendiente |
| 3947 | 12 | 3 | F12-6573 | 2023-11-27 | 2023-12-27 | 5542.98  | PEN | Pagado |
| 1561 | 12 | 2 | F12-6573 | 2024-12-29 | 2025-02-27 | 17058.96 | USD | Pagado |

-Se detectaron 24 registros con valores duplicados en invoice_number y supplier_id, pero con diferentes: invoice_id, department_id,issue_date, due_date e invoice_amount. 

-Impidiendo ser eliminados por no ser filas duplicadas exactas.

---
### 2.5. Revisión de formato en Fechas:
Usamos la funcion ISDATE para consultar la calidad de los valores en formato fecha. Nos devuelve valores booleanos siendo 1 para de fechas válidas y 0 si hay fechas inválidas. 
```sql
SELECT issue_date
FROM bz_invoices
WHERE ISDATE(issue_date) = 0
```

```sql
SELECT due_date
FROM bz_invoices
WHERE ISDATE(due_date) = 0
```

```sql
SELECT payment_date
FROM bz_payments
WHERE ISDATE(payment_date) = 0
```
No devuelve resultados en ninguna de las 3 consultas, concluyendo la  presencia de valores válidos en el formato fecha.

---
## Fase Silver: Estandarización y limpieza
Con los resultados encontrados en el Análisis Exploratorio, se procede a crear las tablas silver con datos limpios, excluyendo y eliminando los errores, duplicados y data inconsistente.
### 3.1. Creación de Tablas finales:
Se crean las 5 tablas con los tipos de datos correctos: 
```sql
DROP TABLE IF EXISTS sil_departments
CREATE TABLE sil_departments (
    department_id int,
    department_name varchar(20),
    budget_owner varchar(20) )
```
```sql
DROP TABLE IF EXISTS sil_payment_methods
CREATE TABLE sil_payment_methods (
     method_id int,
     method_name varchar(20) )
```
```sql
DROP TABLE IF EXISTS sil_suppliers
CREATE TABLE sil_suppliers (
    supplier_id int,
    supplier_name varchar(20),
    category varchar(20),
    country varchar(20),
    rating varchar(5) )
```
```sql
DROP TABLE IF EXISTS sil_invoices;
CREATE TABLE sil_invoices (
invoice_id int,
supplier_id int,
department_id int,
invoice_number varchar(12),
issue_date date,
due_date date,
invoice_amount decimal(10,2),
invoice_amount_status varchar (20),
invoice_number_status varchar(20),
currency varchar(3),
status varchar(12) )
```
```sql
DROP TABLE IF EXISTS sil_payments;
CREATE TABLE sil_payments (
  payment_id INT,
  invoice_id INT ,
  payment_date DATE,
  payment_amount NUMERIC(10,2),
  payment_amount_status VARCHAR(20),
  method_id INT,
  processed_by VARCHAR(20) );
```
### 3.2. Transformación y carga de datos:
Se cargan datos sin filas duplicadas, añadimos el campo de "invoice_amount_status" y "payment_amount_status" para señalar los casos donde hayan valores nulos en el monto. Ademas añadimos tambien "invoice_number_status" para señalar los 12 casos de duplicidad encontrados en el análisis EDA.

```sql
INSERT INTO sil_departments (
department_id,
department_name,
budget_owner )

SELECT 
 cast(department_id as int),
 department_name,
 budget_owner
FROM bz_departments
```
```sql
INSERT INTO sil_payment_methods
( method_id,
 method_name)

SELECT 
 cast(method_id as int),
 method_name
FROM bz_payment_methods
```
```sql
INSERT INTO sil_suppliers
( supplier_id,
 supplier_name,
 category,
 country,
 rating)

SELECT 
 cast(supplier_id as int),
 supplier_name,
 category,
 country,
 rating
FROM bz_suppliers
```
```sql
with payment_cte AS 
( SELECT *, row_number() over (partition by 
                              payment_id,
                              invoice_id,
                              payment_date,
                              payment_amount,
                              method_id,
                              processed_by 
                             order by payment_id )
                             AS rn 
   FROM bz_payments)

INSERT INTO sil_payments (
      payment_id,
      invoice_id,
      payment_date,
      payment_amount,
      payment_amount_status,
      method_id,
      processed_by )

SELECT
cast(payment_id as int),
cast(invoice_id as int),
cast (payment_date as date),
cast( payment_amount as numeric),

CASE 
  WHEN payment_amount is null then 'faltante'
  ELSE 'ok'
  END as payment_amount_status,

cast(method_id as int),
processed_by

from payment_cte
where rn=1

```
```sql
WITH invoice_cte AS
( SELECT *,row_number() over ( 
                   PARTITION BY
                    invoice_id,
                    supplier_id,
                    department_id,
                    invoice_number,
                    issue_date,
                    due_date,
                    invoice_amount,
                    currency,
                    status
                  ORDER BY invoice_id
           ) AS rn
    FROM bz_invoices )

INSERT INTO sil_invoices (
    invoice_id,
    supplier_id,
    department_id,
    invoice_number,
    issue_date,
    due_date,
    invoice_amount,
    invoice_amount_status,
    invoice_number_status,
    currency,
    status )

SELECT
    CAST(invoice_id AS INT),
    CAST(supplier_id AS INT),
    CAST(department_id AS INT),
    invoice_number,
    CAST(issue_date AS DATE),
    CAST(due_date AS DATE),
    CAST(invoice_amount AS DECIMAL(10,2)),

    CASE
        WHEN invoice_amount IS NULL THEN 'faltante'
        ELSE 'ok'
    END AS invoice_amount_status,

    CASE
        WHEN invoice_number IN
          ( SELECT invoice_number
            FROM invoice_cte
            WHERE rn = 1
            GROUP BY invoice_number
            HAVING COUNT(*) > 1 )
        THEN 'duplicado'
        ELSE 'ok'
    END AS invoice_number_status,

    currency,
    status

FROM invoice_cte
WHERE rn = 1;
```
### 3.3.Validación de Post-Carga:
```sql
select count(*) as total_limpio 
from sil_payments
```
| total_limpio  | 
|--------------|
| 4500      |

```sql
select count(*) as total_limpio 
from sil_invoices
```
| total_limpio  | 
|--------------|
| 6000      |

## Fase Gold: Análisis de Negocio 
Ejecutamos consultas que responda las principales pregunta del caso a resolver.
### 4.1. ¿Qué porcentaje de facturas se pagan fuera del plazo?
Unimos la tabla de invoices con payment para encontrar las facturas pagadas mediante un JOIN.
```sql
select TOP 10 i.invoice_id,i.due_date, i.issue_date,p.payment_date
from sil_invoices i left join sil_payments p 
on i.invoice_id=p.invoice_id
```
| invoice_id | due_date | issue_date | payment_date |
|-----------:|-----------|------------|--------------|
| 5568 | 2023-06-03 | 2023-04-04 | 2024-07-10 |
| 4070 | 2024-05-16 | 2024-03-17 | NULL |
| 3177 | 2025-03-01 | 2025-01-30 | NULL |
| 5177 | 2024-05-20 | 2024-03-21 | 2024-07-03 |
| 5177 | 2024-05-20 | 2024-03-21 | 2023-06-30 |
| 283  | 2024-10-01 | 2024-08-02 | NULL |
| 5725 | 2024-09-04 | 2024-07-06 | 2024-05-04 |
| 5725 | 2024-09-04 | 2024-07-06 | 2025-02-12 |
| 5725 | 2024-09-04 | 2024-07-06 | 2024-07-28 |
| 138  | 2024-07-28 | 2024-05-29 | 2024-06-25 |

Luego creamos una columna condicional mediante CASE WHEN para etiquetar las facturas como: anticipado, a tiempo, pendiente, con retraso. Tambien añadimos la etiqueta "otros" para etiquetar los valores por defecto.
```sql
with facturas_total as (
select p.payment_date,i.invoice_id,i.due_date, i.issue_date
from sil_invoices i left join sil_payments p 
on i.invoice_id=p.invoice_id ),

estatus_por_factura as (
 select invoice_id,payment_date,issue_date, due_date,
  case
    when issue_date>payment_date then 'anticipado'
    when issue_date<=payment_date and payment_date<=due_date then 'a tiempo'
    when payment_date> due_date then 'con retraso'
    when payment_date is null then 'pendiente'
    else 'otro'
  end as estatus_pago
 from facturas_total )

 select top 15 * from estatus_por_factura
```
| invoice_id | payment_date | issue_date | due_date | estatus_pago |
|-----------:|--------------|------------|-----------|--------------|
| 5568 | 2024-07-10 | 2023-04-04 | 2023-06-03 | con retraso |
| 4070 | NULL | 2024-03-17 | 2024-05-16 | pendiente |
| 3177 | NULL | 2025-01-30 | 2025-03-01 | pendiente |
| 5177 | 2024-07-03 | 2024-03-21 | 2024-05-20 | con retraso |
| 5177 | 2023-06-30 | 2024-03-21 | 2024-05-20 | anticipado |
| 283 | NULL | 2024-08-02 | 2024-10-01 | pendiente |
| 5725 | 2024-05-04 | 2024-07-06 | 2024-09-04 | anticipado |
| 5725 | 2025-02-12 | 2024-07-06 | 2024-09-04 | con retraso |
| 5725 | 2024-07-28 | 2024-07-06 | 2024-09-04 | a tiempo |
| 138 | 2024-06-25 | 2024-05-29 | 2024-07-28 | a tiempo |
| 1154 | 2024-10-01 | 2023-09-02 | 2023-10-02 | con retraso |
| 1154 | 2024-04-11 | 2023-09-02 | 2023-10-02 | con retraso |
| 5122 | 2024-08-11 | 2023-12-12 | 2024-01-26 | con retraso |
| 5105 | 2023-08-09 | 2023-09-13 | 2023-10-13 | anticipado |
| 5105 | 2024-12-09 | 2023-09-13 | 2023-10-13 | con retraso |

Sin embargo detectamos que hay invoices_id de facturas que se repiten y esto es porque existe facturas que se cancelan en partes, haciendo que una misma factura se duplique en base a los pagos asociados a ella, dando una informacion erronea al análisis.
```sql
select top 15   invoice_id, count(*) as 'numero_de_pagos'
from sil_payments
group by invoice_id
having count(*)>1
order by numero_de_pagos desc
```
| invoice_id | numero_de_pagos |
|-----------:|-----------------:|
| 1157 | 6 |
| 4904 | 5 |
| 949  | 5 |
| 898  | 5 |
| 1728 | 5 |
| 5326 | 5 |
| 2558 | 5 |
| 320  | 5 |
| 3881 | 5 |
| 2138 | 5 |
| 3801 | 5 |
| 3458 | 4 |
| 4168 | 4 |
| 4002 | 4 |
| 5745 | 4 |

Para solucionar ello creamos una CTE temporal llamada "ultimo_pago" que agrupará por invoice_id y solo considerará la última fecha de pago de cada factura, entonces si una factura tiene 6 pagos asociados, solo contará el último que se hizo para cancelar el total de la factura. Esta CTE será el reemplazo de la tabla sil_payments en el JOIN para el cruce de la tabla factura y pagos.

```sql
with ultimo_pago AS (
SELECT
    invoice_id,
    MAX(payment_date) AS fecha_ultimo_pago
FROM sil_payments
GROUP BY invoice_id ),

facturas_total as (
select p.fecha_ultimo_pago,i.invoice_id,i.due_date, i.issue_date, i.status
from sil_invoices i left join ultimo_pago p 
on i.invoice_id=p.invoice_id ),

estatus_por_factura as (
 select invoice_id,status, fecha_ultimo_pago,issue_date, due_date,
  case
    when issue_date>fecha_ultimo_pago then 'anticipada'
    when issue_date<=fecha_ultimo_pago and fecha_ultimo_pago<=due_date then 'a tiempo'
    when fecha_ultimo_pago> due_date then 'con retraso'
    when fecha_ultimo_pago is null then 'pendiente'
    else 'otro'
  end as estado_factura
 from facturas_total )

 select top 15 * from estatus_por_factura
```

| invoice_id | status | fecha_ultimo_pago | issue_date | due_date | estado_factura |
|-----------:|---------|-------------------|------------|-----------|----------------|
| 5568 | Pendiente | 2024-07-10 | 2023-04-04 | 2023-06-03 | con retraso |
| 4070 | Pagado | NULL | 2024-03-17 | 2024-05-16 | pendiente |
| 3177 | Vencido | NULL | 2025-01-30 | 2025-03-01 | pendiente |
| 5177 | Vencido | 2024-07-03 | 2024-03-21 | 2024-05-20 | con retraso |
| 283 | Vencido | NULL | 2024-08-02 | 2024-10-01 | pendiente |
| 5725 | Pendiente | 2025-02-12 | 2024-07-06 | 2024-09-04 | con retraso |
| 138 | Pendiente | 2024-06-25 | 2024-05-29 | 2024-07-28 | a tiempo |
| 1154 | Pendiente | 2024-10-01 | 2023-09-02 | 2023-10-02 | con retraso |
| 5122 | Pagado | 2024-08-11 | 2023-12-12 | 2024-01-26 | con retraso |
| 5105 | Pagado | 2024-12-09 | 2023-09-13 | 2023-10-13 | con retraso |
| 5421 | Vencido | NULL | 2023-04-16 | 2023-05-01 | pendiente |
| 4301 | Vencido | 2024-04-28 | 2024-05-17 | 2024-07-16 | anticipada |
| 756 | Vencido | NULL | 2024-02-26 | 2024-04-11 | pendiente |
| 4778 | Vencido | NULL | 2024-11-13 | 2024-12-13 | pendiente |
| 5972 | Pendiente | 2023-04-01 | 2024-03-08 | 2024-03-23 | anticipada |

Con la informacion correcta lista, buscamos informacion solicitada. Para ello contamos y agrupamos las facturas según la CTE temporal "estado_factura", para calcular el total de facturas y que ejecute la division en cada linea agregamos una windows functions de suma.
```sql
with ultimo_pago AS (
SELECT
    invoice_id,
    MAX(payment_date) AS fecha_ultimo_pago
FROM sil_payments
GROUP BY invoice_id ),

facturas_total as (
select p.fecha_ultimo_pago,i.invoice_id,i.due_date, i.issue_date, i.status
from sil_invoices i left join ultimo_pago p 
on i.invoice_id=p.invoice_id ),

estatus_por_factura as (
 select invoice_id,status, fecha_ultimo_pago,issue_date, due_date,
  case
    when issue_date>fecha_ultimo_pago then 'anticipada'
    when issue_date<=fecha_ultimo_pago and fecha_ultimo_pago<=due_date then 'a tiempo'
    when fecha_ultimo_pago> due_date then 'con retraso'
    when fecha_ultimo_pago is null then 'pendiente'
    else 'otro'
  end as estado_factura
 from facturas_total )

 SELECT 
    estado_factura,
    COUNT(*) as total_facturas,
     cast(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()  as decimal(5,2)) AS porcentaje
 FROM estatus_por_factura
GROUP BY estado_factura
```
* Para que el resultado esté en decimales de 2 digitos, usamos un CAST a DECIMAL(5,2).

| estado_factura | total_facturas | porcentaje (%) |
|----------------|---------------:|---------------:|
| a tiempo | 145 | 2.42 |
| pendiente | 2863 | 47.72 |
| con retraso | 1607 | 26.78 |
| anticipada | 1385 | 23.08 |

### 4.2. ¿Cuál es el retraso promedio en días de los pagos?

* Si bien la pregunta solo considera a las facturas con retraso, sin embargo sabemos que tambien tenemos facturas pagadas anticipadamente y sobretodo facturas que todavía no han sido cancelas. Por ello, enfocaremos el promedio de días en base al estado de cada factura.

Iniciamos usando la CTE "estatus_por_factura" que creamos en la pregunta 1 , y le agregamos una nueva clausula condicional mediante CASE WHEN para calcular los dias de retraso en base al estado de cada factura.
```sql
with ultimo_pago AS (
SELECT
    invoice_id,
    MAX(payment_date) AS fecha_ultimo_pago
FROM sil_payments
GROUP BY invoice_id ),

facturas_total as (
select p.fecha_ultimo_pago,i.invoice_id,i.due_date, i.issue_date, i.status
from sil_invoices i left join ultimo_pago p 
on i.invoice_id=p.invoice_id ),

estatus_por_factura as (
 select invoice_id,status, fecha_ultimo_pago,issue_date, due_date,
  case
    when issue_date>fecha_ultimo_pago then 'anticipada'
    when issue_date<=fecha_ultimo_pago and fecha_ultimo_pago<=due_date then 'a tiempo'
    when fecha_ultimo_pago> due_date then 'con retraso'
    when fecha_ultimo_pago is null then 'pendiente'
    else 'otro'
  end as estado_factura
 from facturas_total ),

 facturas_fuera_fecha as (
 SELECT *,
 case
  when estado_factura ='anticipada' then DATEDIFF(day,fecha_ultimo_pago,issue_date)
  when estado_factura ='a tiempo' then 0
  when estado_factura ='con retraso' then DATEDIFF(day, due_date,fecha_ultimo_pago)
  when estado_factura = 'pendiente' then DATEDIFF(day,due_date,'2025-05-31' )
  else NULL 
  end as dias_fuera_de_fecha
 from estatus_por_factura)

 select top 15 * from facturas_fuera_fecha
 ```
 * Para las facturas sin pago registrado (payment_date IS NULL), los días de atraso se calcularon tomando como referencia la fecha de corte 2025-05-31, correspondiente al último período del conjunto de datos.

| invoice_id | status | fecha_ultimo_pago | issue_date | due_date | estado_factura | dias_fuera_de_fecha |
|-----------:|---------|-------------------|------------|-----------|----------------|--------------------:|
| 5568 | Pendiente | 2024-07-10 | 2023-04-04 | 2023-06-03 | con retraso | 403 |
| 4070 | Pagado | NULL | 2024-03-17 | 2024-05-16 | pendiente | 380 |
| 3177 | Vencido | NULL | 2025-01-30 | 2025-03-01 | pendiente | 91 |
| 5177 | Vencido | 2024-07-03 | 2024-03-21 | 2024-05-20 | con retraso | 44 |
| 283 | Vencido | NULL | 2024-08-02 | 2024-10-01 | pendiente | 242 |
| 5725 | Pendiente | 2025-02-12 | 2024-07-06 | 2024-09-04 | con retraso | 161 |
| 138 | Pendiente | 2024-06-25 | 2024-05-29 | 2024-07-28 | a tiempo | 0 |
| 1154 | Pendiente | 2024-10-01 | 2023-09-02 | 2023-10-02 | con retraso | 365 |
| 5122 | Pagado | 2024-08-11 | 2023-12-12 | 2024-01-26 | con retraso | 198 |
| 5105 | Pagado | 2024-12-09 | 2023-09-13 | 2023-10-13 | con retraso | 423 |
| 5421 | Vencido | NULL | 2023-04-16 | 2023-05-01 | pendiente | 761 |
| 4301 | Vencido | 2024-04-28 | 2024-05-17 | 2024-07-16 | anticipada | 19 |
| 756 | Vencido | NULL | 2024-02-26 | 2024-04-11 | pendiente | 415 |
| 4778 | Vencido | NULL | 2024-11-13 | 2024-12-13 | pendiente | 169 |
| 5972 | Pendiente | 2023-04-01 | 2024-03-08 | 2024-03-23 | anticipada | 342 |

Finalmente, calculamos el promedio de los dias (AVG) y agrupamos por el estado de la factura (group by).

```sql
with ultimo_pago AS (
SELECT
    invoice_id,
    MAX(payment_date) AS fecha_ultimo_pago
FROM sil_payments
GROUP BY invoice_id ),

facturas_total as (
select p.fecha_ultimo_pago,i.invoice_id,i.due_date, i.issue_date, i.status
from sil_invoices i left join ultimo_pago p 
on i.invoice_id=p.invoice_id ),

estatus_por_factura as (
 select invoice_id,status, fecha_ultimo_pago,issue_date, due_date,
  case
    when issue_date>fecha_ultimo_pago then 'anticipada'
    when issue_date<=fecha_ultimo_pago and fecha_ultimo_pago<=due_date then 'a tiempo'
    when fecha_ultimo_pago> due_date then 'con retraso'
    when fecha_ultimo_pago is null then 'pendiente'
    else 'otro'
  end as estado_factura
 from facturas_total ),

 facturas_fuera_fecha as (
 SELECT *,
 case
  when estado_factura ='anticipada' then DATEDIFF(day,fecha_ultimo_pago,issue_date)
  when estado_factura ='a tiempo' then 0
  when estado_factura ='con retraso' then DATEDIFF(day, due_date,fecha_ultimo_pago)
  when estado_factura = 'pendiente' then DATEDIFF(day,due_date,'2025-05-31' )
  else NULL
  end as dias_fuera_de_fecha
 from estatus_por_factura
)

select count(invoice_id)as cantidad_facturas, estado_factura, avg(dias_fuera_de_fecha)as promedio_dias
from facturas_fuera_fecha
group by estado_factura
```

| cantidad_facturas | estado_factura | promedio_dias |
|------------------:|----------------|--------------:|
| 145  | a tiempo      | 0   |
| 2863 | pendiente     | 441 |
| 1607 | con retraso   | 293 |
| 1385 | anticipada    | 265 |

### 4.3. ¿Qué proveedores concentran el mayor número de facturas vencidas?
* Se entiende como facturas vencidas a las que tienen pendiente el pago, es decir, facturas "pendiente" según nuestra columna de estado_factura.

Para conocer a los proveedores con más facturas pendientes, hacemos un JOIN a la tabla sil_invoices con sil_supplier, trayendo las columnas de supplier_name,category y country.Todo se guarda en otra CTE temporal de nombre "suppliers_invoices".
```sql
with suppliers_invoices as (
select top 15 i.invoice_id,i.status,i.due_date,i.issue_date,i.invoice_amount,i.currency,s.supplier_name,s.category,s.country
from sil_invoices i left join sil_suppliers s 
on i.supplier_id=s.supplier_id  
)
select * from suppliers_invoices
```
| invoice_id | status | due_date | issue_date | invoice_amount | currency | supplier_name | category | country |
|-----------:|--------|-----------|------------|---------------:|----------|---------------|----------|---------|
| 5568 | Pendiente | 2023-06-03 | 2023-04-04 | 2601.53 | USD | Proveedor_100 | Logística | México |
| 4070 | Pagado | 2024-05-16 | 2024-03-17 | 5343.80 | USD | Proveedor_100 | Logística | México |
| 3177 | Vencido | 2025-03-01 | 2025-01-30 | 11253.18 | PEN | Proveedor_100 | Logística | México |
| 5177 | Vencido | 2024-05-20 | 2024-03-21 | 8631.95 | USD | Proveedor_100 | Logística | México |
| 283 | Vencido | 2024-10-01 | 2024-08-02 | 11039.55 | USD | Proveedor_100 | Logística | México |
| 5725 | Pendiente | 2024-09-04 | 2024-07-06 | 2385.68 | PEN | Proveedor_100 | Logística | México |
| 138 | Pendiente | 2024-07-28 | 2024-05-29 | 19328.74 | USD | Proveedor_100 | Logística | México |
| 1154 | Pendiente | 2023-10-02 | 2023-09-02 | 19940.49 | USD | Proveedor_100 | Logística | México |
| 5122 | Pagado | 2024-01-26 | 2023-12-12 | 17608.22 | USD | Proveedor_100 | Logística | México |
| 5105 | Pagado | 2023-10-13 | 2023-09-13 | 9182.18 | USD | Proveedor_100 | Logística | México |
| 5421 | Vencido | 2023-05-01 | 2023-04-16 | 7339.20 | USD | Proveedor_100 | Logística | México |
| 4301 | Vencido | 2024-07-16 | 2024-05-17 | 15912.33 | USD | Proveedor_100 | Logística | México |
| 756 | Vencido | 2024-04-11 | 2024-02-26 | 18426.06 | PEN | Proveedor_100 | Logística | México |
| 4778 | Vencido | 2024-12-13 | 2024-11-13 | 5623.70 | PEN | Proveedor_100 | Logística | México |
| 5972 | Pendiente | 2024-03-23 | 2024-03-08 | 10978.26 | USD | Proveedor_100 | Logística | México |

Luego cruzamos esta tabla temporal supplier_invoices con la tabla temporal ultimo_pago antes creada en un LEFT JOIN. A la columna creada "estado_factura" le agregamos un nuevo CASE con el tipo de cambio de dolar a 3.5 para **estandarizar** el monto total de cada factura pendiente según la columna CURRENCY, que puede ser en soles o dolares. Todo ello lo guardamos en una nueva CTE temporal llamada "estado_factura_supplier"
```sql
with suppliers_invoices as (
select i.invoice_id,i.due_date,i.issue_date,i.currency,i.invoice_amount,i.status,s.supplier_name,s.category,s.country
from sil_invoices i left join sil_suppliers s 
on i.supplier_id=s.supplier_id  
),

ultimo_pago AS (
SELECT
    invoice_id,
    MAX(payment_date) AS fecha_ultimo_pago
FROM sil_payments
GROUP BY invoice_id ),

facturas_total as (
select p.fecha_ultimo_pago,i.invoice_id,i.due_date, i.issue_date, i.status,i.currency, i.supplier_name,i.invoice_amount,i.category,i.country
from suppliers_invoices i left join ultimo_pago p 
on i.invoice_id=p.invoice_id ),

estado_factura_supplier as (
 select invoice_id,status,invoice_amount,supplier_name,category,country,currency,
  case
    when issue_date>fecha_ultimo_pago then 'anticipada'
    when issue_date<=fecha_ultimo_pago and fecha_ultimo_pago<=due_date then 'a tiempo'
    when fecha_ultimo_pago> due_date then 'con retraso'
    when fecha_ultimo_pago is null then 'pendiente'
    else 'otro'
  end as estado_factura,
  case
    when currency = 'USD' THEN invoice_amount*(3.5)
    else invoice_amount
    end as invoice_amount_convert
 from facturas_total )

select top 15 * from estado_factura_supplier
```
| invoice_id | status | invoice_amount | supplier_name | category | country | currency | estado_factura | invoice_amount_convert |
|-----------:|--------|---------------:|---------------|----------|---------|----------|----------------|------------------------:|
| 5568 | Pendiente | 2601.53 | Proveedor_100 | Logística | México | USD | con retraso | 9105.355 |
| 4070 | Pagado | 5343.80 | Proveedor_100 | Logística | México | USD | pendiente | 18703.300 |
| 3177 | Vencido | 11253.18 | Proveedor_100 | Logística | México | PEN | pendiente | 11253.180 |
| 5177 | Vencido | 8631.95 | Proveedor_100 | Logística | México | USD | con retraso | 30211.825 |
| 283 | Vencido | 11039.55 | Proveedor_100 | Logística | México | USD | pendiente | 38638.425 |
| 5725 | Pendiente | 2385.68 | Proveedor_100 | Logística | México | PEN | con retraso | 2385.680 |
| 138 | Pendiente | 19328.74 | Proveedor_100 | Logística | México | USD | a tiempo | 67650.590 |
| 1154 | Pendiente | 19940.49 | Proveedor_100 | Logística | México | USD | con retraso | 69791.715 |
| 5122 | Pagado | 17608.22 | Proveedor_100 | Logística | México | USD | con retraso | 61628.770 |
| 5105 | Pagado | 9182.18 | Proveedor_100 | Logística | México | USD | con retraso | 32137.630 |
| 5421 | Vencido | 7339.20 | Proveedor_100 | Logística | México | USD | pendiente | 25687.200 |
| 4301 | Vencido | 15912.33 | Proveedor_100 | Logística | México | USD | anticipada | 55693.155 |
| 756 | Vencido | 18426.06 | Proveedor_100 | Logística | México | PEN | pendiente | 18426.060 |
| 4778 | Vencido | 5623.70 | Proveedor_100 | Logística | México | PEN | pendiente | 5623.700 |
| 5972 | Pendiente | 10978.26 | Proveedor_100 | Logística | México | USD | anticipada | 38423.910 |

Finalmente creamos la querie que nos dara el top 15 de proveedores con mayor cantidad de facturas pendientes ordenado de mayor a menor por la cantidad_facturas.

```sql
with suppliers_invoices as (
select i.invoice_id,i.due_date,i.issue_date,i.currency,i.invoice_amount,i.status,s.supplier_name,s.category,s.country
from sil_invoices i left join sil_suppliers s 
on i.supplier_id=s.supplier_id  
),

ultimo_pago AS (
SELECT
    invoice_id,
    MAX(payment_date) AS fecha_ultimo_pago
FROM sil_payments
GROUP BY invoice_id ),

facturas_total as (
select p.fecha_ultimo_pago,i.invoice_id,i.due_date, i.issue_date, i.status,i.currency, i.supplier_name,i.invoice_amount,i.category,i.country
from suppliers_invoices i left join ultimo_pago p 
on i.invoice_id=p.invoice_id ),

estado_factura_supplier as (
 select invoice_id,status,invoice_amount,supplier_name,category,country,currency,
  case
    when issue_date>fecha_ultimo_pago then 'anticipada'
    when issue_date<=fecha_ultimo_pago and fecha_ultimo_pago<=due_date then 'a tiempo'
    when fecha_ultimo_pago> due_date then 'con retraso'
    when fecha_ultimo_pago is null then 'pendiente'
    else 'otro'
  end as estado_factura,
  case
    when currency = 'USD' THEN invoice_amount*(3.5)
    else invoice_amount
    end as invoice_amount_convert
 from facturas_total )

 select top 15 supplier_name, count(invoice_id)cantidad_facturas, sum(invoice_amount_convert)monto_total, category, country
 from estado_factura_supplier
 where estado_factura='pendiente'
 group by supplier_name,category, country
 order by cantidad_facturas desc
```
| supplier_name | cantidad_facturas | monto_total | category | country |
|---------------|------------------:|------------:|----------|---------|
| Proveedor_49  | 39 | 886150.590 | Tecnología | Chile |
| Proveedor_110 | 35 | 639481.425 | Tecnología | Chile |
| Proveedor_119 | 34 | 704010.390 | Tecnología | México |
| Proveedor_50  | 34 | 836853.890 | Tecnología | Chile |
| Proveedor_17  | 33 | 711473.255 | Insumos | Colombia |
| Proveedor_57  | 31 | 631536.670 | Mantenimiento | Chile |
| Proveedor_2   | 30 | 570720.305 | Tecnología | Chile |
| Proveedor_32  | 30 | 586046.550 | Servicios | México |
| Proveedor_39  | 30 | 557947.760 | Logística | Perú |
| Proveedor_43  | 30 | 612381.740 | Tecnología | Perú |
| Proveedor_68  | 30 | 644425.470 | Logística | Colombia |
| Proveedor_75  | 30 | 671401.135 | Servicios | México |
| Proveedor_83  | 30 | 440430.675 | Insumos | Perú |
| Proveedor_101 | 29 | 661876.800 | Insumos | Colombia |
| Proveedor_115 | 29 | 773614.730 | Logística | Perú |

Si lo ordenamos por monto_total cambia las posiciones de los proveedores: 

| supplier_name | cantidad_facturas | monto_total | category | country |
|---------------|------------------:|------------:|----------|---------|
| Proveedor_49  | 39 | 886150.590 | Tecnología | Chile |
| Proveedor_50  | 34 | 836853.890 | Tecnología | Chile |
| Proveedor_115 | 29 | 773614.730 | Logística | Perú |
| Proveedor_5   | 22 | 771192.735 | Servicios | Perú |
| Proveedor_98  | 28 | 756414.305 | Insumos | Chile |
| Proveedor_74  | 28 | 742707.330 | Servicios | Colombia |
| Proveedor_91  | 28 | 738725.560 | Logística | Perú |
| Proveedor_17  | 33 | 711473.255 | Insumos | Colombia |
| Proveedor_119 | 34 | 704010.390 | Tecnología | México |
| Proveedor_99  | 24 | 691424.700 | Insumos | Perú |
| Proveedor_75  | 30 | 671401.135 | Servicios | México |
| Proveedor_103 | 27 | 669093.980 | Tecnología | México |
| Proveedor_114 | 27 | 668504.835 | Logística | Chile |
| Proveedor_12  | 28 | 665081.010 | Tecnología | Perú |
| Proveedor_21  | 29 | 664893.115 | Tecnología | México |

