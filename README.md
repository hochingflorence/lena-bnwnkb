# Webinterface for Google Dialogflow

This repository contains a client for Dialogflow that uses API v2 and is written in Ruby on Rails. The client is intended to be used for research and development, not for commercial use. It provides a simple and convenient web interface to interact with conversational agents developed using Google Dialogflow

## Getting Started

You can set up the client with the following five steps:

1. Create a conversational agent on [Dialogflow](https://console.dialogflow.com) using the [documentation](https://cloud.google.com/dialogflow/) provided by Google.
2. Create a service account key for the webinterface for authentication. To do so, please follow the instructions in the [Google Cloud Documentation](https://cloud.google.com/dialogflow/docs/quick/setup). The resulting .json file should be named "dialogflow_authentication.json" and saved in the config folder of the webinterface. Afterwards, insert the project ID from the authentication json in the Dialogflow config file (dialogflow.yml) in the same folder.
3. Implement desired changes to the webinterface (for example, you can change agent name and avatar in app/views/welcome/index.html.erb).
4. Precompile the ruby application using the command "RAILS_ENV=production bundle exec rake assets:precompile".
5. Deploy the webinterface. For deployment on Heroku, you can simply upload the webinterface to a new repository and connect this repository with a Heroku app for live deployment. The webinterface uses a Postgres database to store dialogue information. After creating the application on Heroku, please add a Heroku Postgres database in the resources section. Then run "rake db:migrate" to migrate the database to Heroku.

### Prerequisites

* Platform to host client. For example, you can register for the [GitHub Developer Pack](https://www.heroku.com/github-students) and then deploy the client on [Heroku](http://heroku.com) for free (see also Getting Started).

### Remarks

* In addition to the history functionality on dialogflow, you can download all conversations stored in the Postgres database with the commands heroku pg:psql -a appname and then \copy (SELECT * FROM users) TO db_export.csv CSV DELIMITER ','
* The repository further contains a basic briefing website (see folder briefing) that can be used in experiments. You can simply adjust the briefing text and javascript that is used for random participant assignment and then deploy it.
