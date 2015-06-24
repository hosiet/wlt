#
# Regular cron jobs for the wlt-scripts-0.1 package
#
0 4	* * *	root	[ -x /usr/bin/wlt-scripts-0.1_maintenance ] && /usr/bin/wlt-scripts-0.1_maintenance
