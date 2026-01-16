drop database if exists bug_tracker;
create database bug_tracker;
use bug_tracker;

create table users( -- some user accounts are admin accounts
id int auto_increment primary key,
username varchar(25) not null unique,
password varchar(25) not null,
name varchar(50) not null,
phone char(10) not null,
email varchar(25) not null unique,
userType enum ('USER', 'ADMIN'));


create table workers( -- all workers are employed in the company
id int auto_increment primary key,
job varchar(255) not null,
salary float not null,
language varchar(25) not null,
date_of_employment date not null
);


create table developers( -- not all workers are devs
worker_id int not NULL,
name varchar(255),
level enum('Junior', 'Mid-Level', 'Senior'),
constraint foreign key(worker_id) references workers(id),
primary key(worker_id));
  
create table qualityAssurances( -- not all workers are QA
  worker_id int not NULL,
  name varchar(25) not null,
  constraint foreign key(worker_id) references workers(id),
  primary key(worker_id));
  
create table user_bug_report(
user_id int not null,
bug_id int primary key auto_increment not null, -- serialised, expecting spam of bogus bugs
description text not null,
constraint foreign key(user_id) references users(id));
  
create table admin_judge(
admin_id int,
  -- admin_type_check enum('ADMIN'), -- PREVENTS WRONG INSERTS
bug_id int,
bug_user_description varchar(255),
admin_username varchar(100),
decision enum('Known bug','Send to devs(unknown)', 'Ignored'), -- known, ignored and fixed don't go to bugs in practice
primary key(admin_id, bug_id),
foreign key (admin_id) references users(id),
  -- foreign key (admin_type_check) references users(userType),
  foreign key (bug_id) references user_bug_report(bug_id));
 -- foreign key (bug_user_description) references user_bug(description));
  
create table aj_recognised_bugs( 
admin_id int not null,
bug_id varchar(40) not null, -- smth like logneg3034, this is the id the team works with
title varchar(50) not null,
bug_desc varchar(256), -- better description can be given by the admin here. it may be a link or a file path
foreign key (admin_id) references admin_judge(admin_id),
primary key (bug_id, title, bug_desc));
  
create table bugs( -- ppc ne se dava pulen dostup do db na nikoi. na edin chovek mu se dava samo tova koeto si precenil che mu trqbva.
bug_id varchar(40), -- known id
title varchar(50) not null,
bug_description varchar(256) not null,
priority enum('LOW', 'MEDIUM', 'HIGH') not null default 'LOW',
expected_hours time not null,
status enum('OPEN', 'RESOLVED', 'DECLINED', 'PLANNED') NOT NULL DEFAULT 'OPEN',
foreign key (bug_id, title, bug_description) references aj_recognised_bugs(bug_id, title, bug_desc)); 

create table developer_bug( -- not all developers are busy working on bugs
developer_id int not null,
bug_id varchar(40) not null,
progress int not null default 0,
constraint foreign key(developer_id) references developers(worker_id),
constraint foreign key(bug_id) references bugs(bug_id));

create table qa_bug_fix_inspection(
qa_id int not null,
bug_id varchar(40) not null,
code_fix varchar(256) not null, -- this is a link to a code repo/file path
approved boolean default false, 
constraint foreign key(qa_id) references qualityAssurances(worker_id),
constraint foreign key(bug_id) references bugs(bug_id),
primary key(bug_id, code_fix)); -- sustaven kliuch

create table fixes_todo_list( -- mby the admins aren't online 24/7
code_fix varchar(256) not null, -- change this while testing to make it easier to test.
bug_id varchar(40) not null,
approved boolean default null,
foreign key (bug_id, code_fix) references qa_bug_fix_inspection(bug_id, code_fix));

create table bug_fix_deployment( -- mby u can make a procedure or trigger smth that makes sure that only bugs_ids which are approved = true can be here,
								 -- or switch approved to enum and use the trick i did for admin checking
admin_deployer_username varchar(100) not null,
admin_deployer_id int not null,
bug_id varchar(40) not null,
code_fix varchar(256) not null,
time_deployed datetime,
foreign key (admin_deployer_username) references users(username),
foreign key (admin_deployer_id) references users(id),
foreign key (bug_id, code_fix) references fixes_todo_list(bug_id, code_fix));

