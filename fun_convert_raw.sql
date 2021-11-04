	function FUN_CONVERT_RAW (P_VALUE raw, P_DATATYPE VARCHAR2)
	return varchar2 
	is
	begin
		if P_VALUE is null then return '';
		elsif P_DATATYPE in ('VARCHAR2','CHAR') then return utl_raw.cast_to_varchar2(P_VALUE);
		elsif P_DATATYPE = 'NUMBER' then return to_char(utl_raw.cast_to_number(P_VALUE));
		elsif P_DATATYPE = 'DATE' then return TO_CHAR(dbms_stats.convert_raw_to_date(P_VALUE),'yyyy-mm-dd hh24:mi:ss');
		elsif P_DATATYPE like 'TIMESTAMP%WITH TIME ZONE' then return  -- if it is TIMESTAMP WITH TIMEZONE, convert from UTC to local time
			to_char(
				FROM_TZ(
					to_timestamp(dbms_stats.convert_raw_to_date(hextoraw(substr(P_VALUE,1,14)))) +
					numtodsinterval( nvl( to_number(hextoraw(substr(P_VALUE,15,8)),'XXXXXXXX')/1e9, 0 ), 'SECOND')
					, 'UTC' ) at local
				,'yyyy-mm-dd hh24:mi:ss.ff9');
		elsif P_DATATYPE like 'TIMESTAMP%' then return
			to_char(
				to_timestamp(dbms_stats.convert_raw_to_date(hextoraw(substr(P_VALUE,1,14)))) +
				numtodsinterval( nvl( to_number(hextoraw(substr(P_VALUE,15,8)),'XXXXXXXX')/1e9, 0 ), 'SECOND')
				,'yyyy-mm-dd hh24:mi:ss.ff9');
		else return '';
		end if;
	end;
