create user watcher identified by watcher;
grant connect to watcher;
grant EXECUTE on SYS.SCHEDULER_FILEWATCHER_RESULT to watcher;
grant create table, create procedure, create job, create sequence to watcher;
grant execute on dbms_lock to watcher;
grant execute on dbms_system to watcher;
grant manage scheduler to watcher;
create or replace directory JSON_FILES_DIR as 'E:\files';
grant read, write on directory json_files_dir to watcher;

BEGIN
  DBMS_SCHEDULER.SET_ATTRIBUTE('FILE_WATCHER_SCHEDULE', 'REPEAT_INTERVAL',
    'FREQ=MINUTELY;INTERVAL=1');
END;
/
