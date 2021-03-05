/*
begin
  dbms_scheduler.drop_job('json_file_job');
end;  
/
begin
  dbms_scheduler.drop_program('json_file_program');
end; 
/
begin 
  dbms_scheduler.drop_file_watcher('json_file_watcher');
end;
/
begin
  dbms_scheduler.drop_credential('watcher_credential');
end;  
/
drop procedure watcher.upload_json_file;
drop procedure watcher.parse_json;
drop sequence watcher.seq_json_files;
drop table watcher.data_extract;
drop table watcher.json_files
*/