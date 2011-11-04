# Installation and Setup

1. Clone the repository
2. Rename the ```config/salesforce.yml.sample``` to ```config/salesforce.yml```
3. To get Salesforce api access, login to your Salesforce account
4. From the login home page (or Settings from your user drop down in the header)
5. In the "App Setup" navigation group on the left choose Develop -> Remote Access
6. Click "New" to enter a Remote Access Application
7. Enter an application name (e.g. databasedotcom-demo) and for the callback URL enter ```http://localhost:4567/auth/salesforce/callback``` (the demo app has that callback route)
8. Save and copy your consumer key and consumer secret
9. Open the yml file and enter your Salesforce client id (consumer key) and client secret (consumer secret)
10. ```cd``` to where you cloned the repository
11. Run ```bundle install```
12. Once completed run ```./script/server``` to start the server