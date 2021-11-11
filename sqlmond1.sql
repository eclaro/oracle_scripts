/*
This script shows the SQL Monitor details for a given SQL while it's running
It shows the steps that had changes in stats for the last minute

Created by Eduardo Claro on 2021-8-3
Last changes on 2021-11-11

Parameter 1: SQL_ID
Parameter 2: PLAN_HASH_VALUE
Parameter 3: SQL_EXEC_ID (optional)
Parameter 4: minutes (0=show all, default 1)
*/

col OBJECT for a40
col OPOP for a50
col OPOB for a80 head "OPERATION + OPTIONS + OBJECT"
col OUT_ROWS for 999999999999
col FIRST_CHG_TIME for a20
col LAST_CHG_TIME for a20

compute sum of STARTS on report
compute min max of LINE_ID on report
compute sum of OUT_ROWS on report
break on report

WITH q as (
	select KEY, INST_ID, CON_ID, SQL_EXEC_ID, SID
	from gv$sql_monitor	
	where sql_id='&sqlid' and SQL_PLAN_HASH_VALUE='&phv'
	and (SQL_EXEC_ID = '&exec' or '&exec' is null)
	and rownum=1
),
ash as (
	select * from (
		select
			ash.SQL_PLAN_LINE_ID, s.SID, s.INST_ID, s.SQL_EXEC_ID,
			row_number() over (partition by s.inst_id, s.sid, s.SERIAL# order by sample_id desc) rn
		from gv$active_session_history ash
		join gv$session s
			on s.status = 'ACTIVE'
			and ash.inst_id = s.inst_id
			and ash.session_id = s.sid
			and ash.SESSION_SERIAL# = s.SERIAL#
			and ash.sql_id = s.sql_id
			and ash.sql_exec_id = s.sql_exec_id
			and ash.sample_time >= sysdate - 10/24/60/60 --s.sql_exec_start
		where ash.sql_id='&sqlid' and ash.SQL_PLAN_HASH_VALUE='&phv'
		and (ash.SQL_EXEC_ID = '&exec' or '&exec' is null)
	)
	where rn=1
)
select 
--	spm.CON_ID                     ,
--	spm.KEY                        ,
--	spm.STATUS                     ,
--	to_char(FIRST_REFRESH_TIME,'YY-MM-DD hh24:mi:ss') as FIRST_REF_TIME,
--	to_char(LAST_REFRESH_TIME,'YY-MM-DD hh24:mi:ss') as LAST_REF_TIME,
	to_char(spm.FIRST_CHANGE_TIME,'YY-MM-DD hh24:mi:ss') as FIRST_CHG_TIME,
	to_char(spm.LAST_CHANGE_TIME,'YY-MM-DD hh24:mi:ss') as LAST_CHG_TIME,
--	spm.REFRESH_COUNT              as REF_CNT,
--	spm.SID                        ,
--	spm.PROCESS_NAME               ,
--	spm.SQL_ID                     ,
--	spm.SQL_EXEC_START             ,
--	spm.SQL_EXEC_ID                ,
--	spm.SQL_PLAN_HASH_VALUE        ,
--	spm.SQL_CHILD_ADDRESS          ,
--	spm.PLAN_PARENT_ID             ,
	case when coalesce(spm.PLAN_LINE_ID,ash.SQL_PLAN_LINE_ID) = lop.SQL_PLAN_LINE_ID then '==>' else '' end CUR,
	spm.PLAN_LINE_ID               as LINE_ID,
	spm.STARTS                     ,
	spm.OUTPUT_ROWS                OUT_ROWS,
	lpad(' ',spm.PLAN_DEPTH,' ') || spm.PLAN_OPERATION || ' ' || spm.PLAN_OPTIONS || ' ' || 
		case when spm.PLAN_OBJECT_OWNER is NULL then '' else spm.PLAN_OBJECT_OWNER || '.' end || spm.PLAN_OBJECT_NAME as OPOB,
	spm.PLAN_COST                  as COST,
	spm.PLAN_CARDINALITY           as CARD,
	spm.PLAN_BYTES                 as BYTES,
	spm.PLAN_DEPTH                 as DEPTH,
	spm.PLAN_POSITION              as POS,
--	spm.PLAN_TIME                  ,
--	spm.PLAN_PARTITION_START       ,
--	spm.PLAN_PARTITION_STOP        ,
--	spm.PLAN_CPU_COST              ,
--	spm.PLAN_IO_COST               ,
--	spm.PLAN_TEMP_SPACE            ,
--	spm.IO_INTERCONNECT_BYTES      ,
--	spm.PHYSICAL_READ_REQUESTS     ,
--	spm.PHYSICAL_READ_BYTES        ,
--	spm.PHYSICAL_WRITE_REQUESTS    ,
--	spm.PHYSICAL_WRITE_BYTES       ,
--	spm.WORKAREA_MEM               ,
--	spm.WORKAREA_MAX_MEM           ,
--	spm.WORKAREA_TEMPSEG           ,
--	spm.WORKAREA_MAX_TEMPSEG       ,
--	spm.OTHERSTAT_GROUP_ID         ,
--	spm.OTHERSTAT_1_ID             ,
--	spm.OTHERSTAT_1_TYPE           ,
--	spm.OTHERSTAT_1_VALUE          ,
--	spm.OTHERSTAT_2_ID             ,
--	spm.OTHERSTAT_2_TYPE           ,
--	spm.OTHERSTAT_2_VALUE          ,
--	spm.OTHERSTAT_3_ID             ,
--	spm.OTHERSTAT_3_TYPE           ,
--	spm.OTHERSTAT_3_VALUE          ,
--	spm.OTHERSTAT_4_ID             ,
--	spm.OTHERSTAT_4_TYPE           ,
--	spm.OTHERSTAT_4_VALUE          ,
--	spm.OTHERSTAT_5_ID             ,
--	spm.OTHERSTAT_5_TYPE           ,
--	spm.OTHERSTAT_5_VALUE          ,
--	spm.OTHERSTAT_6_ID             ,
--	spm.OTHERSTAT_6_TYPE           ,
--	spm.OTHERSTAT_6_VALUE          ,
--	spm.OTHERSTAT_7_ID             ,
--	spm.OTHERSTAT_7_TYPE           ,
--	spm.OTHERSTAT_7_VALUE          ,
--	spm.OTHERSTAT_8_ID             ,
--	spm.OTHERSTAT_8_TYPE           ,
--	spm.OTHERSTAT_8_VALUE          ,
--	spm.OTHERSTAT_9_ID             ,
--	spm.OTHERSTAT_9_TYPE           ,
--	spm.OTHERSTAT_9_VALUE          ,
--	spm.OTHERSTAT_10_ID            ,
--	spm.OTHERSTAT_10_TYPE          ,
--	spm.OTHERSTAT_10_VALUE         ,
--	spm.OTHER_XML                  ,
--	spm.PLAN_OPERATION_INACTIVE    ,
	0 dummy
from gv$sql_plan_monitor spm 
join q on q.KEY = spm.KEY and q.INST_ID = spm.INST_ID and q.CON_ID = spm.CON_ID
left join gv$session_longops lop on lop.INST_ID = q.INST_ID and lop.SID = q.SID and q.SQL_EXEC_ID = lop.SQL_EXEC_ID and lop.SOFAR < lop.TOTALWORK
left join ash on q.SID = ash.SID and q.INST_ID = ash.INST_ID and q.SQL_EXEC_ID = ash.SQL_EXEC_ID
where (spm.LAST_CHANGE_TIME >= sysdate - nvl(to_number('&tim'),1)/24/60 or to_number('&tim')=0)
order by spm.PLAN_LINE_ID
;

/*
select report
from DBA_HIST_REPORTS_details
where report_Id=7990232
;

SELECT
XMLSERIALIZE( DOCUMENT
XMLTYPE (
report
) as CLOB INDENT) report
FROM dba_hist_reports_details
WHERE report_id =7990232
;

select
	--report
	extractvalue(XMLType(report),'/sql_monitor_report/report_parameters/sql_id') sql_id
--	extractvalue(XMLType(report_summary),'/report_repository_summary/sql/@sql_exec_id') sql_exec_id,
--	extractvalue(XMLType(report_summary),'/report_repository_summary/sql/@sql_exec_start') sql_exec_start
from DBA_HIST_REPORTS_details
where report_Id=7990232
;

SELECT report_id
FROM    XMLTABLE
   ('//report_repository_summary/sql/report_id'
	 PASSING XMLTYPE (REPORT)
	 COLUMNS
	   report_id  NUMBER  PATH '.')
from DBA_HIST_REPORTS_details
where report_Id=7990232
;

SELECT VALUE(p) AS elemento
FROM 
	(
	SELECT XMLTYPE(REPORT) AS xmlrep 
	FROM DBA_HIST_REPORTS_details
	where report_Id=7990232
	) t ,
TABLE(xmlsequence(extract(xmlrep, '/report_repository_summary/sql/last_refresh_time'))) p
;

select 
	extractvalue(XMLType(report_summary),'/report_repository_summary/sql/@sql_id') sql_id,
	extractvalue(XMLType(report_summary),'/report_repository_summary/sql/@sql_exec_id') sql_exec_id,
	extractvalue(XMLType(report_summary),'/report_repository_summary/sql/@sql_exec_start') sql_exec_start,
	REPORT_SUMMARY
from DBA_HIST_REPORTS a
where report_Id=7990232
;
*/

@inc/reset_pars
