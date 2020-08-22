import React from 'react';
import './Components.css';
import Button from '@material-ui/core/Button';

export default class RegisterForm extends React.Component {
    state = {
      username: "",
      password: "",
      password2: "",
      clicked: false,
      registerResult: 0
    };
  
    handleChange = e => {
      this.setState({
        [e.target.name]: e.target.value,
      });
    }
  
    handleSubmit = async e => {
      e.preventDefault();
      const res = await this.props.register(this.state.username, this.state.password, this.state.password2);
      this.setState({
        registerResult: res,
      });
    }
  
    getErrorText(code) {
      switch(code) {
        case -2:
          return "Passwords don't match-";
  
        case -1:
          return "Username already taken-";
  
        default:
          return "";
      }
    }
  
    render(){
      const form = (
        <form onSubmit={this.handleSubmit}  >
          <input className="inputfield1" name="username" type="text" placeholder="Username..." required={true} onChange={this.handleChange}  /><br />
          <input className="inputfield1 header1 marginbot0" name="password" type="text" placeholder="Password..." required={true} onChange={this.handleChange}  /><br />
          <input className="inputfield1 header1" name="password2" type="text" placeholder="Repeat password..." required={true} onChange={this.handleChange}  />
        </form>
        );
      return (
        <div className="header1">
          {form}
            <Button
            variant="contained" 
            color="primary" 
            onClick={this.handleSubmit}
            className="button1" style={{ marginTop: 5 }}>Register</Button>
            <br />
            <Button
            variant="contained" 
            color="primary" 
            onClick={this.props.switchFormState}
            className="button1" style={{ marginTop: 5 }}>Login</Button>
            <br />
            <div className="panel1 margintop1 errorText">
              {this.getErrorText(this.state.registerResult)}
            </div>
        </div>
      );
    }
  }