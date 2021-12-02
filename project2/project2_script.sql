/*  
SQL Schema for Project 2, COMS W4111 - Introduction to Databases
Dr. Alexandros Biliris, Section V03 (CVN)
Columbia University, Fall 2021

By : Cristopher Benge (cb3704@columbia.edu)
     Chisom Jachimike Amaluweze (jca2158@columbia.edu)
*/

drop table if exists Laboratory_audit;
drop table if exists Administrator_Composite;
drop table if exists Laboratory_with_array;
drop type if exists fullname;

create type fullname as (
    firstName text,
    lastName text);

create table Administrator_Composite (
	administratorId int not null generated always as identity,
	adminName fullname,
	primary key (administratorId));

create table Laboratory_with_array (
	laboratoryId int not null generated always as identity,
	safetyLevel int not null check (safetyLevel between 0 and 3),
	managingEntityId int not null,
	managedSinceDate date not null default CURRENT_DATE,
    inspectionSchedule text array[4],
    inspectionCertifications tsvector,
	primary key (laboratoryId),
	foreign key (managingEntityId) references ResearchEntity (entityId));

create table Laboratory_audit (
	laboratoryId int not null,
	safetyLevel int not null,
	managingEntityId int not null,
	managedSinceDate date not null,
    inspectionSchedule text array[4],
    inspectionCertifications tsvector,
    UserName name,
    AddedTime date);

create or replace function func_Laboratory_audit()
    returns trigger as
$$
begin
    insert into Laboratory_audit (laboratoryId, safetyLevel, managingEntityId, managedSinceDate, inspectionSchedule, inspectionCertifications, UserName, AddedTime)
        values(NEW.laboratoryId, NEW.safetyLevel, new.managingEntityId, NEW.managedSinceDate, NEW.inspectionSchedule, NEW.inspectionCertifications, current_user, current_date);

return new;
end;
$$
language 'plpgsql';

create trigger trg_insert_Laboratory
    after insert on Laboratory_with_array
    for each row
    execute procedure func_Laboratory_audit();


insert into Administrator_composite (adminName) 
values(row('Charles','Babbage')),
(row('Ada','Lovelace')),(row('Alan', 'Turing')),(row('Edgar', 'Codd')),
(row('Jim', 'Gray')),(row('Christopher','Date')),(row('Ralph', 'Kimball')),
(row('Bill', 'Inmon')),(row('Ken','Henderson')),(row('Larry','Ellison'));

insert  into Laboratory_with_array (safetyLevel, managingEntityId, managedSinceDate, inspectionSchedule, inspectionCertifications)
    select  floor(random() * 3) as safetyLevel, e.entityId, 
            (select now() - '1 years'::interval * round(random() * 2)) as managedSince,
            '{"January", "March", "June", "September" }', 'Safety1 Safety2 HazardousMaterials TentedPrograms HazMatApproved'
    from  ResearchEntity e;

