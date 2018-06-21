set hive.execution.engine=tez;

CREATE DATABASE IF NOT EXISTS ${hivevar:ARIMAX_DB} LOCATION '${hivevar:ARIMAX_DB_DIR}';

create external table if not exists ${hivevar:ARIMAX_DB}.${hivevar:SCORE_OUTPUT_TABLE} (mdse_item_i string, mdse_dept_ref_i string, week_end_date string, predicted string) ROW FORMAT delimited fields terminated by '\t' location '${hivevar:SCORE_OUTPUT_DIR}';

INSERT OVERWRITE TABLE ${hivevar:MODEL_LANDING_TABLE}
PARTITION (forecast_release_date='${hivevar:RELEASE_DATE}',
forecast_granularity=7, model_id=${hivevar:MODELID}, location_type=1)
SELECT
cast(regexp_replace(trim(a.mdse_item_i),'[^0-9]','') as int) as mdse_item_i
, NULL as ecom_item_i
, NULL as tcin
, c.dpci_lbl_t AS dpci
, regexp_replace(trim(a.week_end_date),'[^0-9\-]','') AS forecast_date
, NULL as location
, b.n_stores as store_count
, cast(trim(predicted) as float) AS forecast_q
from ${hivevar:ARIMAX_DB}.${hivevar:SCORE_OUTPUT_TABLE} as a 
INNER JOIN ${hivevar:SALES_FORECAST_TABLE} as b
ON (cast(regexp_replace(trim(a.mdse_item_i),'[^0-9]','') as int)=b.mdse_item_i
AND regexp_replace(trim(a.week_end_date),'[^0-9\-]','')=b.week_end_date)
INNER JOIN (select distinct t2.mdse_item_i, t2.dpci_lbl_t from ${hivevar:MASTER_ITEM_MAPPING_TABLE} t2 where t2.item_type <> 'WEB_ONLY' and t2.new_item = 'N') c
ON cast(regexp_replace(trim(a.mdse_item_i),'[^0-9]','') as int)=c.mdse_item_i
WHERE a.mdse_item_i IS NOT NULL;
