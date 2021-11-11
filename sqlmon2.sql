/*
This script is a continuation of sqlmon.sql. 
It shows the SQL Monitor options to select one for the report generation.

Created by Eduardo Claro
Last changes on 2021-8-13
*/

set NUMWIDTH 15
prompt
accept KEYREP DEF "&KEYREP" prompt 'KEY/REPORT_ID for the report [&KEYREP]: '
--accept OUT DEF "A"  prompt 'Output type (A=Active/H=Html/T=Text)     [A]: '

set term off
col sqlid new_value sqlid
select 
	OPERATION as SQLID 
from plan_table 
where STATEMENT_ID = 'SQLMON'
	and OBJECT_NODE = '&OBJECT_NODE'
	and PLAN_ID=to_number(nvl('&KEYREP','0'))
;
col SPOOL NEW_VALUE SPOOL
col TYPE NEW_VALUE TYPE
col SCRIPT NEW_VALUE SCRIPT
select 
	'&tmp/sqlmon_&sqlid._' || trim('&KEYREP.') || 
	decode(upper('&OUT'),'A','_ACTIVE.','H','_HTML.','T','.','_ACTIVE.') ||
	decode(upper('&OUT'),'A','html','H','html','T','txt','html') SPOOL,
	decode(upper('&OUT'),'A','ACTIVE','H','HTML','T','TXT','ACTIVE') TYPE,
	case when '&KEYREP' is NULL or '&KEYREP' = '0' then 'null' else 'sqlmon3' end SCRIPT
from dual;

@@&SCRIPT
