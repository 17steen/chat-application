import React from 'react';
import './Components.css';
import Button from '@material-ui/core/Button';

export default class LoginForm extends React.Component {
    state = {
      username: "",
      password: "",
      clicked: false,
      loginResult: 0
    };
  
    componentDidMount = async() => {
      const res = await this.props.login("", "", "autologin");
      this.setState({
        loginResult: res,
      });
    }
  
    handleChange = e => {
      this.setState({
        [e.target.name]: e.target.value,
      });
    }
  
    handleSubmit = async e => {
      e.preventDefault();
      const res = await this.props.login(this.state.username, this.state.password, "default");
      this.setState({
        loginResult: res,
      });
    }
  
    getErrorText(code) {
      switch(code) {
        case -3:
          return "Session expired-";
  
        case -2:
          return "User not found-";
        
        case -1:
          return "Invalid password-";
  
        default:
          return "";
      }
    }
  
    getSuccessText(code) {
      switch(code) {
        case -3:
        case -2:
        case -1:
          return "";
  
        default:
          return "Success- Redirecting you in 3s...";
      }
    }
  
    render() {
      const form = (
        <form onSubmit={this.handleSubmit}  >
          <input className="inputfield1" name="username" type="text" placeholder="Username..." required={true} onChange={this.handleChange}  /><br />
          <input className="inputfield1 header1" name="password" type="password" placeholder="Password..." required={true} onChange={this.handleChange}  />
        </form>
        );
      return (
        <div className="header1">
          {form}
            <Button
            variant="contained" 
            color="primary" 
            onClick={this.handleSubmit}
            className="button1" style={{ marginTop: 5 }}>Login</Button>
            <br />
            <Button
            variant="contained" 
            color="primary" 
            onClick={this.props.switchFormState}
            className="button1" style={{ marginTop: 5 }}>Register</Button>
            <br />
            <div className="panel1 margintop1 errorText">
              {this.getErrorText(this.state.loginResult)}
            </div>
            <div className="panel1 margintop1 successText">
              {this.getSuccessText(this.state.loginResult)}
            </div>
        </div>
      );
    }
  }