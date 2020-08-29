
const crypto = require("crypto");
const cookieParser = require('cookie-parser');
const bodyParser = require('body-parser');
const express = require('express');
const { argv } = require("process");
const app = express();
app.use(bodyParser.urlencoded({extended: false}));
app.use(bodyParser.json());
app.use(cookieParser());

app.use(express.static(argv[2]  ?? "../client-elm/public"));


let messages = [];
const sessions = new Map();
const database = new Map().set("lamkas", "1").set("stéén", "2")

app.get('/message', (req, res) => {
    res.send(JSON.stringify(messages));
});

app.post('/message', (req, res) => {
    const message = req.body;
    console.log(message.text)
    message.createdAt = Date.now()
    if(message.text === "/clear"){
        messages = [];
        return;
    }
    messages.push(message);
    res.send('Success');
});

app.post('/login', (req, res) => {
    const data = req.body;
    switch(data.authType) {
        case "autologin":
            console.log(sessions)
            console.log(req.cookies);
            if(!sessions.has(req.cookies["sessionID"])) {
                
                const error = {
                    status: -3
                }
                res.send(JSON.stringify(error))
            } else {
                res.send(JSON.stringify(sessions.get(req.cookies["sessionID"])));
            }
            break;

        case "default":
            console.log("default login")
            if(!database.has(data.username)) {
                const error = {
                    status: -2
                }
                res.send(JSON.stringify(error))
            } else if(database.get(data.username) != data.password) {
                const error = {
                    status: -1
                }
                res.send(JSON.stringify(error))
            } else {
                const sessionID = crypto.randomBytes(16).toString("hex");
                const session = {
                    id: sessionID,
                    username: data.username,
                    status: 1
                }
        
                sessions.set(sessionID, session);
                res.cookie("sessionID", session.id)
                res.send(JSON.stringify(session));  
            }
            break;
    }
})

app.post('/register', (req, res) => {
    const data = req.body;
    if(database.has(data.username)) {
        const error = {
            status: -1
        }
        res.send(JSON.stringify(error))
    } else if(data.password !== data.password2) {
        const error = {
            status: -2
        }
        res.send(JSON.stringify(error))
    } else {
        database.set(data.username, data.password)

        const sessionID = crypto.randomBytes(16).toString("hex");
        const session = {
            id: sessionID,
            username: data.username,
            status: 1
        }

        sessions.set(sessionID, session);
        res.send(JSON.stringify(session));
    }
})

console.log("http://localhost:8080/");

app.listen(8080);