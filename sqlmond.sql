/*
This script shows the SQL Monitor details for a given SQL while it's running
It shows the steps that had changes in stats for the last minute

Created by Eduardo Claro on 2021-08-03
Last changes on 2021-08-04

Parameter 1: SQL_ID
Parameter 2: PLAN_HASH_VALUE
Parameter 3: SQL_EXEC_ID (optional)
*/

col OBJECT for a40
col OPOP for a50
col OPOB for a80 head "OPERATION + OPTIONS + OBJECT"

compute sum of STARTS on report
compute min max of LINE_ID on report
compute sum of OUT_ROWS on report
break on report

WITH q as (
	select KEY
	from gv$sql_monitor
	where sql_id='&1' and SQL_PLAN_HASH_VALUE=&2
	and (SQL_EXEC_ID = '&3' or '&3' is null)
	and rownum=1
)
select 
--	CON_ID                     ,
--	KEY                        ,
--	STATUS                     ,
--	to_char(FIRST_REFRESH_TIME,'YY-MM-DD hh24:mi:ss') as FIRST_REF_TIME,
--	to_char(LAST_REFRESH_TIME,'YY-MM-DD hh24:mi:ss') as LAST_REF_TIME,
	to_char(FIRST_CHANGE_TIME,'YY-MM-DD hh24:mi:ss') as FIRST_CHG_TIME,
	to_char(LAST_CHANGE_TIME,'YY-MM-DD hh24:mi:ss') as LAST_CHG_TIME,
--	REFRESH_COUNT              as REF_CNT,
--	SID                        ,
--	PROCESS_NAME               ,
--	SQL_ID                     ,
--	SQL_EXEC_START             ,
--	SQL_EXEC_ID                ,
--	SQL_PLAN_HASH_VALUE        ,
--	SQL_CHILD_ADDRESS          ,
--	PLAN_PARENT_ID             ,
	PLAN_LINE_ID               as LINE_ID,
	STARTS                     ,
	OUTPUT_ROWS                OUT_ROWS,
	lpad(' ',PLAN_DEPTH,' ') || PLAN_OPERATION || ' ' || PLAN_OPTIONS || ' ' || 
		case when PLAN_OBJECT_OWNER is NULL then '' else PLAN_OBJECT_OWNER || '.' end || PLAN_OBJECT_NAME as OPOB,
	PLAN_COST                  as COST,
	PLAN_CARDINALITY           as CARD,
	PLAN_BYTES                 as BYTES,
	PLAN_DEPTH                 as DEPTH,
	PLAN_POSITION              as POS,
--	PLAN_TIME                  ,
--	PLAN_PARTITION_START       ,
--	PLAN_PARTITION_STOP        ,
--	PLAN_CPU_COST              ,
--	PLAN_IO_COST               ,
--	PLAN_TEMP_SPACE            ,
--	IO_INTERCONNECT_BYTES      ,
--	PHYSICAL_READ_REQUESTS     ,
--	PHYSICAL_READ_BYTES        ,
--	PHYSICAL_WRITE_REQUESTS    ,
--	PHYSICAL_WRITE_BYTES       ,
--	WORKAREA_MEM               ,
--	WORKAREA_MAX_MEM           ,
--	WORKAREA_TEMPSEG           ,
--	WORKAREA_MAX_TEMPSEG       ,
--	OTHERSTAT_GROUP_ID         ,
--	OTHERSTAT_1_ID             ,
--	OTHERSTAT_1_TYPE           ,
--	OTHERSTAT_1_VALUE          ,
--	OTHERSTAT_2_ID             ,
--	OTHERSTAT_2_TYPE           ,
--	OTHERSTAT_2_VALUE          ,
--	OTHERSTAT_3_ID             ,
--	OTHERSTAT_3_TYPE           ,
--	OTHERSTAT_3_VALUE          ,
--	OTHERSTAT_4_ID             ,
--	OTHERSTAT_4_TYPE           ,
--	OTHERSTAT_4_VALUE          ,
--	OTHERSTAT_5_ID             ,
--	OTHERSTAT_5_TYPE           ,
--	OTHERSTAT_5_VALUE          ,
--	OTHERSTAT_6_ID             ,
--	OTHERSTAT_6_TYPE           ,
--	OTHERSTAT_6_VALUE          ,
--	OTHERSTAT_7_ID             ,
--	OTHERSTAT_7_TYPE           ,
--	OTHERSTAT_7_VALUE          ,
--	OTHERSTAT_8_ID             ,
--	OTHERSTAT_8_TYPE           ,
--	OTHERSTAT_8_VALUE          ,
--	OTHERSTAT_9_ID             ,
--	OTHERSTAT_9_TYPE           ,
--	OTHERSTAT_9_VALUE          ,
--	OTHERSTAT_10_ID            ,
--	OTHERSTAT_10_TYPE          ,
--	OTHERSTAT_10_VALUE         ,
--	OTHER_XML                  ,
--	PLAN_OPERATION_INACTIVE    ,
	0 dummy
from v$sql_plan_monitor join q using (KEY)
where LAST_CHANGE_TIME >= sysdate - 1/24/60
order by PLAN_LINE_ID
;
