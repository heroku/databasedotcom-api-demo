# Installation and Setup

1. Clone the repository
2. Rename the ```config/salesforce.yml.sample``` to ```config/salesforce.yml```
3. You can specify an optional ```version``` YAML key if Salesforce removes support for an older API as the databasedotcom gem might not have the most up to date default version. For other YAML keys: http://rubydoc.info/github/heroku/databasedotcom/master/Databasedotcom/Client:initialize

        ---
        client_secret: client_secret
        client_id: client_id
        version: 23.0 # this is the current Salesforce API version

4. To get Salesforce api access, login to your Salesforce account
5. From the login home page (or Settings from your user drop down in the header)
6. In the "App Setup" navigation group on the left choose Develop -> Remote Access
7. Click "New" to enter a Remote Access Application
8. Enter an application name (e.g. databasedotcom-demo) and for the callback URL enter ```http://localhost:4567/auth/salesforce/callback``` (the demo app has that callback route)
9. Save and copy your consumer key and consumer secret
10. Open the yml file and enter your Salesforce client id (consumer key) and client secret (consumer secret)
11. ```cd``` to where you cloned the repository
12. Run ```bundle install```
13. Once completed run ```./script/server``` to start the server