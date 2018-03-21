/* Show all the 256 colors (if the terminal have this capability) */

col color for a200

prompt
prompt Background colors. USAGE: chr(27) || '[48;5;' || number
define x=48
select
	'id=' || to_char(4 * (level-1) + 1,'999') || 
	chr(27) || '[&x.;5;' || ( 4 * (level-1) + 1 ) || 'm' || ' COLOR ' || chr(27) || '[0m' || '    ' ||
	'id=' || to_char(4 * (level-1) + 2,'999') || 
	chr(27) || '[&x.;5;' || ( 4 * (level-1) + 2 ) || 'm' || ' COLOR ' || chr(27) || '[0m' || '    ' ||
	'id=' || to_char(4 * (level-1) + 3,'999') || 
	chr(27) || '[&x.;5;' || ( 4 * (level-1) + 3 ) || 'm' || ' COLOR ' || chr(27) || '[0m' || '    ' ||
	'id=' || to_char(4 * (level-1) + 4,'999') || 
	chr(27) || '[&x.;5;' || ( 4 * (level-1) + 4 ) || 'm' || ' COLOR ' || chr(27) || '[0m' color
from dual connect by level <= 256/4;

prompt
prompt Foreground colors USAGE: chr(27) || '[38;5;' || number
define x=38
select
	'id=' || to_char(4 * (level-1) + 1,'999') || 
	chr(27) || '[&x.;5;' || ( 4 * (level-1) + 1 ) || 'm' || ' COLOR ' || chr(27) || '[0m' || '    ' ||
	'id=' || to_char(4 * (level-1) + 2,'999') || 
	chr(27) || '[&x.;5;' || ( 4 * (level-1) + 2 ) || 'm' || ' COLOR ' || chr(27) || '[0m' || '    ' ||
	'id=' || to_char(4 * (level-1) + 3,'999') || 
	chr(27) || '[&x.;5;' || ( 4 * (level-1) + 3 ) || 'm' || ' COLOR ' || chr(27) || '[0m' || '    ' ||
	'id=' || to_char(4 * (level-1) + 4,'999') || 
	chr(27) || '[&x.;5;' || ( 4 * (level-1) + 4 ) || 'm' || ' COLOR ' || chr(27) || '[0m' color
from dual connect by level <= 256/4;
