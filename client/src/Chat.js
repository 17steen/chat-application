import React from 'react';
import './Components.css';


export default class Chat extends React.Component {

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

    const styles = [
      ["**", "b"],
      ["*", "i"],
      ["__", "u"],
      ["~~", "s"]
    ];
    styles.forEach((val, i) => {
      message = this.toFormat(message, val);
    });

    return <p className="text1 margin0" dangerouslySetInnerHTML={{__html: message}}></p>;
  }

  formatDate(timestamp) {
    const date = new Date(timestamp)
    const curr = new Date()

    if(date.getDay() === curr.getDay()) {
      return "Today at " +
      (date.getHours() < 10 ? "0" + date.getHours() : date.getHours())
      + ":" +
      (date.getMinutes() < 10 ? "0" + date.getMinutes() : date.getMinutes())
    } else {
      return new Date(timestamp).toUTCString()
    }
  }

  render(){
    const messageList = this.props.messages.map((message, i) => {
      return(
        <div className="message-wrapper" key={i}>
          <div className="flex">
            <div className="flex1" style={{margin: 0, color: message.color, fontSize: 16}}>
              {message.username}
            </div>
            <div className="flex1" style={{marginLeft: 5, fontSize: 10, color: "#acacac"}}>
              {this.formatDate(message.createdAt)}
            </div>
          </div>
            {this.formatMessage(message.text)}
        </div>
      )
    });

    return (
      <div className="Chat">
        <h3 className="text1 margin0 header1"> Messages ({this.props.messages.length})</h3>
        <div>
          {messageList}
        </div>
      </div>
    );
  }
}