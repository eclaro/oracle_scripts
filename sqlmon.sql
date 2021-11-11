/*
This script generates a SQL Monitor report for a specific run of a query

Created by Eduardo Claro
Last changes on 2021-11-11

See the help below in the query
*/

set term off
@inc/save_set

-- Default values for the parameters
define type=""
define sqlid=""
define phv=""
define exec=""
define begin="sysdate-1"
define end="sysdate"
define min="0"
define tim=""
define bd=""
define ed=""
define user=""
define src="A"
define out="A"
define secs=0
define DEFAULTVAR1="type"
define DEFAULTVAR2="sqlid"
define DEFAULTVAR3="phv"
define DEFAULTVAR4="exec"

def KEYREP=""

-- Parse the received parameters
@@parser

set term off
col QUERY NEW_VALUE QUERY
col datini new_value datini
col datfin new_value datfin
coL SCRIPT NEW_VALUE SCRIPT
col SQLID NEW_VALUE SQLID
col TYPE NEW_VALUE TYPE
select
	case 
		when upper('&HELP') in ('S','Y') or upper('&TYPE') in ('D','M') then 'help' 
		else 'main' 
	end QUERY,
	case 
		when upper('&HELP') in ('S','Y') or '&OUT' = '0' then 'null' 
		when upper('&TYPE') in ('C') then 'null'
		when upper('&TYPE') in ('D','M') then 'sqlmond1'
		else 'sqlmon2' 
	end SCRIPT,
	case 
		when to_number('&MIN') < 0 then q'[trunc(sysdate,'mi')+(&MIN./24/60)]' 
		when to_number('&MIN') > 0 then q'[&begin]' 
		when '&bd' is not null then q'[to_date('&bd','yyyy/mm/dd-hh24:mi')]' 
		else q'[&begin]' 
	end datini,
	case 
		when to_number('&MIN') < 0 then 'sysdate'
		when to_number('&MIN') > 0 then q'[&begin.+&MIN./24/60]'
		when '&ed' is not null then q'[to_date('&ed','yyyy/mm/dd-hh24:mi')]' 
		else q'[&END]'
	end datfin,
	case
		when upper('&TYPE') NOT in ('R','C','D','M') then '&TYPE'
		else '&SQLID' 
	end SQLID,
	case
		when upper('&TYPE') NOT in ('R','C','D','M') then 'R'
		else '&TYPE' 
	end TYPE
from dual;
col TIM new_value TIM
select nvl('&TIM',decode(upper('&TYPE'),'D',0,1)) TIM from dual where upper('&TYPE') in ('M','D');

col OBJECT_NODE NEW_VALUE OBJECT_NODE
select to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') OBJECT_NODE from dual;
INSERT INTO PLAN_TABLE (
	STATEMENT_ID/*'SQLMON'*/,OBJECT_NODE/*SYSDATE*/, REMARKS/*SRC*/,PLAN_ID/*KEYREP*/,
	OPERATION/*SQL_ID*/,ID/*SQL_EXEC_ID*/,OPTIONS/*USERNAME*/,
	PARENT_ID/*SQL_PLAN_HASH_VALUE*/,DEPTH/*FMS*/,OTHER_TAG/*STATUS*/,
	TIMESTAMP/*EXEC_START*/,PARTITION_STOP/*LAST_REFR*/, 
	COST/*SECS*/, ACCESS_PREDICATES/*SQL_TEXT*/
	)
WITH
mem as (
	select *
	from (
		select key, report_id, sql_id, SQL_EXEC_ID, USERNAME, 
			SQL_PLAN_HASH_VALUE, force_matching_signature FMS, status, sql_exec_start, 
			LAST_REFRESH_TIME, (LAST_REFRESH_TIME - sql_exec_start) *24*60*60 SECS,
			sql_text
		from gv$sql_monitor
		where (SQL_ID='&sqlid' or '&sqlid' is null)
		and (SQL_PLAN_HASH_VALUE = to_number('&phv') or '&phv' is null)
		and (SQL_EXEC_ID = to_number('&exec') or '&exec' is null)
		and SQL_PLAN_HASH_VALUE <> 0
		and nvl(PX_QCSID,SID) = SID and nvl(PX_QCINST_ID,INST_ID) = INST_ID --don't show Parallel slaves
		and upper('&SRC') <> 'H'
		and sql_exec_start between &datini and &datfin
		and (username = upper('&USER') or '&USER' is null)
	)
	where secs >= &secs
),
hist as (
	select * 
	from (
		select a.*, (LAST_REFRESH_TIME - sql_exec_start) *24*60*60 SECS
		from
			(
			select report_id, KEY1 as SQL_ID, to_number(KEY2) as SQL_EXEC_ID, GENERATION_TIME,
				to_date(key3,'mm:dd:yyyy hh24:mi:ss') as sql_exec_start,
--				to_date(EXTRACTVALUE(XMLType(report_summary),'/report_repository_summary/sql/@sql_exec_start'),'mm/dd/yyyy hh24:mi:ss') sql_exec_start,
				EXTRACTVALUE(XMLType(report_summary),'/report_repository_summary/sql/status') status,
				to_date(EXTRACTVALUE(XMLType(report_summary),'/report_repository_summary/sql/last_refresh_time'),'mm/dd/yyyy hh24:mi:ss') last_refresh_time,
				EXTRACTVALUE(XMLType(report_summary),'/report_repository_summary/sql/sql_text') sql_text,
				EXTRACTVALUE(XMLType(report_summary),'/report_repository_summary/sql/user') username,
				to_number(EXTRACTVALUE(XMLType(report_summary),'/report_repository_summary/sql/plan_hash')) SQL_PLAN_HASH_VALUE
			from DBA_HIST_REPORTS
			where component_name = 'sqlmonitor'
			AND report_name = 'main'
			AND (KEY1='&sqlid' or '&sqlid' is null)
			and (to_number(EXTRACTVALUE(XMLType(report_summary),'/report_repository_summary/sql/plan_hash')) = to_number('&phv') or '&phv' is null)
			and (KEY2 = '&exec' or '&exec' is null)
			and upper('&SRC') <> 'M'
			and GENERATION_TIME between &datini and &datfin
			) a
		)
	where secs >= &secs
	and (username = upper('&USER') or '&USER' is null)
)
select
	'SQLMON', '&OBJECT_NODE',
	case when mem.SQL_PLAN_HASH_VALUE is not null then 'MEM' else 'HIST' end SRC,
	coalesce(mem.KEY, hist.REPORT_ID) keyrep,
	SQL_ID, SQL_EXEC_ID, 
	coalesce(mem.USERNAME, hist.USERNAME) USERNAME, 
	coalesce(mem.SQL_PLAN_HASH_VALUE, hist.SQL_PLAN_HASH_VALUE) SQL_PLAN_HASH_VALUE, mem.FMS, 
	coalesce(mem.STATUS, hist.STATUS) STATUS, coalesce(mem.SQL_EXEC_START, hist.SQL_EXEC_START) EXEC_START,
	to_char(coalesce(mem.LAST_REFRESH_TIME,hist.LAST_REFRESH_TIME),'yyyy-mm-dd hh24:mi:ss') LAST_REFR, 
	coalesce(mem.SECS, hist.SECS) SECS, coalesce(mem.SQL_TEXT, hist.SQL_TEXT) SQL_TEXT
