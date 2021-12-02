/*  
SQL Schema for Project 2, COMS W4111 - Introduction to Databases
Dr. Alexandros Biliris, Section V03 (CVN)
Columbia University, Fall 2021

By : Cristopher Benge (cb3704@columbia.edu)
     Chisom Jachimike Amaluweze (jca2158@columbia.edu)
*/

--- *******************************************
--- CREATE TABLES, FUNCTIONS, TRIGGERS
--- *******************************************

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

--- *******************************************
--- Insert New Data
--- *******************************************

insert into Administrator_composite (adminName) 
values(row('Charles','Babbage')),
(row('Ada','Lovelace')),(row('Alan', 'Turing')),(row('Edgar', 'Codd')),
(row('Jim', 'Gray')),(row('Christopher','Date')),(row('Ralph', 'Kimball')),
(row('Bill', 'Inmon')),(row('Ken','Henderson')),(row('Larry','Ellison'));

insert  into Laboratory_with_array (safetyLevel, managingEntityId, managedSinceDate, inspectionSchedule, inspectionCertifications)
    select  floor(random() * 3) as safetyLevel, e.entityId, 
            (select now() - '1 years'::interval * round(random() * 2)) as managedSince,
            '{"January", "March", "June", "September" }', to_tsvector('Safety1 Safety2 HazardousMaterials TentedPrograms HazMatApproved')
    from  ResearchEntity e;

--- *******************************************
--- Three Meaningful Queries
--- *******************************************

 -- As an inspector, I perform on-site laboratory inspections that are either scheduled or surprise and doucment the inspection summary
 -- I would only want to view the list of laboratories that have not had a SUCCESSFUL inspection in at least the last 12 months of type AD-HOC or ROUTINE
 -- and limit the list to only those labotatories that are scheduled to be operating in September (ARRAY searching)
 -- NOTE: use of the ARRAY data type in filtering.

with ins as (
    select  li.laboratoryId, max(li.scheduledDate) as scheduleDate
      from  laboratoryInspection li
     where  li.inspectionType in ('ad-hoc', 'routine')
       and  li.inspectionOutcome = 'successful'
     group  by li.laboratoryId
    having  max(li.scheduledDate) >= (now() - INTERVAL '1 YEAR')
)

select  l.laboratoryId, l.safetyLevel, e.entityName, e.contactFirstName, e.contactLastName, e.contactPhoneNumber, 
        e.contactEmailAddress
  from  Laboratory_with_array l
        join ins on l.laboratoryId = ins.laboratoryId
        join ResearchEntity e on l.managingEntityId = e.entityId 
 where  'September' = any (l.inspectionSchedule);

 -- as a faciltator, I need to review reported incidents (theft, loss, spill)
 -- but I want to review reports only from those labs that are certified to handle Safety level 1 AND hazardous materials.
 -- NOTE: use of text search of document data type via tsvector and to_tsquery syntax.

select  l.laboratoryId, e.entityName, i.incidentReportedDate, i.incidentOccurredDate, i.threatLevel, i.incidentType, i.incidentSummary,
        i.investigationOpenDate, i.investigationClosedDate, i.investigatedByFacilitatorId
  from  Incident i
        join Laboratory_with_array l on i.laboratoryId = l.laboratoryId
        join ResearchEntity e on l.managingEntityId = e.entityId
 where  coalesce(i.investigationStatus, 'open') = 'open'
   and  l.inspectionCertifications @@ to_tsquery('HazardousMaterials & Safety1')

-- as an administrator with the last name of 'Turing', I would like to see all of the experiments from the
-- research universities that I have approved in the system, and sort the experiments by the start date
-- of the experiment (ascending order).
-- NOTE: use of filtering by the custom type [implemented in Project 2] in the WHERE clause.

select  re.entityName, a.adminName, e.experimentStatus, e.experimentStartDate, e.experimentClosedDate
  from  ResearchEntity re
        join Administrator_composite a on re.approvedByAdministratorId = a.administratorId
        join Experiment e on re.entityId = e.entityId
 where  (adminName).lastName = 'Turing'
 order  by experimentStartDate asc;

