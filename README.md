COMS W4111 - Introduction to Databases - Project 1 & 2
==========================================================
<img align="right" width="180" src="./images/cu_logo.jpg"/>

#### Project 1 & 2 for the Fall of 2021
#### Authors : [Cristopher Benge](https://cbenge509.github.io/) | [Chisom Amalunweze](https://www.linkedin.com/in/chisomamalunweze/)
<br><br><br><br>
Columbia University in the City of New York

Masters of Science in Computer Science - Machine Learning Concentration <br>
Section V03 - [Alexandros Biliris, PhD](http://www.cs.columbia.edu/~biliris/)

---

## Description

This repository contains the collaboration between Cris and Chisom for the Project 1, Part 3 assignment from the Fall 2021 course of *Introduction to Databases* (COMS W4111, section V03 (CVN)).  Part 3 of the project is focused on designing a [very] basic UI in Python 3.x to interact with the tables, execute a variety of SQL queries, etc.  All of the requirements are outlined fully in [the online rubric for this assignment](https://www.cs.columbia.edu/~biliris/4111/21f/projects/proj1-3/proj1-3.html).

---

## Submission Information

Below are the details requested in the submission guidelines for Project 1, Part 3.

| Submission Item | Details |
|:----------------|:--------|
| PostgreSQL account | cb3704 |
| Application URL | http://localhost:8111/ |
| Implementation description | Our application incorporates navigation of all key areas of our database, including logging in as an <b>Administrator</b> and reviewing and approving experiments, logging in as an <b>Inspector</b> and inspecting labs, as well as logging in as a <b>Facilitator</b> to review inspection details and investigate a reported incident.  Simple table views are provided to show the transational data for each of the key tables in our solution.  Please see the UML Activity Case Diagram below for details of actors and actions within our application.  |
| Two areas of interest | There are several areas of interest throughout our application, but two interesting items in our application is the (1) ability to create and report a new incident (such as a theft or spill of a select agent in a lab), and (2) the ability to both view and update the progress of your experiments on the same form.  These two actions constitute major parts of the actions taken by the key actor in our application, aka. the Researcher.  Please see the UML Activity Case Diagram below for details of actors and actions within our application. |

--- 

## Important Files

| File | Description |
|:-----|:------------|
| [create_tables.sql](./sql_scripts/create_tables.sql) | SQL script used to create the tables in a PostgreSQL database for Project 1, Part 2 (approved by TA) |
| [populate_date.sql](./sql_scripts/populate_data.sql) | SQL script used to populate simulated data for the tables in a PostgreSQL database for Project 1, Part 2 (approved by TA) |
| [secondary_actor_queries.sql](./sql_scripts/secondary_actor_queries.sql) | SQL script with example queries for each of the secondary actor functions depicted below in the use case diagram. |

---

## ER Diagram

A depiction of our database diagram is available below for reference:

<img src="./images/ERDiagram.png">

---

## Activity Case Diagram (UML)

Below is a high-level depiction of the primary (researcher) and secondary (administrator, inspector, facilitor) actors and their basic interaction points within our application.  For guidance on how to read / interpret an Activity Case diagram, please watch [this short video](https://www.youtube.com/watch?v=zid-MVo7M-E).

<img src="./images/CaseDiagram.png">

---

## Other Information 

A few important links for the course has been provided below:

 - [Official Syllabus](https://www.cs.columbia.edu/~biliris/4111/21f/)
 - [Ed Discussion Forum](https://edstem.org/us/courses/13950/discussion/) *(replaces Piazza)*
 - [Gradescope](https://www.gradescope.com/courses/313462) for submitting assignments.

---

## License
-------
Licensed under the MIT License. See [LICENSE](LICENSE) file for more details.