create table bug_log( -- bugs which have been fixed and their details. ppl should check this so as to not deploy the same fix twice. the ui can make sure ppl dont attempt
						-- deploying the same bugfix twice, or smth else. also useful for checking who gets paid extra hehehe oshte tablici.
log_id int primary key auto_increment,
bug_id varchar(40), -- btw i think it's weird that the id can be longer than the title.
bug_title varchar(50),
bug_description varchar(256),
date_fixed datetime,
code_fix varchar(256),
fixed_by_dev_id int,
inspected_by_id int,
found_by_id int,
deployed_by_id int,
foreign key (bug_id, bug_title, bug_description) references bugs(bug_id, title, bug_description),
-- foreign key (bug_title) references aj_recognised_bugs(title),
-- foreign key (bug_description) references bugs(bug_description),
foreign key (bug_id, code_fix) references bug_fix_deployment(bug_id, code_fix), 
foreign key (fixed_by_dev_id) references developer_bug(developer_id),
foreign key (inspected_by_id) references qa_bug_fix_inspection(qa_id),
foreign key (found_by_id) references admin_judge(admin_id),
foreign key (deployed_by_id) references bug_fix_deployment(admin_deployer_id)
);	-- this table basically crosses the work force related to bugs with the part of the company which checks who to pay extra, and let's ppl reference their previous work					


-- Заявки за таблица "users":
INSERT INTO users VALUES
(null,'user1', 'pass1', 'John Doe', '1234567890', 'john@example.com', 'USER'),
(null, 'user2', 'pass2', 'Jane Smith', '9876543210', 'jane@example.com', 'USER'),
(null, 'admin1', 'adminpass1', 'Admin One', '5555555555', 'admin1@example.com', 'ADMIN'),
(null, 'user3', 'pass3', 'Michael Johnson', '3333333333', 'michael@example.com', 'USER'),
(null, 'admin2', 'adminpass2', 'Admin Two', '4444444444', 'admin2@example.com', 'ADMIN'),
(null,'user4', 'pass4', 'Emily Brown', '6666666666', 'emily@example.com', 'USER'),

(null, 'user5', 'pass5', 'Alex Johnson', '5551234567', 'alex@example.com', 'USER'),
(null, 'user6', 'pass6', 'Sophia Martinez', '6662345678', 'sophia@example.com', 'USER'),
(null, 'admin3', 'adminpass3', 'Admin Three', '7773456789', 'admin3@example.com', 'ADMIN'),
(null, 'user7', 'pass7', 'Daniel Lee', '8884567890', 'daniel@example.com', 'USER'),
(null, 'admin4', 'adminpass4', 'Admin Four', '9995678901', 'admin4@example.com', 'ADMIN');

-- Заявки за таблица "workers":
INSERT INTO workers VALUES 
(null, 'Software Developer', 5000.00, 'Spanish', '2023-01-15'),
(null, 'Quality Assurance', 4500.00, 'Dutch', '2022-12-01'), 
(null,'Project Manager', 6000.00, 'English', '2023-02-28'),
(null,'Software Developer', 5500.00, 'Spanish', '2023-03-10'),
(null,'Quality Assurance', 4200.00, 'English', '2022-11-15'),
(null,'UI/UX Designer', 5200.00, 'Dutch', '2023-04-20'),

(null, 'Software Developer', 5200.00, 'German', '2023-05-15'),
(null, 'Quality Assurance', 4800.00, 'French', '2023-01-01'),
(null, 'Project Manager', 6500.00, 'Italian', '2023-03-01'),
(null, 'Software Developer', 5800.00, 'German', '2023-04-10'),
(null, 'Quality Assurance', 4300.00, 'French', '2022-12-15');

INSERT INTO developers VALUES 
(1, 'Dev One', 'Junior'),
(4, 'Dev Two', 'Senior'),

(7, 'Dev Three', 'Mid-Level'),
(10, 'Dev Four', 'Senior');

INSERT INTO qualityAssurances VALUES
(2, 'QA One'),
(5, 'QA Two'),

(8, 'QA Three'),
(11, 'QA Four');

INSERT INTO user_bug_report VALUES 
(1, null, 'Encountered an error while trying to log in.'),
(2, null,'Application crashes when clicking on the "Settings" button.'),
(4, null,'Images not loading on the homepage.'),
(6, null,'Search functionality not returning results.'),

(7, null, 'Unable to reset password on the login page.'),
(8, null,'404 error when accessing certain pages.'),
(10, null,'Slow loading times for images.'),
(1, null,'Invalid search results returned.'),
(2, null,'Application crashes randomly.');

-- админите разполагат с техен user interface, който им помага да препращат тази информация, която се създава в admin_judge. Конректно дали се препращат нататъка.
INSERT INTO admin_judge  VALUES 
(3, 1, 'Encountered an error while trying to log in.', 'admin1', 'Send to devs(unknown)'),
(3, 2, 'Application crashes when clicking on the "Settings" button.', 'admin1', 'Known bug'),
(5, 3, 'Unable to submit form data on the website.', 'admin2', 'Send to devs(unknown)'),
(5, 4, 'Images not loading on the homepage.', 'admin2', 'Ignored'),

