# Oracle FILE_WATCHER_SCHEDULE, Parsing Marketo json file

### Task Description
It is necessary to monitor the catalog for new json-files to download to Oracle. 
Newest file needed upload to table. Parsing uploaded file and put clear data to report-table 
Dictionary provided by data supplier:
```
|ACTIVITY_TYPE_ID| ATTRIBUTE_NAME	| ATTRIBUTE_DATATYPE  |IS_PRIMARY |
|	9	 | Campaign Run ID	|         integer     |	    0 	  |
|	9	 | Client IP Address	|         string      |	    0 	  |
|	9	 | Form Fields		|         text        |	    0 	  |
|	9	 | Has Predictive	|	  boolean     |	    0 	  |
|	9	 | Query Parameters	|         string      |	    0 	  |
|	9	 | Referrer URL		|         string      |	    0 	  |
|	9	 | Test Variant		|         integer     |	    0 	  |
|	9	 | User Agent		|         string      |	    0 	  |
|	9	 | Webform ID		|         integer     |	    0 	  |
|	9	 | Webpage ID		|         integer     |	    0 	  |
|	9	 | Mailing ID		|         integer     |	    0 	  |
```
Useful (or confusing) links:

https://developers.marketo.com/rest-api/bulk-extract/bulk-activity-extract/

https://developers.marketo.com/rest-api/lead-database/fields/field-types/

### Solution
01.sql - run as sysdba user (create user + grants, register directory where will be files)

02.sql - run as new user watcher (created in 01.sql, stored procedures, tables ddl, file watcher) - You must to change user credentials in credential section, and change path to your directory

03.sql - debug queries

04.sql - show result

05.sql - drop all objects

Put some file (like an example.txt) to PATH and wait 1 min, after cheking 04.sql
Attention! Creation date of files in PATH should be more then time when you enabled job/file watcher/program.
After you create file like an example.txt you have to wait a one minute and use 04.sql to see result. You don't have to run job by yourself like "dbms_scheduler.run_job". Default time 10 minutes, changed it in the 01.sql to 1 minute.
