/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const axios = require('axios');
const sql = require('mssql');

async function receiveConnection(req, res) {
    try {
        console.log('Received request body:', req.body);

        // Extract the invitation from the request body
        const { invitation ,holder , issuer} = req.body;

        // Step 1: Get wallet data for the user
        const walletData = await getWalletData(holder);
        if (!walletData) {
            throw new Error(`Wallet not found for holder: ${holder}`);
        }

        // Step 2: Get JWT token for the user's wallet
        const jwtToken = await getAuthToken(walletData.wallet_id);

        console.log('Sending invitation to the SSI agent...');
        const response = await axios.post(
            `http://127.0.0.1:7011/connections/receive-invitation`, 
            invitation,
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`, // Pass your JWT token
                    'Content-Type': 'application/json'
                }
            }
        );

        console.log('Invitation response from SSI agent:', response.data);

        // Process the connection ID and status
        const connectionStatus = 'Connection received and processed successfully';
        const connectionID = response.data.connection_id;

        console.log(`Processing connectionID: ${connectionID}, connectionStatus: ${connectionStatus}`);

        // Call storeConnectionData to save the data into the database
        await storeConnectionData(connectionID, issuer, connectionStatus, holder);

        console.log('Connection data stored in database successfully.');

        // Send a response back to the issuer
        res.status(200).json({
            message: 'Holder received the connection',
            status: connectionStatus
        });
    } catch (error) {
        console.error('Error in receiveConnection function:', error.response ? error.response.data : error.message);
        res.status(500).json({
            message: 'Failed to process connection',
            error: error.message
        });
    }
}

// Function to store Connection data in the database
async function storeConnectionData(connectionID, issuer, status, email) {
    try {
        console.log('Storing connection data into database:', { connectionID, issuer, status, email });

        // Define the SQL query for inserting data
        const query = `INSERT INTO connection (connection_id, issuer, status, Email_Address) 
                       VALUES (@connectionID, @issuer, @status, @Email_Address)`;

        // Create a new request object to execute queries
        const pool = await sql.connect(); // Make sure pool is connected
        const request = new sql.Request(pool);

        // Parameterize the query to prevent SQL injection
        request
            .input('connectionID', sql.NVarChar(255), connectionID)
            .input('issuer', sql.NVarChar(50), issuer)
            .input('status', sql.NVarChar(50), status)
            .input('Email_Address', sql.NVarChar(200), email);

        // Execute the query
        await request.query(query);

        console.log('Connection data stored successfully.');



    } catch (error) {
        console.error('Error storing connection data:', error.message);
        throw new Error('Failed to store connection data');
    } 
}




// Get auth token from ACA-Py
async function getAuthToken(walletID) {
    try {
        console.log(`Requesting auth token for walletID: ${walletID}`);
        const url = `http://127.0.0.1:7011/multitenancy/wallet/${walletID}/token`;
        console.log(`Requesting URL: ${url}`);

        const response = await axios.post(url);
        console.log('Auth Token Retrieved Successfully:', response.data);
        return response.data.token;  // Return the token
    } catch (error) {
        console.error('Error getting auth token:', error.response ? error.response.data : error.message);
        throw new Error('Failed to get auth token');
    }
}




// Get wallet data function
async function getWalletData(email) {
    try {
        const query = `SELECT wallet_id, public_did FROM Wallets WHERE Email_Address = @Email_Address`;
        const request = new sql.Request();
        const result = await request
            .input('Email_Address', sql.NVarChar(200), email)
            .query(query);

        if (result.recordset.length > 0) {
            const walletData = result.recordset[0];
            console.log(`Wallet Data Retrieved:`, walletData);
            return walletData;
        } else {
            console.log(`No wallet found for email: ${email}`);
            return null;
        }
    } catch (error) {
        console.error('Error retrieving wallet data:', error);
        throw new Error('Failed to retrieve wallet data');
    }
}








module.exports = { receiveConnection, getWalletData, getAuthToken};
