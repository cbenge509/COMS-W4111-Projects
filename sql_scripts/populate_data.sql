-- Populate the [Administrator] table with 10 fixed names
insert into Administrator (adminFirstName, adminLastName) 
values('Charles','Babbage'),
('Ada','Lovelace'),('Alan', 'Turing'),('Edgar', 'Codd'),
('Jim', 'Gray'),('Christopher','Date'),('Ralph', 'Kimball'),
('Bill', 'Inmon'),('Ken','Henderson'),('Larry','Ellison');

-- Populate the [Inspector] table with 10 fixed names
insert into Inspector (inspectorFirstName, inspectorLastName) 
values('Isaac', 'Asimov'),
('JD', 'Salinger'),('Telly', 'Savalas'),('Gene', 'Roddenberry'),
('Sandy', 'Koufax'),('Pat', 'Boone'),('Barack', 'Obama'),
('Julia', 'Stiles'),('Alicia', 'Keys'),('Amelia', 'Earhart');

-- Populate the [Facilitator] table with 10 fixed names
insert into Facilitator (facilitatorFirstName, facilitatorLastName) 
values('Claude', 'Monet'),
('Pierre-Aguste', 'Renoir'),('Vincent', 'van Gogh'),('Edgar', 'Degas'),
('Edouard', 'Manet'),('Paul', 'Cezanne'),('Mary', 'Cassatt'),
('Alfred', 'Sisley'),('Henri', 'Matisse'),('Aguste', 'Rodin');

-- Populate the [BioAgent] table with 10 random values from the 
-- U.S. Department of Health and Human Services official list
insert into BioAgent(agentName, strainName, category) 
values('Ricin', null, 'other'),('Ebola virus', 'West African', 'other'),
('encephalitis (flavi)', 'Siberian', 'tick-borne'),
('encephalitis', 'far eastern', 'tick-borne'),
('Bacillus anthracis', null, 'other'),
('Bacillus antrhacis (O)', 'Pasteur', 'other'),
('Chapare (H.fever)', 'South American', 'haemorrhagic'),
('Goat pox virus', null, 'other'),
('Swine vesicular', null, 'other'),
('Rathayibacter toxicus', null, 'plant');

-- Populate the [ResearchEntity] table
insert into ResearchEntity (entityName, contactFirstName, 
contactLastName, contactPhoneNumber, contactEmailAddress, 
approvedByAdministratorId, approvedByDate)
values('The University of Chicago','Paul','Williams','773-702-1234',
	'researchsafety@uchicago.edu', 1, '12/28/2006'),
('The University of Texas at Austin','Mary','Curie','512-471-8871',
	'irb@austin.utexas.edu', 4, '09/27/2016'),
('University of Massachusetts Amherst','Mark','Knoffler','413-545-0111',
	'rescomp@research.umass.edu', 3, '08/02/1999'),
('University of South Carolina','Paul','Rogers','803-777-5269',
	'tsyfert@mailbox.sc.edu', 5, '09/30/2006'),
('University of Colorado Denver','Cindi','Mcilvaine','303-315-5183',
	'clas@ucdenver.edu', 5, '07/16/2020'),
('University of Iowa','Robert','Bruns','319-335-8501',
	'ehs-contact@uiowa.edu', 10, '11/22/1996'),
('Cornell University','Linda','Wilseng','607-255-8200',
	'askehs@cornell.edu', 2, '05/28/2009'),
('Colorado State University','Andrew','Fogarty','970-491-6444',
	'csurams@colostate.edu', 5, '06/01/2021'),
('University of Pennsylvania','Siduo','Jiang','215-898-6236',
	'andrew.maksym@upenn.edu', 3, '01/01/2019'),
('Drexel University','Malvika','Bhatia','215-895-2000',
	'safeheal@drexel.edu', 3, '04/02/2001');

-- create closed experiments
with params as (select 1 as min_id, 10 as id_span),
p2 as (select p.min_id + trunc(random() * p.id_span)::integer as id
from params p, generate_series(1, 15) g group by 1)
insert into Experiment (entityId, experimentStatus, 
experimentStartDate, experimentClosedDate)
select p2.id as entityId, 'closed' as experimentStatus, 
(select now() - '1 year'::interval * round(random() * 100)) as experimentStartDate,
(select now() - '10 days'::interval * round(random() * 100)) as experimentEndDate
from p2;

-- create design experiments
with params as (select 1 as min_id, 10 as id_span),
p2 as (select p.min_id + trunc(random() * p.id_span)::integer as id
from params p, generate_series(1, 15) g group by 1)
insert into Experiment (entityId, experimentStatus, 
experimentStartDate, experimentClosedDate)
select p2.id as entityId, 'design' as experimentStatus, 
(select now() - '2 days'::interval * round(random() * 100)) as experimentStartDate,
null as experimentEndDate
from p2;

