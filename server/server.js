const express = require('express');
const crypto = require("crypto");
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.urlencoded({extended: false}));
app.use(bodyParser.json());

const messages = [];
const sessions = new Map();
const database = new Map().set("lamkas", 1).set("stéén", 2)

app.get('/message', (req, res) => {
    res.send(JSON.stringify(messages));
});

app.post('/message', (req, res) => {
    const message = req.body;
    if(message.text === "/clear"){
        messages.filter(() => true);
        return;
    }
    messages.push(message);
    res.send('Success');
});

app.post('/login', (req, res) => {
    const data = req.body;
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
        res.send(JSON.stringify(session));
    }
})

app.listen(8080);