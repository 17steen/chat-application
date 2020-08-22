import React from 'react';
import './App.css';
import Chat from './Chat'
import Send from './Send';
import LoginForm from './LogginForm';
import RegisterForm from './RegisterForm';
import { Color, UsernameDisplay } from './Components.js';
import axios from 'axios';

class App extends React.Component {
  state = {
    username: "",
    password: "",
    password2: "",
    color: "red",
    messages: [],
    formState: 0
  };

  changeColor = (_color) => {
    this.setState({
      color: _color,
    });
  }

  switchFormState = () => {
    this.setState({
      formState: this.state.formState === 0 ? 1 : 0,
    });
  }

  updateMessages = async () => {
    const messages = (await axios.get('/message')).data;
    this.setState({
      messages: messages.slice(0),
    });
  }

  login = async (_username, _password, _type) => {
    const reply = (await axios.post('/login', {
      authType: _type,
      username: _username,
      password: _password
    }));

    if(reply.data.status !== 1) {
      return reply.data.status;
    } else {
      setTimeout(() => {
        this.setState({
          session: reply.data,
          username: reply.data.username
        })
      }, 3000);

      return reply.data;
    }
  }

  register = async (_username, _password, _password2) => {
    const reply = (await axios.post('/register', {
      username: _username,
      password: _password,
      password2: _password2
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
    await axios.post('/message', {
      username: this.state.username,
      color: this.state.color,
      text: message,
    });

    await this.updateMessages();

    return true;
  }

  render() {
    return (
      <div className="App">
        {this.state.username.length !== 0 ?
          <div>
            <UsernameDisplay username={this.state.username}/>
            <Color color={this.state.color} changeColor={this.changeColor} />
            <Chat messages={this.state.messages} updateMessages={this.updateMessages}/>
            <Send sendMessage={this.sendMessage}/>
          </div> :
        (this.state.formState === 0 ?
          <div>
            <div className="margin0" style={{color: "white"}}>Login</div>
            <LoginForm 
            username={this.state.username} password={this.state.password}
            formState={this.state.formState} switchFormState={this.switchFormState}
            login={this.login}/>
          </div> :
          <div>
            <div className="margin0" style={{color: "white"}}>Register</div>
            <RegisterForm
            username={this.state.username} password={this.state.password} password2={this.state.password2}
            formState={this.state.formState} switchFormState={this.switchFormState}
            register={this.register}/>
          </div>
        )}
      </div>
    )
  }
}

export default App;
