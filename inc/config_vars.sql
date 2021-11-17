define MYDB=""
define MYSESS_TXT=""
define MYSID=""
define MYSER=""
define MYINST=""
define USE_PROMPT_COLOR=Y

-- EBS database?
define EBS="N"
col EBS new_value EBS
select 'Y' EBS from all_tables where table_name='FND_USER' and owner='APPLSYS';

-- OS specifics
col tmp NEW_VALUE tmp
col PROMPT_COLOR NEW_VALUE PROMPT_COLOR
select 
	case when upper('&_EDITOR') = 'NOTEPAD' then 'C:\temp' else '/tmp' end as tmp,
	case when upper('&_EDITOR') = 'NOTEPAD' then '#&_C_REVERSE' else '#&_CB_CYAN' end as PROMPT_COLOR
from dual;
col tmp clear
col PROMPT_COLOR clear

-- Get SQLPATH from OS
set echo off ver off feed off pages 0 escape #
select
	case when upper('&_EDITOR') = 'NOTEPAD' then
		'host echo define SQLPATH="%SQLPATH%" > config_vars2.tmp'
	else
		'host echo define SQLPATH="$SQLPATH" > config_vars2.tmp'
	end
from dual
.
spool config_vars.tmp
/
spool off
@config_vars.tmp
@config_vars2.tmp

-- Configure my session variables
col MYSESS new_value MYSESS
col MYSESS_TXT new_value MYSESS_TXT 
col MYDB new_value MYDB 
col MYINST new_value MYINST 
col MYSID new_value MYSID 
col MYSER new_value MYSER 
select
	sid || ',' || s.serial# || ',@' || sys_context( 'userenv', 'instance' ) as MYSESS,
	d.DB_UNIQUE_NAME || '_' || sid || '_' || s.serial# || '_' || sys_context( 'userenv', 'instance' ) as MYSESS_TXT,
	d.DB_UNIQUE_NAME MYDB, sid MYSID, s.serial# MYSER, sys_context( 'userenv', 'instance' ) MYINST
from v$session s
cross join v$database d
where sid = userenv('SID');
col MYSESS     clear
col MYSESS_TXT clear
col MYDB       clear
col MYINST     clear
col MYSID      clear
col MYSER      clear
