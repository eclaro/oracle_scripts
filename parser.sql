/*
Parameter parser

This script transform all the parameters (&1-&16) into SQL*Plus variables
It allows you to pass parameters in no specific order in the format PAR=val

Created by Eduardo Claro, 2018-8-15
Last changes on 2018-03-20

Example: if you run the script and the values of &1 is "VAR1='X'", it will define the SQL*Plus variable VAR1 to 'X'

For this to work properly, the number variables should be pre-defined as NULL in the login.sql
*/

set term off 
store set set.tmp replace
set feed off ver off echo off head off timing off
spool parser.tmp REPLACE
select
	case when q'!&1!'  is not null then q'!define &1!'  end || chr(10) ||
	case when q'!&2!'  is not null then q'!define &2!'  end || chr(10) ||
	case when q'!&3!'  is not null then q'!define &3!'  end || chr(10) ||
	case when q'!&4!'  is not null then q'!define &4!'  end || chr(10) ||
	case when q'!&5!'  is not null then q'!define &5!'  end || chr(10) ||
	case when q'!&6!'  is not null then q'!define &6!'  end || chr(10) ||
	case when q'!&7!'  is not null then q'!define &7!'  end || chr(10) ||
	case when q'!&8!'  is not null then q'!define &8!'  end || chr(10) ||
	case when q'!&9!'  is not null then q'!define &9!'  end || chr(10) ||
	case when q'!&10!' is not null then q'!define &10!' end || chr(10) ||
	case when q'!&11!' is not null then q'!define &11!' end || chr(10) ||
	case when q'!&12!' is not null then q'!define &12!' end || chr(10) ||
	case when q'!&13!' is not null then q'!define &13!' end || chr(10) ||
	case when q'!&14!' is not null then q'!define &14!' end || chr(10) ||
	case when q'!&15!' is not null then q'!define &15!' end || chr(10) ||
	case when q'!&16!' is not null then q'!define &16!'end statement
from dual;
spool off
@parser.tmp
@set.tmp
set term on
