/*
This script is a continuation of sqlmon.sql

Created by Eduardo Claro
Last changes on 2021-8-12
*/

/*
https://sqlmaria.com/2017/08/01/getting-the-most-out-of-oracle-sql-monitor/?unapproved=15990&moderation-hash=345d82d91085062ece092c8cd001201e#comment-15990
Disabling SQL Monitor compression that hits a bug (28649388) when < 18C RU 18.4, that makes the SQL Monitor not display for very large reports
*/
alter session set events = 'emx_control compress_xml=none';
set term on
----------------------
set lines 32767 trimout on trimspool on head off feed off echo off timing off termout off long 1000000 longchunksize 1000000 ver off pages 0
spool &SPOOL
select DBMS_SQL_MONITOR.report_sql_monitor(
	sql_id => a.OPERATION,
	sql_exec_start => a.TIMESTAMP,
	sql_exec_id => a.ID,
	report_level=>'ALL',type=>'&TYPE')
from plan_table a
where STATEMENT_ID = 'SQLMON'
and OBJECT_NODE = '&OBJECT_NODE'
and PLAN_ID=to_number(nvl('&KEYREP','0'))
and REMARKS='MEM'
UNION ALL
select dbms_auto_report.Report_repository_detail(
	RID  => to_number(nvl('&KEYREP','0')), 
	TYPE => '&TYPE')
from plan_table a
where STATEMENT_ID = 'SQLMON'
and OBJECT_NODE = '&OBJECT_NODE'
and PLAN_ID=to_number(nvl('&KEYREP','0'))
and REMARKS='HIST'
;
spool off

prompt
prompt Report generated on "&SPOOL"
