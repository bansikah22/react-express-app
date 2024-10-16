require('dotenv').config(); // Load environment variables
console.log('PORT:', process.env.PORT);
console.log('FRONTEND_URL:', process.env.FRONTEND_URL);

const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 5000;

// CORS Configuration
const corsOptions = {
  origin: process.env.FRONTEND_URL || 'http://localhost:3001' || '*',  // Allow requests from the frontend
  optionsSuccessStatus: 200,
};

app.use(cors(corsOptions));  // Apply CORS settings

app.options('*', cors(corsOptions));  // Handle preflight requests

// Middleware to parse incoming requests
app.use(express.json());

// Example POST route
app.post('/api/submit', (req, res) => {
  const { input } = req.body;
  res.json({ message: `Hello, you entered: ${input}` });
});

// Health check route
app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello from Express backend!' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
