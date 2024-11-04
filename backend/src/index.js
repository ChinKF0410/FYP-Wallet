/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const app = require('./app');
const port = process.env.PORT || 4000;

// Start server
app.listen(port, () => {
    console.log(`Server is running on http://127.0.0.1:${port}`);
});