(9, 5, 'Slow loading times for images.', 'admin3', 'Known bug'),
(9, 6, 'Invalid search results returned.', 'admin3', 'Send to devs(unknown)'),
(11, 7, 'Application crashes randomly.', 'admin4', 'Ignored'),
(11, 8, 'Broken links on the contact page.', 'admin4', 'Send to devs(unknown)'),
(3, 9, 'Error message displayed incorrectly.', 'admin1', 'Send to devs(unknown)');



INSERT INTO aj_recognised_bugs VALUES 
(3, 'Login3', 'Login Error', 'The login form is not functioning correctly.'),
(5, 'Submission50', 'Form Submission Issue', 'Users are unable to submit form data on the website.'),


(9, 'Search20', 'Search Functionality Error', 'Invalid search results are being returned.'),
(11, 'Links40', 'Broken Links', 'Some links on the contact page are broken.'),
(3, 'Error50', 'Error Message Display', 'Error messages are not displayed correctly.');

-- Заявки за таблица "bugs":
INSERT INTO bugs  VALUES
('Login3', 'Login Error', 'The login form is not functioning correctly.', 'HIGH', '02:00:00', 'OPEN'),
('Submission50', 'Form Submission Issue', 'Users are unable to submit form data on the website.', 'LOW', '01:30:00', 'OPEN'),

('Search20', 'Search Functionality Error', 'Invalid search results are being returned.', 'HIGH', '02:30:00', 'OPEN'),
('Links40', 'Broken Links', 'Some links on the contact page are broken.', 'LOW', '01:00:00', 'OPEN'),
('Error50', 'Error Message Display', 'Error messages are not displayed correctly.', 'MEDIUM', '02:00:00', 'DECLINED');


INSERT INTO developer_bug VALUES 
(1, 'Login3', 20),
(4, 'Submission50', 10),


(7, 'Search20', 15),
(10, 'Links40', 10);


-- Заявки за таблица "qa_bug_fix_inspection":
INSERT INTO qa_bug_fix_inspection  VALUES 
(2, 'Login3', 'https://github.com/project/Login3', true),
(5, 'Submission50', 'https://github.com/project/Submission50', true),

(8, 'Search20', 'https://github.com/project/Search20', true),
(11, 'Links40', 'https://github.com/project/Links40', false),
(11, 'Links40', 'https://github.com/project/Links40V2', true);


-- Заявки за таблица "fixes_todo_list":
INSERT INTO fixes_todo_list  VALUES 
('https://github.com/project/Login3', 'Login3', true),
('https://github.com/project/Submission50', 'Submission50', true),

('https://github.com/project/Search20', 'Search20', true),
('https://github.com/project/Links40V2', 'Links40', true);


-- Заявки за таблица "bug_fix_deployment":
INSERT INTO bug_fix_deployment  VALUES 
('admin1', 3, 'Login3', 'https://github.com/project/Login3', '2024-04-18 10:00:00'),
('admin2', 5, 'Submission50', 'https://github.com/project/Submission50', '2024-04-18 11:30:00'),


('admin1', 9, 'Search20', 'https://github.com/project/Search20', '2024-04-20 10:30:00'),
('admin4', 11, 'Links40', 'https://github.com/project/Links40V2', '2024-04-20 13:30:00');



-- Заявки за таблица "bug_log":
INSERT INTO bug_log VALUES 
(null,'Login3', 'Login Error', 'The login form is not functioning correctly.', '2024-04-18 10:30:00', 'https://github.com/project/Login3', 1, 2, 3, 3),
(null,'Submission50', 'Form Submission Issue', 'Users are unable to submit form data on the website.', '2024-04-18 12:00:00', 'https://github.com/project/Submission50', 4, 5, 5, 5),


(null, 'Search20', 'Search Functionality Error', 'Invalid search results are being returned.', '2024-04-20 11:00:00', 'https://github.com/project/Search20', 7, 8, 9, 3),
(null, 'Links40', 'Broken Links', 'Some links on the contact page are broken.', '2024-04-20 14:00:00', 'https://github.com/project/Links40V2', 10, 11, 11, 11);


SELECT * FROM users;
SELECT * FROM workers;
SELECT * FROM developers;
SELECT * FROM qualityassurances;
SELECT * FROM user_bug_report;
SELECT * FROM admin_judge;
SELECT * FROM aj_recognised_bugs;
SELECT * FROM bugs;
select * from developer_bug;
select * from qa_bug_fix_inspection;
select * from fixes_todo_list;
select * from bug_fix_deployment;
select * from bug_log;

