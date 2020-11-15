# Welcome to TermChat

## What is TermChat?
TermChat is a chatting application written in Bash for the client and PHP for the web server.

## How does it work?
You have a client-app and a web-server
The client-app is what your clients will have and the web server is what you will run. 
The web server is a place where the client app will contact to allow the user to talk to other members on the server. 

Think of it like Discord, but way more crappy. Instead of a Discord Server, you will have a web server and instead of the Discord app, you have a client terminal script.

When you are set up and type a message;
```m Hello world!```
The client app will contact the web server with your username, password and message. If the username and password are correct, the webserver will then store your latest message temporarily and when a client-app asks for a refresh (clients do this twice every second) it will give them your new message.

## Where do I get releases?
DO NOT clone this git as it is not organised in a way where you can use it out of the box, please go to the Releases section [or click here](https://github.com/SejDevStuff/termchat/releases)

## How do I set this up?
*Setup Info will be here when we make our first release!*