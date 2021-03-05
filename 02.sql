create sequence seq_json_files
  minvalue 1
  maxvalue 999999999999999
  start with 1
  increment by 1
  cache 5
  order;
 
create table json_files(
  id number,
  ins_date date,
  file_name  varchar2(255),
  file_date_time  timestamp,
  file_size  number,
  file_cont   clob,
  status number(1) default 0
);
/

create table data_extract (
  file_id number,
  campaign_run_id integer,
  client_ip_address varchar2(15),
  form_fields clob,
  has_predictive number(1),
  query_parameters varchar2(255),
  referrer_url varchar2(1000),
  test_variant integer,
  user_agent varchar2(400),
  webform_id integer,
  webpage_id integer,
  mailing_id integer
);
/
create or replace procedure parse_json (p_file_id in number) as
  v_json_row clob;
  v_form_field clob;
  v_patt number;
begin
  for cur in (
    with clob_table(clob_data) as (
      select file_cont 
      from json_files jf 
      where jf.id = p_file_id 
        and jf.status = 0)
    select regexp_substr(clob_data, '.+', 1, level) text,level line
    from clob_table
    connect by level <= regexp_count(clob_data, '.+')
  )
  loop
    v_json_row := replace(cur.text,chr(13),null);
    v_patt := instr(v_json_row, '"{""',1,1);
    if v_patt > 0 then
      v_json_row := substr(
                      replace(
                        replace(
                          replace(
                            replace(
                              regexp_replace(
                                v_json_row, '"":[^"]+?""', '":"'|| replace(
                                  replace(regexp_substr(v_json_row,'":[^"]+?,',1,1),'":',''),',','')||'",'), -- for ""Webpage ID"":695040, --> "Webpage ID":"695040",
                              '"",""','","'),
                          '"":""','":"' ),
                        '""}"','"}' )
                      ,'"{""','{"' ),
                    v_patt, length(v_json_row));
      v_form_field :=  null;
      v_patt := instr(v_json_row, '"Form Fields":');
      if v_patt > 0 then
        v_form_field := substr(v_json_row, v_patt+14, length(v_json_row) - v_patt-15 ) ;
        v_json_row := substr(v_json_row, 1, v_patt) || '}';
      end if;

      insert into data_extract (file_id, campaign_run_id,client_ip_address,form_fields,query_parameters,referrer_url,user_agent,webform_id,webpage_id)
      select p_file_id, d.campaign_run_id, d.client_ip_address, v_form_field, d.query_parameters, d.referrer_url,d.user_agent, to_number(d.webpage_id), to_number(d.webform_id)
      from (
        with json_row as
          (select to_char(v_json_row) jrow from dual), seperate_rows as
            (select
              level rnum, regexp_substr(jrow,'({[^}]+?})',1,level) roww
             from json_row connect by regexp_substr(jrow,'({[^}]+?})',1,level) is not null
             ),
             fields (rnum, fn, val) as
              ( select
                  rnum,
                  1 fn,
                  trim('"' from trim( ':' from regexp_substr(roww,':"[^"]+?"',1, 1) )) val
                from seperate_rows
                union all
                select
                  f.rnum,
                  f.fn + 1,
                  trim('"' from trim( ':' from regexp_substr(roww,':"[^"]+?"',1, fn + 1) )) val
                from fields f, seperate_rows s
                where f.rnum = s.rnum
                  and trim('"' from trim( ':' from regexp_substr(roww,'"[^"]+?":',1, fn + 1) )) is not null)
        select *
        from fields pivot (max(val) for fn in
          (1 campaign_run_id,2 client_ip_address,3 query_parameters,4 referrer_url,5 user_agent,6 webpage_id,7 webform_id))
      ) d;

      --dbms_output.put_line(v_json_row);
      --dbms_output.put_line(v_form_field);
    end if;
  end loop;
  update json_files jf
    set jf.status = 1
  where jf.id = p_file_id
  and jf.status = 0;
end;
/

create or replace procedure upload_json_file (p_file in sys.scheduler_filewatcher_result)
is
  v_clob clob;
  v_bfile bfile;
  v_warning integer;
  v_dest_offset integer := 1;
  v_src_offset integer := 1;
  v_src_csid     NUMBER  := NLS_CHARSET_ID ('AL32UTF8');
  v_lang_context INTEGER := dbms_lob.default_lang_ctx;
  v_id number;
begin
  v_id := seq_json_files.nextval;
  insert into json_files (id, ins_date,file_name, file_date_time , file_size, file_cont)
                   values(v_id,
                          sysdate,
                          p_file.directory_path || '\' || p_file.actual_file_name,
                          p_file.file_timestamp,
                          --p_file.directory_path || '/' || p_file.actual_file_name, -- for linux
                          p_file.file_size,
                          empty_clob()
                        ) returning file_cont into v_clob;

  v_bfile := bfilename('JSON_FILES_DIR', p_file.actual_file_name);
  dbms_lob.fileopen(v_bfile);
  dbms_lob.loadclobfromfile (
    v_clob,
    v_bfile,
    dbms_lob.getlength(v_bfile),
    v_dest_offset,
    v_src_offset,
    v_src_csid,
    v_lang_context,
    v_warning
  );
  dbms_lob.fileclose(v_bfile);
  parse_json(v_id);
  commit;
end;
/



/*File Watcher*/
begin
  dbms_scheduler.create_credential(
     credential_name => 'watcher_credential',
     username        => 'OS User', -- oracle
     password        => 'OS USER PASSWORD'); -- oracle
end;
/

begin
  dbms_scheduler.create_program(
    program_name        => 'json_file_program',
    program_type        => 'stored_procedure',
    program_action      => 'upload_json_file',
    number_of_arguments => 1,
    enabled             => false);
  dbms_scheduler.define_metadata_argument(
    program_name        => 'json_file_program',
    metadata_attribute  => 'event_message',
    argument_position   => 1);
  dbms_scheduler.enable('json_file_program');
end;
/
 
begin
  dbms_scheduler.create_file_watcher(
    file_watcher_name => 'json_file_watcher',
    directory_path    => 'E:\files', -- '?/eod_reports',
    file_name         => '*', -- 'eod*.txt',
    credential_name   => 'watcher_credential',
    destination       => null,
    enabled           => false);
end;
/
 
begin
  dbms_scheduler.create_job(
    job_name        => 'json_file_job',
    program_name    => 'json_file_program',
    event_condition => 'tab.user_data.file_size > 10', --more than 10 byte
    queue_spec      => 'json_file_watcher',
    auto_drop       => false,
    enabled         => false);
  dbms_scheduler.set_attribute('json_file_job','parallel_instances',true);
end;
/
 
begin
  dbms_scheduler.enable('json_file_watcher,json_file_job');
end;
/

