#!/bin/sh
export FLASK_APP=./RecipeScraper/index.py
pipenv run flask --debug run -h 0.0.0.0