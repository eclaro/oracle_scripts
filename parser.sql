/*
Parameter parser

This script transform all the parameters (&1-&16) into SQL*Plus variables

Created by Eduardo Claro, 2018-3-15
Last changes on 2021-11-12

Usage

	@parser PAR=value PAR=value ...

	You can pass up to 16 parameters in no specific order.
	To pass parameters with spaces or other special characters, use "" and '' like in the examples below.
	In order for this to work properly, the number variables should be pre-defined as NULL in the login.sql.
	The general format to pass the parameters is PAR=value. 
	If caller script have defined a default variable, then you can call it just passing the parameter value (see examples).

	If the first parameter is HELP, it creates a variable HELP=Y

	I always issue "set term off" before running this script, and "set term on" after it, to not show the results in the terminal.

Examples:

	@parser VAR1='X' "VAR2='A B C'" VAR3=
	this would result in:
		DEFINE VAR1 = "X"
		DEFINE VAR2 = "A B C"

	@parser ABC123 XYZ
	this would result in:
		DEFINE &DEFAULTVAR1 = "ABC123"
		DEFINE &DEFAULTVAR2 = "XYZ"
*/
set term off
define HELP=""
store set set.tmp replace
set feed off ver off echo off head off timing off
spool parser.tmp REPLACE
select
	case 
		when upper(q'!&1!') in ('HELP','HLP') then 'define HELP=Y' 
		when q'!&1!' not like '%=%' then 'define &DEFAULTVAR1=' || q'!&1!' 
		when q'!&1!'   is not null then regexp_replace(q'!define  &1."!','=','="',1,1) end || chr(10) ||
	case 
		when q'!&2!' not like '%=%' then 'define &DEFAULTVAR2=' || q'!&2!' 
		when q'!&2!'  is not null then regexp_replace(q'!define  &2."!','=','="',1,1) end || chr(10) ||
	case 
		when q'!&3!' not like '%=%' then 'define &DEFAULTVAR3=' || q'!&3!' 
		when q'!&3!'  is not null then regexp_replace(q'!define  &3."!','=','="',1,1) end || chr(10) ||
	case 
		when q'!&4!' not like '%=%' then 'define &DEFAULTVAR4=' || q'!&4!' 
		when q'!&4!'  is not null then regexp_replace(q'!define  &4."!','=','="',1,1) end || chr(10) ||
	case when q'!&5!'  is not null then regexp_replace(q'!define  &5."!','=','="',1,1) end || chr(10) ||
	case when q'!&6!'  is not null then regexp_replace(q'!define  &6."!','=','="',1,1) end || chr(10) ||
	case when q'!&7!'  is not null then regexp_replace(q'!define  &7."!','=','="',1,1) end || chr(10) ||
	case when q'!&8!'  is not null then regexp_replace(q'!define  &8."!','=','="',1,1) end || chr(10) ||
	case when q'!&9!'  is not null then regexp_replace(q'!define  &9."!','=','="',1,1) end || chr(10) ||
	case when q'!&10!' is not null then regexp_replace(q'!define &10."!','=','="',1,1) end || chr(10) ||
	case when q'!&11!' is not null then regexp_replace(q'!define &11."!','=','="',1,1) end || chr(10) ||
	case when q'!&12!' is not null then regexp_replace(q'!define &12."!','=','="',1,1) end || chr(10) ||
	case when q'!&13!' is not null then regexp_replace(q'!define &13."!','=','="',1,1) end || chr(10) ||
	case when q'!&14!' is not null then regexp_replace(q'!define &14."!','=','="',1,1) end || chr(10) ||
	case when q'!&15!' is not null then regexp_replace(q'!define &15."!','=','="',1,1) end || chr(10) ||
	case when q'!&16!' is not null then regexp_replace(q'!define &16."!','=','="',1,1) end statement
from dual;
spool off
@parser.tmp
@set.tmp
set term on
