import React from 'react';
import './Components.css';
import Button from '@material-ui/core/Button';



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
        <button onClick={this.handleChange} _color="red" className="full" style={{backgroundColor: "red", border: "1px solid #424242"}}>red</button>
        <button onClick={this.handleChange} _color="blue" className="full change-color1" style={{backgroundColor: "blue", border: "1px solid #424242"}}>blue</button>
        <button onClick={this.handleChange} _color="green" className="full change-color1" style={{backgroundColor: "green", border: "1px solid #424242"}}>green</button>
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

export default { Color, UsernameDisplay };
