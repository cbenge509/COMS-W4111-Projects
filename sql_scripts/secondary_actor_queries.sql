-- As an adiministrator, I review experiments that are in the 'initiated' status and moved them EITHER to 'cancelled' (NOT APPROVED) or 'in-progress' (APPROVED)
-- return the list of experiments that have been initiated and which agents they propose to work on

-- action: the adiministrator actor would update the status of these to either 'in-porogress' or 'cancelled'

select  e.experimentId, b.agentName, b.strainName, b.category, eb.agentQuantity, eb.agentUnitOfMeasure
  from  Experiment e
        join Experiment_BioAgent eb on e.experimentId = eb.experimentId
        join BioAgent b on eb.agentId = b.agentId
 where  e.experimentStatus = 'initiated'
 order  by e.experimentId, b.agentName, b.strainName

 
 -- As an inspector, I perform on-site laboratory inspections that are either scheduled or surprise and doucment the inspection summary
 -- I would only want to view the list of laboratories that have not had a SUCCESSFUL inspection in at least the last 12 months of type AD-HOC or ROUTINE

-- I would need to insert a record here for either a AD-HOC or ROUTINE inspection

with ins as (
    select  li.laboratoryId, max(li.scheduledDate) as scheduleDate
      from  laboratoryInspection li
     where  li.inspectionType in ('ad-hoc', 'routine')
       and  li.inspectionOutcome = 'successful'
     group  by li.laboratoryId
    having  max(li.scheduledDate) >= (now() - INTERVAL '1 YEAR')
)

select  l.laboratoryId, l.safetyLevel, e.entityName, e.contactFirstName, e.contactLastName, e.contactPhoneNumber, e.contactEmailAddress
  from  Laboratory l
        join ins on l.laboratoryId = ins.laboratoryId
        join ResearchEntity e on l.managingEntityId = e.entityId 
        
-- As a facilitary, I review completed inspections that have not yet been reviewed
-- NOTE: our generated data does not have any inspections not yet reviewed; you would need to insert new ones 
-- or update existing ones to not yet have an inspection.  Also, I did not generate any "inspection Notes" but you 
-- will want to see these notes if you are a "reviewer".  To flag an inspection row as having been "reviewed", simply
-- update the row with the ID of the facilitator performing the review (from the Facilitator table)

select  l.laboratoryId, l.safetyLevel, e.entityName, li.scheduledDate, li.inspectionType, li.inspectionOutcome, li.inspectionNotes
  from  LaboratoryInspection li
        join Laboratory l on li.laboratoryId = l.laboratoryId
        join ResearchEntity e on l.managingEntityId = e.entityId
 where  li.inspectionOutcome is not null
   and  li.reviewedByFacilitatorId is null

-- as a faciltator, I need to review reported incidents (theft, loss, spill)
-- to update this, you would set an investigatedByFacilitatoryId and set the investigation open date
-- when an investigation is done, the facilitator would come back and mark the status and 'closed' and set the closed date accordingly

select  l.laboratoryId, e.entityName, i.incidentReportedDate, i.incidentOccurredDate, i.threatLevel, i.incidentType, i.incidentSummary,
        i.investigationOpenDate, i.investigationClosedDate, i.investigatedByFacilitatorId
  from  Incident i
        join Laboratory l on i.laboratoryId = l.laboratoryId
        join ResearchEntity e on l.managingEntityId = e.entityId
 where  coalesce(i.investigationStatus, 'open') = 'open'
