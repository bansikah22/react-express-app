import React from 'react';
import './App.css'; // Import general styling (optional, if you need any)
import Form from './components/Form'; // Import the Form component

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>My Simple React and Express App</h1>
      </header>
      <main>
        <Form /> {/* Render the Form component */}
      </main>
    </div>
  );
}

export default App;
