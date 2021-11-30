CREATE TYPE fullname AS (
    firstname TEXT,
    lastname TEXT
);

drop table Administrator_composite;

create table Administrator_composite (
	administratorId int not null generated always as identity,
	adminnname fullname
	primary key (administratorId));


insert into Administrator_composite (adminName) 
values (ROW('Charles','Babbage'));





drop table Laboratory_with_array;

create table Laboratory_with_array (
	laboratoryId int not null generated always as identity,
	safetyLevel int not null check (safetyLevel between 0 and 3),
	managingEntityId int not null,
	managedSinceDate date not null default CURRENT_DATE,
    inspectionschedule text ARRAY[4],
	primary key (laboratoryId),
	foreign key (managingEntityId) references ResearchEntity (entityId));


insert into Laboratory_with_array (safetyLevel, managingEntityId, managedSinceDate, inspectionschedule)
select floor(random() * 3) as safetyLevel, e.entityId, 
(select now() - '1 years'::interval * round(random() * 2)) as managedSince,
'{"January", "March", "June", "September" }'
from ResearchEntity e;



