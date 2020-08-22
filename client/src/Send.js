import React from 'react';
import './Components.css';


export default class Send extends React.Component {
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