from mem
full join hist using (SQL_ID, SQL_EXEC_ID)
where nvl(upper('&HELP'),'N') NOT in ('S','Y')
and nvl(upper('&TYPE'),'R') NOT in ('D','M')
;
set term on

col keyrep NEW_VALUE KEYREP for 9999999999999
col module for a16 trunc
col action for a20 trunc
col sql_text for a35 trunc
col refresh_count for 9999 head "REFRs"
col FMS for 999999999999999999999
col SECS for 99999
set tab off
col KEYREP head "KEY/REPORT_ID"
col SRC for a4
col zSTATUS head "STATUS" for a20 trunc
col SQL_EXEC_START for a20

WITH
help as (
select q'[
Usage:
   START sqlmon par=value par=value ...

Parameters (can be passed in any order in the form parameter=value)
   type : (first MANDATORY parameter) the type of execution:
      c = just checks (shows) the reports available
      r = after seeing the the reports available you can inform one to extract the SQL Monitor report (the default value)
      d = details (execution plan and associated statistics) of a specific execution (finished or not). Only for src=M.
      m = monitor a running SQL in real time, showing stats for each row that have change over the last &tim minutes. Only for src=M.
   sqlid: (default second parameter) the SQL_ID
   phv  : (default third parameter) the PLAN_HASH_VALUE
   exec : (default fourth parameter) the SQL_EXEC_ID
   tim  : time in minutes to show in SQL Monitor details (just for type=M, default 1)
   user : the USERNAME
   src  : the source. Enter H to query the history view or M to query memory. Any other value will bring both.
   secs : minimum seconds (default 0)
   out  : the output type of the report:
      A = active (the default value)
      H = html
      T = text
      0 = none

   To filter queries by their SQL_EXEC_START (for type R/C):
      begin: begin date as a DATE expression, like sysdate-1 (the default value).
      end  : end   date as a DATE expression, like sysdate (the default value).
      min  : interval in minutes, can only be combined with begin/end, not bd/ed.
             if a positive number is provided, the period is defined starting with begin and ending the number of minutes after that (end parameter is ignored).
   		     if a negative number is provided, the period is defined starting the number of minutes before now (sysdate) and ending now (begin and end are ignored).
      bd   : begin date (use format 'yyyy/mm/dd-hh24:mi').
      ed   : begin date (use format 'yyyy/mm/dd-hh24:mi').
   --

Example:
   START sqlmon 92y2r3d37mxg5
   START sqlmon src=H sqlid=92y2r3d37mxg5 user=CLAROE
]' HELPTXT
from dual
where upper('&HELP') in ('S','Y') 
),
--==============================================================================================================
main as (
	select
		REMARKS as SRC, PLAN_ID as KEYREP,
		OPERATION as SQL_ID, PARENT_ID as SQL_PLAN_HASH_VALUE, ID as SQL_EXEC_ID, 
		OPTIONS as USERNAME, DEPTH as FMS, OTHER_TAG as zSTATUS,
		TIMESTAMP as EXEC_START, to_date(PARTITION_STOP,'yyyy-mm-dd hh24:mi:ss') as LAST_REFR, 
		COST as SECS, ACCESS_PREDICATES as SQL_TEXT
	from plan_table
	where STATEMENT_ID = 'SQLMON'
	and OBJECT_NODE = '&OBJECT_NODE'
	and COST /*SECS*/ >= &secs
	order by EXEC_START
)
--==============================================================================================================
select * from &QUERY
;

set term off
select case when '&KEYREP' is NULL and '&SCRIPT' = 'sqlmon2' then 'null' else '&SCRIPT' end SCRIPT from dual;
set term on

@@&SCRIPT

@inc/load_set
set term on

@@inc/reset_pars
