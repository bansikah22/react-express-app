import React, { useState } from 'react';
import './Form.css'; // Import the CSS file for styling

function Form() {
  const [input, setInput] = useState('');
  const [response, setResponse] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const res = await fetch(`${process.env.REACT_APP_API_URL}/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ input }),
      });
      if (!res.ok) {
        throw new Error('Network response was not ok');
      }
      const data = await res.json();
      setResponse(data.message);
    } catch (error) {
      console.error('Failed to fetch:', error);
      setResponse('Error occurred while fetching data');
    }
  };

  return (
    <div className="form-container">
      <h2>Submit Your Input</h2>
      <form onSubmit={handleSubmit} className="form-box">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Enter something"
          className="input-field"
        />
        <button type="submit" className="submit-button">Submit</button>
      </form>
      {response && <p className="response-message">{response}</p>}
    </div>
  );
}

export default Form;