-- create in-progress experiments
with params as (select 1 as min_id, 10 as id_span),
p2 as (select p.min_id + trunc(random() * p.id_span)::integer as id
from params p, generate_series(1, 15) g group by 1)
insert into Experiment (entityId, experimentStatus, 
experimentStartDate, experimentClosedDate)
select p2.id as entityId, 'in-progress' as experimentStatus, 
(select now() + '30 days'::interval * round(random() * 100)) as experimentStartDate,
(select now() + '1 year'::interval * round(random() * 100)) as experimentEndDate
from p2;

-- create initiated experiments
with params as (select 1 as min_id, 10 as id_span),
p2 as (select p.min_id + trunc(random() * p.id_span)::integer as id
from params p, generate_series(1, 15) g group by 1)
insert into Experiment (entityId, experimentStatus, 
experimentStartDate, experimentClosedDate)
select p2.id as entityId, 'initiated' as experimentStatus, 
(select now() + '1 day'::interval * round(random() * 100)) as experimentStartDate,
null as experimentEndDate
from p2;

-- populate the [Experiment_BioAgent] values
with c as (select e.experimentId, a.agentId from Experiment e cross join BioAgent a)
insert into Experiment_BioAgent (experimentId, agentId, agentUnitOfMeasure, 
agentQuantity) select c.experimentId, c.agentId, 
(select(array['oz','l','ml','mL','L','kg','mg','Mg'])[floor(random() * 8 + 1)])
as agentUnitOfMeasure, (random() * 100)::decimal(20,5) as agentQuantity
from c order by random() limit 100;

-- randomize the unit of measure for all 100 rows
update Experiment_BioAgent set agentUnitOfMeasure = 
(array['oz','l','ml','mL','L','kg','mg','Mg'])[floor(random() * 8 + 1)];

-- populate the [Laboratory] table
insert into Laboratory (safetyLevel, managingEntityId, managedSinceDate)
select floor(random() * 3) as safetyLevel, e.entityId, 
(select now() - '1 years'::interval * round(random() * 2)) as managedSince
from ResearchEntity e;

-- initialize [Inspection] table with base values
with c as (select l.laboratoryId, i.inspectorId 
from Laboratory l cross join Inspector i)
insert into LaboratoryInspection (laboratoryId, inspectorId, 
scheduledDate, inspectionType, inspectionOutcome, 
reviewedByFacilitatorId)
select c.laboratoryId, c.inspectorId, now() as scheduledDate, 
'routine' as inspectionType, 'inconclusive' as inspectionOutcome, 
floor(random() * 10 + 1) as reviewedByFacilitatorId
from c order by random() limit 50;

-- randomize scheduled dates
update LaboratoryInspection
set scheduledDate = now() - '1 day'::interval * round(random() * 600);

-- randomize the inspection types
update LaboratoryInspection
set inspectionType = 
(array['routine','incident-based','ad-hoc'])[floor(random() * 3 + 1)];

-- randomize the inspection outcomes
update LaboratoryInspection
set inspectionOutcome = 
(array['failed','successful','inconclusive'])[floor(random() * 3 + 1)];

-- randomize the reviewed by facilitators
update LaboratoryInspection
set reviewedByFacilitatorId = floor(random() * 10 + 1);

-- Initialize the [Incident] table
with i as (select laboratoryId, scheduledDate from LaboratoryInspection 
where inspectionType = 'incident-based')
insert into Incident (laboratoryId, incidentReportedDate, 
incidentOccurredDate, threatLevel, incidentType,
incidentSummary, investigatedByFacilitatorId, investigationStatus)
select i.laboratoryId, 
i.scheduledDate - '1 day'::interval * round(random() * 10) as incidentReportedDate,
now() as incidentOccurredDate, 1 as threatLevel, 'theft' as incidentType, 
'laboratory incident' as incidentSummary, 1 as investigatedByFacilitatorId, 
'open' as investigationStatus from i;

-- update the occurred date
update Incident set incidentOccurredDate = 
incidentReportedDate - '1 day'::interval * round(random() * 3 + 1);

-- add constraint to ensure the incident is reported AFTER it occurrs
alter table Incident add constraint 
CK_Incident_OccurredDate check (incidentOccurredDate < incidentReportedDate);

-- randomize the threatlevel
update Incident
set threatLevel = floor(random() * 5 + 1);

-- randomize the incident type
update Incident set incidentType = 
(array['theft','spill','loss','other'])[floor(random() * 4 + 1)];

-- randomize the facilitator who investigated the incident
update Incident
set investigatedByFacilitatorId = floor(random() * 10 + 1);

-- randomize the investigation status
update Incident set investigationStatus = 
(array['open','closed'])[floor(random() * 2 + 1)];

-- update the investigation open date
update Incident set investigationOpenDate = 
incidentReportedDate + '1 day'::interval * round(random() * 3 + 1);

-- add constraint to ensure the incident reported comes later
alter table Incident add constraint CK_Incident_InvestigationDate 
check (investigationOpenDate > incidentReportedDate);

-- set the closed date to some random time after the open date 
-- if the status is CLOSED
update Incident set investigationClosedDate = 
investigationOpenDate + '1 day'::interval * round(random() * 30 + 1)
where investigationStatus = 'closed';