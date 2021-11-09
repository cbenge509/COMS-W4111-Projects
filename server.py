#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Oct 29 22:11:02 2021

@author: jachimikeamalunweze
"""

#!/usr/bin/env python

"""
Columbia's COMS W4111.003 Introduction to Databases
Example Webserver

To run locally:

    python server.py

Go to http://localhost:8111 in your browser.

A debugger such as "pdb" may be helpful for debugging.
Read about it online.
"""

import os
from sqlalchemy import *
from sqlalchemy.pool import NullPool
from flask import Flask, request, render_template, g, redirect, Response, \
                  session, url_for, jsonify

tmpl_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'templates')
app = Flask(__name__, template_folder=tmpl_dir)



#
# The following is a dummy URI that does not connect to a valid database. You will need to modify it to connect to your Part 2 database in order to use the data.
#
# XXX: The URI should be in the format of: 
#
#     postgresql://USER:PASSWORD@104.196.152.219/proj1part2
#
# For example, if you had username biliris and password foobar, then the following line would be:
#
#     DATABASEURI = "postgresql://biliris:foobar@104.196.152.219/proj1part2"
#
DATABASEURI = "postgresql://cb3704:CUf21w4111#@35.196.73.133/proj1part2"

app.secret_key = 'bigbigsecretkey'


#
# This line creates a database engine that knows how to connect to the URI above.
#
engine = create_engine(DATABASEURI)

#
# Example of running queries in your database
# Note that this will probably not work if you already have a table named 'test' in your database, containing meaningful data. This is only an example showing you how to run queries in your database using SQLAlchemy.
#
engine.execute("""CREATE TABLE IF NOT EXISTS test (
  id serial,
  name text
);""")
engine.execute("""INSERT INTO test(name) VALUES ('grace hopper'), ('alan turing'), ('ada lovelace');""")


@app.before_request
def before_request():
  """
  This function is run at the beginning of every web request 
  (every time you enter an address in the web browser).
  We use it to setup a database connection that can be used throughout the request.

  The variable g is globally accessible.
  """
  try:
    g.conn = engine.connect()
  except:
    print("uh oh, problem connecting to database")
    import traceback; traceback.print_exc()
    g.conn = None

@app.teardown_request
def teardown_request(exception):
  """
  At the end of the web request, this makes sure to close the database connection.
  If you don't, the database could run out of memory!
  """
  try:
    g.conn.close()
  except Exception as e:
    pass


#
# @app.route is a decorator around index() that means:
#   run index() whenever the user tries to access the "/" path using a GET request
#
# If you wanted the user to go to, for example, localhost:8111/foobar/ with POST or GET then you could use:
#
#       @app.route("/foobar/", methods=["POST", "GET"])
#
# PROTIP: (the trailing / in the path is important)
# 
# see for routing: http://flask.pocoo.org/docs/0.10/quickstart/#routing
# see for decorators: http://simeonfranklin.com/blog/2012/jul/1/python-decorators-in-12-steps/

#
def research_dashboard():
    user = session['entityid']

    cursor = g.conn.execute("select entityname from researchentity where entityid = {0}".format(user))
    username ={}
    for r in cursor:
        username = r['entityname']
    cursor.close()    
    
    context = dict(user=username)
    return render_template('research-dashboard.html', **context)



def admin_dashboard():
    user = session['adminid']
    
    cursor = g.conn.execute("select adminfirstname||' '||adminlastname as name from administrator where administratorid = {0}".format(user))
    username ={}
    for r in cursor:
        username = r['name']
    cursor.close()   
    
    initiated_exp = g.conn.execute(""" select  e.experimentId, b.agentName, b.strainName, b.category, eb.agentQuantity, eb.agentUnitOfMeasure
                                   from  Experiment e
        join Experiment_BioAgent eb on e.experimentId = eb.experimentId
        join BioAgent b on eb.agentId = b.agentId
        where  e.experimentStatus = 'initiated'
        order  by e.experimentId, b.agentName, b.strainName
                                   """)
    init_exps = initiated_exp.fetchall()
    initiated_exp.close()
                                   
    
    context = dict(user=username, exps  = init_exps)
    return render_template('admin_dashboard.html', **context)


def inspect_dash():
    user = session['inspectorid']
    
    cursor = g.conn.execute("select inspectorfirstname||' '||inspectorlastname as name from inspector where inspectorid = {0}".format(user))
    username ={}
    for r in cursor:
        username = r['name']
    cursor.close()   
    
    
    non_inspected = g.conn.execute("""
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
                                   """)
    non_inspect = non_inspected.fetchall()
    non_inspected.close()
    
    context = dict(user=username,nons= non_inspect)
    
    return  render_template('inspect_dash.html', **context)

def facilitator_dash():
    user = session['facilitatorid']
    
    cursor = g.conn.execute("select facilitatorfirstname||' '||facilitatorlastname as name from facilitator where facilitatorid = {0}".format(user))
    username ={}
    for r in cursor:
        username = r['name']
    cursor.close()   
    
    
    revcursor = g.conn.execute("""
                               select  l.laboratoryId, l.safetyLevel, e.entityName, li.scheduledDate, li.inspectionType, li.inspectionOutcome, li.inspectionNotes
  from  LaboratoryInspection li
        join Laboratory l on li.laboratoryId = l.laboratoryId
        join ResearchEntity e on l.managingEntityId = e.entityId
 where  li.inspectionOutcome is not null
   and  li.reviewedByFacilitatorId is null
                               """)
    to_review = revcursor.fetchall()
    revcursor.close()
    
    repcursor = g.conn.execute("""
                               select  l.laboratoryId, e.entityName, i.incidentReportedDate, i.incidentOccurredDate, i.threatLevel, i.incidentType, i.incidentSummary,
        i.investigationOpenDate, i.investigationClosedDate, i.investigatedByFacilitatorId
  from  Incident i
        join Laboratory l on i.laboratoryId = l.laboratoryId
        join ResearchEntity e on l.managingEntityId = e.entityId
 where  coalesce(i.investigationStatus, 'open') = 'open'
                               """)
    reports = repcursor.fetchall()
    repcursor.close()                          
    
    context = dict(user=username, revs= to_review, reps = reports)
    
    return  render_template('facilitator_dash.html', **context)




@app.route('/')
def index():
    # print(request.args)
      
      
    if 'entityid' in session:
        # return render_template("another.html")
        return research_dashboard()
    
    if 'adminid' in session:
        return admin_dashboard()
    
    if 'inspectorid' in session:
        return inspect_dash()
    
    if 'facilitatorid' in session:
        return facilitator_dash()
    
    
    
    cursor = g.conn.execute("SELECT entityid, entityname FROM researchentity")
    users = {}
    for result in cursor:
        users[result['entityid']] = result['entityname']
    cursor.close()  
    
    
    admincursor = g.conn.execute("select administratorid, adminfirstname||' '||adminlastname as name from administrator")
    admins = {}
    for result in admincursor:
        admins[result['administratorid']] = result['name']
    admincursor.close()
    
    
    inspectcursor = g.conn.execute("select inspectorid,  inspectorfirstname||' '||inspectorlastname as name from inspector")
    inspects = {}
    for result in inspectcursor:
        inspects[result['inspectorid']] = result['name']
    inspectcursor.close()
    
    facilcursor = g.conn.execute("select facilitatorid,  facilitatorfirstname||' '||facilitatorlastname as name from facilitator")
    facils = {}
    for result in facilcursor:
        facils[result['facilitatorid']] = result['name']
    facilcursor.close() 
      

    context = dict(data = users, admindata = admins, inspectdata = inspects, facildata=facils)
    
    
    #
    # render_template looks in the templates/ folder for files.
    # for example, the below file reads template/index.html
    #
    return render_template("index.html", **context)

#
# This is an example of a different path.  You can see it at:
# 
#     localhost:8111/another
#
# Notice that the function name is another() rather than index()
# The functions for each app.route need to have different names
#
@app.route('/another')
def another():
  return render_template("another.html")





@app.route('/labs')
def labs():
    
    user = session['entityid']
    
    icursor = g.conn.execute("select * from laboratory where managingentityid = {0}".format(user))
    labs = icursor.fetchall()
    icursor.close()
    
    context = dict(comments=labs)
    
    return render_template("labs.html", **context)


@app.route('/experiment')
def experiment():
    # has_experiments = ap.has_experiments(session['entityid'])
    
    user = session['entityid']
    

     
    icursor = g.conn.execute("select * from experiment where entityid = {0}".format(user))
    experiments = icursor.fetchall()
    icursor.close()
    # for results in icursor:
    #     experiments[results['experimentid']] = results
    # icursor.close()
    

    statuses = ['design', 'initiated', 'in-progress', 'closed', 'cancelled', 'on-hold']  
    
    
    
    context = dict(comments=experiments, statuses=statuses)
    return render_template("experiment.html", **context)

@app.route('/incident')
def incident():
    # has_experiments = ap.has_experiments(session['entityid'])
    
    user = session['entityid']
    

     
    icursor = g.conn.execute("select * from laboratory where managingentityid = {0}".format(user))
    experiments = icursor.fetchall()
    icursor.close()
    # for results in icursor:
    #     experiments[results['experimentid']] = results
    # icursor.close()
    

    statuses = ['design', 'initiated', 'in-progress', 'closed', 'cancelled', 'on-hold']  
    
    
    
    context = dict(comments=experiments)
    return render_template("incident.html", **context)



@app.route('/bioagent')
def bioagent():
    return render_template("bioagent.html")


# Example of adding new data to the database
@app.route('/add', methods=['POST'])
def add():
  name = request.form['name']
  g.conn.execute("INSERT INTO test VALUES (5,'Chisom Amalunweze')",name)
  return redirect('/')

@app.route('/approve_exp', methods=['POST'])
def approve_exp():
      newstatus = request.form['exstatus']
      expid = request.form['expid']
     
      values = (newstatus, expid)
     
      q = "UPDATE experiment set experimentstatus = %s where experimentid = %s"
     
      g.conn.execute(q,values)
    
      return admin_dashboard()
     # return jsonify(request.form)

@app.route('/add_experiment', methods=['POST'])
def add_experiment():
    
    user = session['entityid']
    name = request.form['exstatus']
    # name= 'closed'
    start_date = request.form['startdate']
    end_date = request.form['enddate']
    
    
    if len(end_date) < 1:
        
        values = (user,name, start_date)
        q = 'insert into experiment(entityid,experimentstatus,experimentstartdate) values (%s, %s, %s)'
        
    else:
        values = (user,name, start_date,end_date) 
        q = 'insert into experiment(entityid,experimentstatus,experimentstartdate,experimentcloseddate) values (%s, %s, %s,%s)'
    g.conn.execute(q,values)
    return redirect(url_for('experiment'))
    # return jsonify(request.form)


@app.route('/update_experiment', methods=['POST'])
def update_experiment():
    
    user = session['entityid']
    name = request.form['exstatus']
    # name= 'closed'
    expid = request.form['expid']
    end_date = request.form['enddate']
    
    
    if len(end_date) < 1:
        values = (name, expid,user)
        q = 'update experiment set  experimentstatus = %s where  experimentid = %s and entityid = %s'
        
    else:
        values = (name, end_date, expid,user)
        q = 'update experiment set  experimentstatus = %s, experimentcloseddate = %s where  experimentid = %s and entityid = %s'
    g.conn.execute(q,values)
    return redirect(url_for('experiment'))
    # return jsonify(request.form)


@app.route('/add_incident', methods=['POST'])
def add_incident():
    
    lab = request.form['labid']
    report_date = request.form['reportdate']
    occur_date = request.form['occurdate']
    threatlevel = request.form['threatlevel']
    incident_type = request.form['inctype']
    incident_summary = request.form['incsummary']
    
    values = (lab, report_date, occur_date, threatlevel, incident_type, incident_summary)
    
    q = """insert into incident(laboratoryid, incidentreporteddate, incidentoccurreddate, 
    threatlevel, incidenttype, incidentsummary) values (%s, %s, %s, %s, %s, %s)"""
    
    g.conn.execute(q,values)
    
    return redirect(url_for('incident'))


@app.route('/add_inspection', methods=['POST'])
def add_inspection():
    
    user = session['inspectorid']
    lab = request.form['labid']
    report_date = request.form['scheddate']
    occur_date = request.form['insptype']
    threatlevel = request.form['inspoutcome']
    incident_type = request.form['inspnotes']
    # incident_summary = request.form['incsummary']
    
    values = (lab, user, report_date, occur_date, threatlevel, incident_type)
    
    q = """insert into laboratoryinspection(laboratoryid, inspectorid, scheduleddate, inspectiontype, 
    inspectionoutcome, inspectionnotes) values (%s, %s, %s, %s, %s, %s)"""
    
    g.conn.execute(q,values)
    
    return inspect_dash()
    # return jsonify(request.form)

@app.route('/add_lab', methods=['POST'])
def add_lab():
    user = session['entityid']
    safetylevel = request.form['safetylevel']
    managedsince = request.form['msdate']

    
    values = (safetylevel, user, managedsince)
    
    q = """insert into laboratory(safetylevel,managingentityid, managedsincedate) values (%s, %s, %s)"""
    
    g.conn.execute(q,values)
    
    return redirect(url_for('labs'))
    # return jsonify(request.form)

@app.route('/update_lab', methods=['POST'])
def update_lab():
    user = session['entityid']
    safetylevel = request.form['safetylevel']
    managedsince = request.form['msdate']
    labid = request.form['labid']
    
    values = (safetylevel,managedsince, user, labid)
    
    q = 'update laboratory set safetylevel = %s, managedsincedate = %s where managingentityid = %s and laboratoryid = %s'
    
    g.conn.execute(q,values)
    
    return redirect(url_for('labs'))
    
    # return jsonify(request.form)
    
    
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        session['entityid'] = request.form['entityid']
    return redirect(url_for('index'))


@app.route('/login_admin', methods=['GET', 'POST'])
def login_admin():
    if request.method == 'POST':
        session['adminid'] = request.form['administratorid']
    return redirect(url_for('index'))
    # return jsonify(request.form)


@app.route('/login_facilitator', methods=['GET', 'POST'])
def login_facilitator():
    if request.method == 'POST':
        session['facilitatorid'] = request.form['facilitatorid']
    return redirect(url_for('index'))


@app.route('/login_inspector', methods=['GET', 'POST'])
def login_inspector():
    if request.method == 'POST':
        session['inspectorid'] = request.form['inspectorid']
    return redirect(url_for('index'))

    
@app.route('/logout')
def logout():
    session.pop('entityid', None)
    return redirect(url_for('index'))

@app.route('/logout_admin')
def logout_admin():
    
    session.pop('adminid',None)
    return redirect(url_for('index'))

@app.route('/logout_inspect')
def logout_inspect():
    
    session.pop('inspectorid',None)
    return redirect(url_for('index'))

@app.route('/logout_facilitator')
def logout_facil():
    
    session.pop('facilitatorid',None)
    return redirect(url_for('index'))

if __name__ == "__main__":
  import click

  @click.command()
  @click.option('--debug', is_flag=True)
  @click.option('--threaded', is_flag=True)
  @click.argument('HOST', default='0.0.0.0')
  @click.argument('PORT', default=8111, type=int)
  def run(debug, threaded, host, port):
    """
    This function handles command line parameters.
    Run the server using:

        python server.py

    Show the help text using:

        python server.py --help

    """

    HOST, PORT = host, port
    print("running on %s:%d" % (HOST, PORT))
    app.run(host=HOST, port=PORT, debug=debug, threaded=threaded)


  run()