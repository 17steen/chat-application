import React from 'react';
import './Components.css';
import Button from '@material-ui/core/Button';
// import axios from 'axios';

export class Chat extends React.Component {

  

  componentDidMount = () => {
    this.props.updateMessages();
    setInterval(this.props.updateMessages, 500);
  }

  toFormat(message, [diss, repl]) {
    const skip = diss.length;
    let result = [];
    let lastIndex = 0;

    while(message.slice(lastIndex).split(diss).length > 2) {
      let i1 = message.indexOf(diss, lastIndex);
      if(i1 !== lastIndex){
        result.push(message.slice(lastIndex, i1));
      }
      let i2 = message.indexOf(diss, i1 + skip);
      lastIndex = i2 + skip;
      
      result.push(`<${repl}>${message.slice(i1 + skip, i2)}</${repl}>`);
    }
    result.push(message.slice(lastIndex, message.length));

    return result.join("");
  }

  formatMessage(message) {
    let result = message.text;

    const styles = [
      ["**", "b"],
      ["*", "i"],
      ["__", "u"],
      ["~~", "s"]
    ];
    styles.forEach((val, i) => {
      result = this.toFormat(result, val);
    });

    return <p className="text1 margin0" dangerouslySetInnerHTML={{__html: result}}></p>;
  }

  render(){
    const messageList = this.props.messages.map((message, i) => {
      return(
        <div className="message-wrapper" key={i}>
          <h5 style={{margin: 0,
                      color: message.color}}>
            {message.username}
          </h5>
            {this.formatMessage(message)}
        </div>
      )
    });

    return (
      <div className="Chat">
        <h3 className="text1 margin0 header1"> Messages</h3>
        <div>
          {messageList}
        </div>
      </div>
    );
  }
}

export class Send extends React.Component {
  state = {
    message: "",
  };

  handleChange = e => {
    this.setState({
      message: e.target.value,
    });
  }

  handleSubmit = async e => {
    e.preventDefault();

    if(await this.props.sendMessage(this.state.message))
      this.setState({
        message: "",
      });
    
  }

  render(){
    return (
      <div className="Send">
        <form onSubmit={this.handleSubmit} className="full">
          <input className="input-message" type="text" value={this.state.message} placeholder="Message..." required={true} onChange={this.handleChange} />
        </form>
      </div>
    );
  }
}

export class LoginForm extends React.Component {
  state = {
    username: "",
    password: "",
    clicked: false,
    loginResult: 0
  };

  handleChange = e => {
    this.setState({
      [e.target.name]: e.target.value,
    });
  }

  handleSubmit = async e => {
    e.preventDefault();
    const res = await this.props.login(this.state.username, this.state.password);
    this.setState({
      clicked: false,
      loginResult: res,
    });
  }

  handleClick = () => {
    this.setState({
      clicked: true,
    });
  }

  getErrorText(code) {
    switch(code) {
      case -2:
        return "User not found-";
      
      case -1:
        return "Invalid password-";

      default:
        return "";
    }
  }

  render(){
    const form = (
      <form onSubmit={this.handleSubmit}  >
        <input className="inputfield1" name="username" type="text" placeholder="Username..." required={true} onChange={this.handleChange}  /><br />
        <input className="inputfield1 header1" name="password" type="text" placeholder="Password..." required={true} onChange={this.handleChange}  />
      </form>
      );
    return (
      <div class="header1">
        {form}
        <Button
          variant="contained" 
          color="primary" 
          onClick={this.handleSubmit}
          className="button1" style={{ marginTop: 5 }}>Login</Button>
          <br />
          <div className="panel1 margintop1 errorText">
            {this.getErrorText(this.state.loginResult)}
          </div>
      </div>
    );
  }
}

export class UsernameDisplay extends React.Component {
  render() {
    return (
      <div className="panel1">
        <div className="color-text">
          <div className="margin0 currentColor" style={{color: "white"}}>Username: {this.props.username.length >= 1 ? this.props.username : "-"}</div>
        </div>
      </div>
    );
  }
}

export class Color extends React.Component {
  state = {
    color: "red",
    clicked: false,
  };

  handleChange = e => {
    this.setState({
      color: e.target.getAttribute("_color"),
      clicked: false,
    }, () => 
      this.props.changeColor(this.state.color));
  }

  handleClick = () => {
    this.setState({
      clicked: true,
    });
  }

  render(){
    const form = (
      <form className="change-color-form">
        <button onClick={this.handleChange} _color="red" style={{backgroundColor: "red", border: "1px solid #424242"}}>red</button>
        <button onClick={this.handleChange} _color="blue" className="change-color1" style={{backgroundColor: "blue", border: "1px solid #424242"}}>blue</button>
        <button onClick={this.handleChange} _color="green" className="change-color1" style={{backgroundColor: "green", border: "1px solid #424242"}}>green</button>
      </form>);
    return (
      <div className="panel1">
        {this.state.clicked && form}
        {!this.state.clicked && <Button
         variant="contained" 
         color="primary" 
         onClick={this.handleClick}
         className="button1">
           {this.props.color.length === 0 ? "Set Color" : "Change Color"}
          </Button>}
        <div className="color-text">
          <div className="margin0 currentColor" style={{color: this.props.color}}>Color: {this.props.color}</div>
        </div>
      </div>
    );
  }
}

export default { Chat, Send, LoginForm, Color, UsernameDisplay };
