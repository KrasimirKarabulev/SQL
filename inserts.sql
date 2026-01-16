
select * from bug_fix_deployment
where time_deployed = '2024-04-18 10:00:00';

select job, count(job) as job_count 
from workers 
where job ='Software Developer' 
group by job ;

select username as Admin, title as NameOfBug, bug_fix_deployment.code_fix as Fix, time_deployed as TimeOfDeployment
from users 
inner join bug_fix_deployment on users.id = bug_fix_deployment.admin_deployer_id
inner join fixes_todo_list on bug_fix_deployment.bug_id = fixes_todo_list.bug_id
inner join qa_bug_fix_inspection on fixes_todo_list.bug_id = qa_bug_fix_inspection.bug_id
inner join bugs on qa_bug_fix_inspection.bug_id = bugs.bug_id;
 
select * from workers 
left join developers on id = developers.worker_id;

-- select * from developers full join developer_bug on worker_id = developer_bug.developer_id;

 
-- select users.username as reporter_username, (select count(*) from user_bug_report where user_id = users.id) as num_bugs_reported, (select count(*) from developer_bug where developer_id = users.id) as num_bugs_fixed
-- FROM users 
-- WHERE users.userType = 'USER';

select bugs.bug_id, priority, title, fixes_todo_list.code_fix 
from bugs 
join fixes_todo_list on ( bugs.bug_id in 
( select bug_id 
from qa_bug_fix_inspection 
where bug_id in
(select bug_id 
from developer_bug 
where developer_bug.bug_id = fixes_todo_list.bug_id)));

select bugs.bug_id, priority, title, fixes_todo_list.code_fix 
from bugs 
join fixes_todo_list on bugs.bug_id in 
(select bug_id from qa_bug_fix_inspection 
where fixes_todo_list.bug_id = qa_bug_fix_inspection.bug_id);

select username as User, count(bug_id) as Bugs_Reported from user_bug_report
join users on user_bug_report.user_id = users.id
group by username
having Bugs_Reported > 1;


drop procedure if exists UpdateBugStatus ;
delimiter $
create procedure UpdateBugStatus(in bug_id_param varchar(40))
begin 
	declare done boolean default false;
	declare current_status enum('OPEN', 'RESOLVED', 'DECLINED', 'PLANNED');
    declare new_status enum('OPEN', 'RESOLVED', 'DECLINED', 'PLANNED');
    declare bug_id_var varchar(40);
    
    declare bug_cursor cursor for select bug_id from bugs where bug_id = bug_id_param;
    declare continue handler for not found set done = true;
    
    open bug_cursor;
    bug_loop:loop
    fetch bug_cursor into bug_id_var;
    if done
    then leave bug_loop;
    end if;
    
    select status into current_status from bugs where bug_id = bug_id_var;
	if current_status = 'OPEN'
    then set new_Status = 'RESOLVED';
    elseif current_status = 'PLANNED'
    then set new_status = 'OPEN';
    elseif  current_status = 'DECLINED'
    then set new_status = 'PLANNED';
    end if;
    
    update bugs set status = new_status where bug_id = bug_id_var;
    select concat('Bug ', bug_id_var , ' status updated from ', current_status, ' to ', new_status) as ' Status Update';
    end loop;
    close bug_cursor;
end $
delimiter ;

select * from bugs;
call UpdateBugStatus('Login3');
select * from bugs;


drop trigger if exists update_bug_log_trigger;
delimiter $
create trigger update_bug_log_trigger after insert on bug_fix_deployment
for each row
begin 
insert into bug_log(
bug_id, 
bug_title, 
bug_description,
date_fixed,
code_fix,
fixed_by_dev_id,
inspected_by_id,
found_by_id,
deployed_by_id)
values(new.bug_id, 
(select title from bugs where bug_id = new.bug_id), 
(select bug_description from bugs where bug_id = new.bug_id), 
(select time_deployed from bug_fix_deployment where bug_id = new.bug_id),
(select code_fix from bug_fix_deployment where bug_id = new.bug_id),
(select developer_id from developer_bug where bug_id = new.bug_id),
(select qa_id from qa_bug_fix_inspection where bug_id = new.bug_id and approved = 1),
(select admin_id from aj_recognised_bugs where bug_id = new.bug_id),
(select admin_deployer_id from bug_fix_deployment where bug_id = new.bug_id));
end $
delimiter ;

INSERT INTO bug_fix_deployment  VALUES 
('admin1', 3, 'Search20', 'https://github.com/project/Search20', '2024-04-20 10:30:00'),
('admin4', 11, 'Links40', 'https://github.com/project/Links40V2', '2024-04-20 13:30:00');
select * from bug_log;
