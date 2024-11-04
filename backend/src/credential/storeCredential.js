/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const axios = require('axios');
const sql = require('mssql');
const dbConfig = require('../config/dbConfigWallet');
const acaPyBaseUrl = 'http://127.0.0.1:7011';

// Initialize SQL connection pool
let poolPromise = sql.connect(dbConfig)
    .then(pool => {
        console.log('Connected to MSSQL');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });

// Helper function to wait for a specified number of milliseconds
function wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// Function to store the credential (modified to take data from req.body)
const storeCredential = async (req, res) => {
    const { credExId, jwtToken } = req.body; // Extract credExId and jwtToken from request body

    // Check if both credExId and jwtToken are provided
    if (!credExId || !jwtToken) {
        return res.status(400).json({ error: "credExId and jwtToken are required" });
    }

    try {
        console.log("Step 1: Received credExId and jwtToken from request body");
        console.log("credExId: ", credExId);
        console.log("\n\n\njwtToken:\n", jwtToken + "\n\n\n\n\n");

        // Step 1: Accept the offer
        const acceptResponse = await axios.post(
            `${acaPyBaseUrl}/issue-credential-2.0/records/${credExId}/send-request`,
            {},
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`,  // Use the JWT token from the request body
                    'Content-Type': 'application/json'
                }
            }
        );

        console.log("Offer accepted: ", acceptResponse.data);
        // Wait for 5 seconds (if needed)
         await wait(5000);

        // Step 2: Store the credential after a short delay
        const storeResponse = await axios.post(
            `${acaPyBaseUrl}/issue-credential-2.0/records/${credExId}/store`,
            {},
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`,  // Use the JWT token from the request body
                    'Content-Type': 'application/json'
                }
            }
        );



        console.log("Credential stored successfully: ", storeResponse.data);

        // Send success response back to the client
        return res.status(200).json({
            message: "Credential stored successfully",
            data: storeResponse.data
        });

    } catch (error) {
        console.error('Error storing credential:', error.message);
        return res.status(500).json({ error: 'Failed to store credential' });
    }
};

// Function to get Auth Token from ACA-Py
const getAuthToken = async (req, res) => {
    const { walletID } = req.body; // Expect walletID in request body

    if (!walletID) {
        return res.status(400).json({ error: "Wallet ID is required" });
    }

    try {
        const response = await axios.post(`${acaPyBaseUrl}/multitenancy/wallet/${walletID}/token`);

        if (response.data && response.data.token) {
            res.status(200).json({ token: response.data.token });
        } else {
            res.status(404).json({ error: 'Token not found in response' });
        }
    } catch (error) {
        console.error('Error getting auth token:', error.response ? error.response.data : error.message);
        res.status(500).send('Failed to get auth token');
    }
};

// Function to get Wallet Data from MSSQL database
const getWalletData = async (req, res) => {
    const { email } = req.body; // Expect email in request body

    if (!email) {
        return res.status(400).json({ error: "Email is required" });
    }

    try {
        const pool = await poolPromise;
        const walletDataResult = await pool.request()
            .input('Email_Address', sql.NVarChar(50), email)
            .query(`
                SELECT wallet_id, public_did 
                FROM Wallets 
                WHERE Email_Address = @Email_Address
            `);

        if (walletDataResult.recordset.length === 0) {
            return res.status(404).send('No wallet found for this email.');
        }

        const walletData = walletDataResult.recordset[0];
        res.status(200).json({ wallet: walletData });
    } catch (err) {
        console.error('Get Wallet Data Error:', err);
        res.status(500).send('Server error');
    }
};

// Export all the functions as proper POST methods
module.exports = {
    storeCredential,
    getAuthToken,
    getWalletData
};
