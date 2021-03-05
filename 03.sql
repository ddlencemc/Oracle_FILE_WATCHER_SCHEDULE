select file_watcher_name, directory_path, file_name, credential_name
from dba_scheduler_file_watchers;
select * from dba_scheduler_credentials;
select * from all_scheduler_jobs;
select * from all_scheduler_job_args;
select * from all_scheduler_programs p where p.owner = 'WATCHER' ;
select * from all_scheduler_program_args a where a.owner = 'WATCHER'; 
select * from all_scheduler_job_run_details j where j.owner = 'WATCHER'
order by 1 desc;
