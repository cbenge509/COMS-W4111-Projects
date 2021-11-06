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

@app.route('/')
def index():
    # print(request.args)
      
      
    if 'entityid' in session:
        # return render_template("another.html")
        return research_dashboard()
    
    
    
    cursor = g.conn.execute("SELECT entityid, entityname FROM researchentity")
    users = {}
    for result in cursor:
        users[result['entityid']] = result['entityname']
    cursor.close()  
      

    context = dict(data = users)
    
    
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
  return render_template("labs.html")


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



@app.route('/add_experiment', methods=['POST'])
def add_experiment():
    
    print(request.form.items())
    user = session['entityid']
    name = request.form['exstatus']
    # name= 'closed'
    start_date = request.form['startdate']
    end_date = request.form['enddate']
    
    values = (user,name, start_date,end_date)
    
    q = 'insert into experiment(entityid,experimentstatus,experimentstartdate,experimentcloseddate) values (%s, %s, %s,%s)'
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


    
    
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        session['entityid'] = request.form['entityid']
    return redirect(url_for('index'))
    
@app.route('/logout')
def logout():
    session.pop('entityid', None)
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