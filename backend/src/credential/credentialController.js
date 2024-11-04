/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const axios = require('axios');
const sql = require('mssql');
const dbConfig = require('../config/dbConfigWallet');  // Database configuration
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

// Function to wait for a specified number of milliseconds
async function wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function receiveOffer(req, res) {
    try {
        // Extract the holder email from the request body
        const { holderEmail } = req.body;
        console.log("1: " + holderEmail);

        if (!holderEmail) {
            throw new Error('Email attribute not found in the request.');
        }

        console.log('Email found: ', holderEmail);

        // Step 1: Get wallet data for the user based on the email
        const walletData = await getWalletData(holderEmail);
        if (!walletData) {
            throw new Error(`Wallet not found for email: ${holderEmail}`);
        }

        // Step 2: Get JWT token for the user's wallet
        const jwtToken = await getAuthToken(walletData.wallet_id);
        console.log(jwtToken);

        // Fetch all credential offers from the ACA-Py agent (holder's side)
        const recordsResponse = await axios.get(
            'http://127.0.0.1:7011/issue-credential-2.0/records',
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`,  // Use the retrieved JWT token
                    'Content-Type': 'application/json'
                }
            }
        );

        // Declare 'records' outside the 'if' block so it can be used globally in the function
        let records = [];

        // Check if the response structure is valid and extract 'results'
        if (recordsResponse && recordsResponse.data && recordsResponse.data.results) {
            records = recordsResponse.data.results; // Fetch the list of credential exchange records
            console.log("Fetched records: ", records);
        } else {
            console.log("No records found or incorrect response structure.");
        }

        // Check if records exist and get the first record
        if (records.length === 0) {
            return res.status(201).json({ message: 'No credential offers found.' });
        }
console.log("\n\n\n\n\n\n\n hi \n\n\n\n\n\n");
        const firstRecord = records[0]; // Get the first record
        console.log('First record:', firstRecord);

        const credExId = firstRecord.cred_ex_record.cred_ex_id; // Extract the credential exchange ID


        // Step 1: Accept the offer
        const acceptResponse = await axios.post(
            `http://127.0.0.1:7011/issue-credential-2.0/records/${credExId}/send-request`,
            {},
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`,  // Pass your JWT token for holder
                    'Content-Type': 'application/json'
                }
            }
        );
        console.log(acceptResponse.data);

        const requestUrl = `http://127.0.0.1:7011/issue-credential-2.0/records/${credExId}/store`;
        console.log(requestUrl);

        // Wait for 5 seconds
        await wait(5000);


        // Step 2: Store the credential
        const storeResponse = await axios.post(
            requestUrl,
            {},
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`,  // Use the retrieved JWT token
                    'Content-Type': 'application/json'
                }
            }
        );

        console.log("Store Done");

        console.log(jwtToken);

        // After fetching the credential records
        const credentialRecordResponse = await axios.get(
            `http://127.0.0.1:7011/credentials`,
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        console.log('Credential Record:', credentialRecordResponse.data);

        // Respond with success message and credential data
        res.status(200).json({
            message: "Credential offer accepted and stored successfully.",
            ccredentials: credentialRecordResponse.data.results   // Pass credentials to frontend
        });


    } catch (error) {
        console.error('Error processing credential offer:', error.message);
        res.status(500).json({ error: error.message });
    }
}

async function getWalletData(username) {
    try {
        const Email_Address = username;
        const pool = await poolPromise;  // Use the pool connection
        const query = `SELECT wallet_id, public_did FROM Wallets WHERE Email_Address = @Email_Address`;

        const request = pool.request();  // Create a request using the pool connection
        const result = await request
            .input('Email_Address', sql.NVarChar(50), Email_Address)
            .query(query);

        if (result.recordset.length > 0) {
            const walletData = result.recordset[0];
            console.log(`Wallet ID: ${walletData.wallet_id}, Public DID: ${walletData.public_did}`);
            return walletData;
        } else {
            console.log(`No wallet found for Email_Address: ${Email_Address}`);
            return null;
        }
    } catch (error) {
        console.error('Error retrieving wallet data:', error);
        throw new Error('Failed to retrieve wallet data');
    }
}

// Get auth token from ACA-Py
async function getAuthToken(walletID) {
    try {
        const response = await axios.post(`${acaPyBaseUrl}/multitenancy/wallet/${walletID}/token`);
        console.log('Auth Token Retrieved Successfully:', response.data);
        return response.data.token;
    } catch (error) {
        console.error('Error getting auth token:', error.response ? error.response.data : error.message);
        throw new Error('Failed to get auth token');
    }
}

module.exports = { receiveOffer };
