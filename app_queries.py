#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Oct 31 09:03:11 2021

Custom queries for web application

@author: jachimikeamalunweze
"""


def view_experiments(conn, id):
    query = ("select entityid, experimentid, experimentstatus from experiment where entityid = ?",id)
    cursor = conn.execute(query)
    return cursor

def insert_experiment(conn,id,insert_args):
    return None

def has_experiments(conn, id):
    query = ("select count(*) from experiments where entityid = ?", id)
    cursor = conn.execute(query)
    return cursor > 0
    

