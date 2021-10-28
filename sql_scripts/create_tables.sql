/*  
SQL Schema for Project 1.2, COMS W4111 - Introduction to Databases
Dr. Alexandros Biliris, Section V03 (CVN)
Columbia University, Fall 2021

By : Cristopher Benge (cb3704@columbia.edu)
     Chisom Jachimike Amaluweze (jca2158@columbia.edu)
*/

drop table if exists Incident;
drop table if exists LaboratoryInspection;
drop table if exists Laboratory;
drop table if exists Experiment_BioAgent;
drop table if exists Experiment;
drop table if exists ResearchEntity;
drop table if exists BioAgent;
drop table if exists Facilitator;
drop table if exists Inspector;
drop table if exists Administrator;

create table Administrator (
	administratorId int not null generated always as identity,
	adminFirstName varchar(40) not null,
	adminLastName varchar(40) not null,
	primary key (administratorId));

create table Inspector (
	inspectorId int not null generated always as identity,
	inspectorFirstName varchar(40) not null,
	inspectorLastName varchar(40) not null,
	primary key (inspectorId));


create table Facilitator (
	facilitatorId int not null generated always as identity,
	facilitatorFirstName varchar(40) not null,
	facilitatorLastName varchar(40) not null,
	primary key (facilitatorId));

create table BioAgent (
	agentId int not null generated always as identity,
	agentName varchar(50) unique not null,
	strainName varchar(100) null,
	category varchar(20) not null check (
		category in ('plant', 'haemorrhagic','tick-borne','other')),
	primary key (agentid));

create table ResearchEntity (
	entityId int not null generated always as identity,
	entityName varchar(50) unique not null,
	contactFirstName varchar(40) null,
	contactLastName varchar(40) null,
	contactPhoneNumber varchar(20) null,
	contactEmailAddress varchar(30) null,
	approvedByAdministratorId int not null,
	approvedByDate date not null default CURRENT_DATE,
	primary key (entityId),
	foreign key (approvedByAdministratorId) 
		references Administrator (administratorId));

create table Experiment (
	experimentId int not null generated always as identity,
	entityId int not null,
	experimentStatus varchar(20) not null check (
		experimentStatus in ('design', 'initiated', 'in-progress', 
		'closed', 'cancelled', 'on-hold')),
	experimentStartDate date not null default CURRENT_DATE,
	experimentClosedDate date null,
	primary key (experimentId),
	foreign key (entityId) references ResearchEntity (entityId));

alter table Experiment add constraint CK_Experiment_Dates check (
experimentStartDate < experimentClosedDate OR experimentClosedDate is null);

create table Experiment_BioAgent (
	experimentId int not null,
	agentId int not null,
	agentQuantity decimal (20,5) not null check (agentQuantity >= 0.0),
	agentUnitOfMeasure varchar(5) not null check (
		agentUnitOfMeasure in ('oz', 'l', 'ml', 'mL', 'L', 'kg', 'mg', 'Mg')),
	primary key (experimentId, agentId),
	foreign key (experimentId) references Experiment (experimentId),
	foreign key (agentId) references BioAgent (agentId));


create table Laboratory (
	laboratoryId int not null generated always as identity,
	safetyLevel int not null check (safetyLevel between 0 and 3),
	managingEntityId int not null,
	managedSinceDate date not null default CURRENT_DATE,
	primary key (laboratoryId),
	foreign key (managingEntityId) references ResearchEntity (entityId));

create table LaboratoryInspection (
	laboratoryId int not null,
	inspectorId int not null,
	scheduledDate date not null,
	inspectionType varchar(30) not null check (
	inspectionType in ('routine', 'incident-based', 'ad-hoc')),
	inspectionOutcome varchar(20) null check (
		inspectionOutcome in ('failed', 'successful', 'inconclusive')),
	inspectionNotes text null,
	reviewedByFacilitatorId int null,
	primary key (laboratoryId, inspectorId, scheduledDate),
	foreign key (laboratoryId) references Laboratory (laboratoryId),
	foreign key (inspectorId) references Inspector (inspectorId),
	foreign key (reviewedByFacilitatorId) 
		references Facilitator (facilitatorId));

create table Incident (
	incidentId int not null generated always as identity,
	laboratoryId int not null,
	incidentReportedDate date not null default CURRENT_DATE,
	incidentOccurredDate date not null default CURRENT_DATE,
	threatLevel int not null check (
	threatLevel between 1 and 5),
	incidentType varchar(5) not null check (
		incidentType in ('theft', 'spill', 'loss', 'other')),
	incidentSummary text not null,
	investigatedByFacilitatorId int null,
	investigationStatus varchar(10) not null check (
		investigationStatus in ('open', 'closed')) default ('open'),
	investigationOpenDate date not null default CURRENT_DATE,
	investigationClosedDate date null,
	primary key (incidentId),
	foreign key (laboratoryId) references Laboratory (laboratoryId),
	foreign key (investigatedByFacilitatorId) 
		references Facilitator (facilitatorId));