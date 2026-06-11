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

**Cantidad de registros de pagos relacionados a 1 factura**
```sql
select top 14 invoice_id, count(*) as 'total_veces'
from bz_payments
group by invoice_id
order by count(*) desc
```
| invoice_id | total_veces |
|------------:|------------:|
| 1157 | 6 |
| 1728 | 5 |
| 2138 | 5 |
| 2558 | 5 |
| 320  | 5 |
| 3801 | 5 |
| 3881 | 5 |
| 4240 | 5 |
| 4904 | 5 |
| 5326 | 5 |
| 898  | 5 |
| 949  | 5 |
| 103  | 4 |
| 1079 | 4 |

Se detectó facturas con múltiples registros repetidos. La factura con 1157 de ID se relacionó hasta con 6 registros de pago.

**Cantidad de pagos realizados en un día**
```sql
select top 14 payment_date, count(*) as 'total_pagos_realizados'
from bz_payments
group by payment_date
order by total_pagos_realizados desc
```
| payment_date | total_pagos_realizados |
|---------------|----------------------:|
| 2023-03-23 | 15 |
| 2024-01-20 | 15 |
| 2024-07-18 | 13 |
| 2024-11-08 | 13 |
| 2024-12-21 | 13 |
| 2023-10-17 | 12 |
| 2024-08-02 | 12 |
| 2024-10-09 | 12 |
| 2025-03-17 | 12 |
| 2023-01-16 | 11 |
| 2023-02-18 | 11 |
| 2023-04-22 | 11 |
| 2023-04-24 | 11 |
| 2023-12-07 | 11 |

Se encontró que el 23 de marzo del 2023 y el 20 de enero del 2024 fueron los días con mayor pago, 15 pagos realizados.

**Monto total facturado por proveedor**
```sql
select top 15 supplier_id, 
sum(cast(invoice_amount as numeric(10,2))) as 'monto_total_facturado'
from bz_invoices
group by supplier_id
order by sum(cast(invoice_amount as numeric(10,2))) desc
```
| supplier_id | monto_total_facturado |
|------------:|----------------------:|
| 49  | 649144.65 |
| 103 | 648805.24 |
| 75  | 632216.88 |
| 98  | 628997.01 |
| 105 | 628555.18 |
| 93  | 619405.28 |
| 50  | 614183.70 |
| 53  | 609020.66 |
| 83  | 606928.74 |
| 17  | 604974.11 |
| 32  | 597960.42 |
| 97  | 588065.95 |
| 2   | 587219.83 |
| 18  | 586967.87 |

Se convirtió temporalemente los datos de invoice_amount en números mediante la función CAST, para determinar que el proveedor con ID 49 posee el mayor monto total facturado.

**Cantidad de facturas por departamento**
```sql
select department_id, count(*) as 'cantidad_facturas'
from bz_invoices
group by department_id
order by cantidad_facturas desc
```
| department_id | cantidad_facturas |
|--------------:|------------------:|
| 5  | 644 |
| 7  | 633 |
| 6  | 623 |
| 9  | 616 |
| 2  | 614 |
| 4  | 610 |
| 1  | 604 |
| 3  | 601 |
| 10 | 594 |
| 8  | 581 |

Determinando que el departamento con ID 5 posee la mayor cantidad de facturas emitidas con 644 registros.

**Determinar si el número de factura es valor único**
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

Se detectaron 132 valores con registro doble, sin embargo, ya se habían detectado solo 120 valores duplicados. Existen 12 registros pendientes de revisión. 