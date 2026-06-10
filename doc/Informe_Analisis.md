# Informe: Análisis seguimiento de pagos y facturas
**Repositorio**:
---
### 1. Diagrama de Flujo de Datos

### 2. Procesamiento y Calidad de Datos 

### 2.1. Matriz de Limpieza y Descartes
Antes de proceder con el análisis, se realizó un proceso exhaustivo de limpieza en la capa **Silver** de la arquitectura Medallion.

| Campo Afectado | Criterio de Error / Inconsistencia | Acción Tomada | Registros Impactados |
| :--- | :--- | :--- | :--- |
| `mcg_id` | IDs Inexistentes (-1, 99999999) | Eliminación de Filas | 3 |
| `product_name` | Valores Inconsistentes (00000000, NULL) | Eliminación de Filas | 3 |
| `ctry_mrch` | Valor Nulo (NA) | Eliminación de Filas | 2 |
| `prch_date` | Formato divergente (DD-MM-YYYY) | Normalización a ISO (/) | 400,000 (~17%) |
| `prch_time` | Separador divergente (HH.MM.SS) | Normalización a ISO (:) | 400,000 (~17%) |

> **Nota Técnica:** Aunque se aplicó la transformación de tipos de datos (CAST) al 100% del dataset para asegurar el esquema, la corrección de formatos mixtos fue necesaria específicamente en el bloque de 400,000 registros con separadores no estándar.

**Resultado:** De la tabla `transactions_staging` se migraron a `transactions` (Prod) únicamente los registros limpios y normalizados (2'400,000 registros).



### 3. Análisis de Resultados

