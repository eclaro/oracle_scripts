/*
This script generates AWR Reports

Created by Eduardo Claro
Last changes on 2021-10-29

See the help below in the query
*/

define bs="0"
define es="0"
define typ="AWR"
define ins=""
define fmt="html"
define bd=""
define ed=""
define bs2=""
define es2=""
define ins2=""
define sqlid=""
define rac=""
define opt=""
define DEFAULTVAR1="bs"
define DEFAULTVAR2="es"
define DEFAULTVAR3="typ"
define DEFAULTVAR4="ins"
define DEFAULTVAR5="fmt"

-- Parse the received parameters
@@parser

set term off
col SCRIPT new_value SCRIPT
col AWRSPOOL NEW_VALUE AWRSPOOL
select
	case when upper('&HELP') in ('S','Y') then 'null' else 'awr2' end SCRIPT
from dual;
@inc/save_set.sql
set head off feed off ver off timing off
set term on

WITH
help as (
select q'[
------------------------------------------------------------------------
Usage:
   START awr bs es typ ins fmt par=value par=value ...
   START awr par=value par=value ...

Parameters (can be passed in any order in the form parameter=value)
   bs   : begin SNAP_ID
   es   : end SNAP_ID
   bd   : begin date (use format 'yyyy/mm/dd-hh24:mi'), only for ASH reports (use bd/ed or bs/es)
   ed   : begin date (use format 'yyyy/mm/dd-hh24:mi'), only for ASH reports (use bd/ed or bs/es)
   rac  : Y for Global (RAC) reports
   ins  : instance number (default 1 or NULL for RAC=Y)
   typ  : type of the report = 'AWR' (default), 'ASH' or 'SQL'
   fmt  : format = HTML (default) or TEXT
   bs2  : begin SNAP_ID for DIFF reports
   es2  : end SNAP_ID for DIFF reports
   ins2 : instance number for DIFF reports (default = ins)
   sqlid: the SQL_ID for the SQL type report
   opt  : additional options (depend on the type)

Example:
   START awr 200 210
   START awr 200 210 awr 1
   START awr bs=200 es=210 typ=awr rac=y
   START awr 200 210 bs2=220 es2=230 fmt=html
   START 200 210 sql sqlid=fkubjw4jnzvum
------------------------------------------------------------------------
]' HELPTXT
from dual
)
select * from help where upper('&HELP') in ('S','Y')
;

@inc/load_set.sql
set term on

@@&SCRIPT

@@inc/reset_pars
