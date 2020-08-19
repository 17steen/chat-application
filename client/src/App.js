import React from 'react';
import './App.css';
import { Chat, Send, LoginForm, Color, UsernameDisplay } from './Components.js';
import axios from 'axios';

class App extends React.Component {
  state = {
    username: "",
    password: "",
    color: "red",
    messages: [],
  };

  changeColor = (_color) => {
    this.setState({
      color: _color,
    });
  }

  updateMessages = async () => {
    const messages = (await axios.get('/message')).data;
    this.setState({
      messages: messages.slice(0),
    });
  }

  login = async (_username, _password) => {
    const reply = (await axios.post('/login', {
      username: _username,
      password: _password
    }));

    if(reply.data.status !== 1) {
      return reply.data.status;
    } else {
      await new Promise(res => {
        this.setState({
          session: reply.data,
          username: _username
        }, res); 
      });

      return reply.data;
    }
  }

  sendMessage = async (message) => {
    if(this.state.username.length === 0){

      alert("Please pick a username fisrt!");
      return false;
    }
    await axios.post('/message', {
      username: this.state.username,
      color: this.state.color,
      text: message,
    });

    await this.updateMessages();

    return true;
  }

  render() {
    if(this.state.username.length === 0) {
      return (
        <div className="App">
          <div>
            <div className="margin0" style={{color: "white"}}>Login</div>
          </div>
          <LoginForm 
          username={this.state.username} password={this.state.password}
          changeUsername={this.changeUsername} changePassword={this.changePassword}
          login={this.login}/>
        </div>
      )
    }

    return (
      <div className="App">
        <UsernameDisplay username={this.state.username}/>
        <Color color={this.state.color} changeColor={this.changeColor} />
        <Chat messages={this.state.messages} updateMessages={this.updateMessages}/>
        <Send sendMessage={this.sendMessage}/>
      </div>
    );
  }
}

export default App;
