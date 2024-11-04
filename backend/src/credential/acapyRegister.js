/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const axios = require('axios');
const sql = require('mssql');
const crypto = require('crypto');
// ACA-Py API endpoint configuration
const acaPyBaseUrl = 'http://127.0.0.1:7011';  // Issuer API URL || holder is 7011

//-----------------------------------------------------------------------------//
// Main function to create wallet and DID
async function createWalletandDID(req, res) {
    const { email, password } = req.body; // Changed from username to email

    try {
        // Step 1: Create a wallet for the holder
        const wallet = await createWallet(email, password);
        const walletID = wallet.wallet_id;
        const authtoken = wallet.token;  // Get auth token

        // Step 2: Create DID for the wallet 
        const didData = await createDid(authtoken);
        const did = didData.did;
        const verkey = didData.verkey;

        // Step 3: Register DID on the VON network
        await registerDIDatVon(did, verkey);

        // Step 4: Make DID public
        const publicDID = await makeDidPublic(authtoken, did); 
        
        // Step 5: Store key and DID into the database
        await storeWalletData(email, walletID, publicDID); // Changed username to email

        // Step 6: Return success response with DID and verkey
        return {
            message: 'DID and wallet created successfully',
            did,  // Return DID
            verkey,  // Return Verkey
        };
    } catch (error) {
        console.error('Error:', error.message);
        throw new Error('Failed to create wallet and DID');
    }
}


// Function to store wallet key and public DID in the database
async function storeWalletData(email, walletID, publicDid) {
    try {
        // Define the SQL query for inserting data
        const query = `INSERT INTO Wallets (wallet_id, public_did, Email_Address) VALUES (@walletID, @publicDid, @Email_Address)`;

        // Create a new request object to execute queries
        const request = new sql.Request();

        // Parameterize the query to prevent SQL injection
        await request
            .input('walletID', sql.NVarChar(255), walletID)
            .input('publicDid', sql.NVarChar(255), publicDid)
            .input('Email_Address', sql.NVarChar(200), email) // Changed from username to email
            .query(query);

        console.log('Wallet data stored successfully.');
    } catch (error) {
        console.error('Error storing wallet data:', error);
        throw new Error('Failed to store wallet data');
    }
}

// Register DID to VON Network
async function registerDIDatVon(DID, Verkey) {
    try {
        await axios.post(
            `http://localhost:9000/register`,
            {
                did: DID,
                verkey: Verkey,
                role: "ENDORSER"  // or "TRUST_ANCHOR" depending on your network setup
            },
            {
                headers: {
                    'Content-Type': 'application/json'
                }
            }
        );
        console.log('DID registered successfully on VON network');
    } catch (error) {
        console.error('Error registering DID on VON network:', error.response ? error.response.data : error.message);
        throw new Error('Failed to register DID on VON network');
    }
}

// Make DID public
async function makeDidPublic(jwtToken, did) {
    try {
        const response = await axios.post(
            `${acaPyBaseUrl}/wallet/did/public?did=${did}`, {},  // No body, just an empty object
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`,  // Pass your JWT token
                    'Content-Type': 'application/json'
                }
            }
        );
        console.log('DID made public:', response.data);
        const publicdid = response.data.result.did;
        return publicdid;
    } catch (error) {
        console.error('Error making DID public:', error.response ? error.response.data : error.message);
        throw new Error('Failed to make DID public');
    }
}

// Create DID
async function createDid(jwtToken) {
    try {
        const response = await axios.post(
            `${acaPyBaseUrl}/wallet/did/create`,
            {
                method: 'sov',  // DID method for Sovrin or Indy-based ledger
                options: {
                    public: true  // Set this DID as public
                }
            },
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`,  // Pass your JWT token
                    'Content-Type': 'application/json'
                }
            }
        );

        const did = response.data.result.did;
        const verkey = response.data.result.verkey;
        console.log('DID created:', did);

        return { did, verkey };
    } catch (error) {
        console.error('Error creating DID:', error.response ? error.response.data : error.message);
        throw new Error('Failed to create DID');
    }
}

// Function to create a new wallet
async function createWallet(walletName, wallet_key) {
    const currentDateTime = new Date(); // This gets the current date and time
    const combinedKey = `${wallet_key}${currentDateTime.toISOString()}`; // Use toISOString() for a standard format

// Create a hash of the combinedKey
    const walletKeyHash = crypto.createHash('sha256').update(combinedKey).digest('hex');
    console.log(walletKeyHash);
    const walletData = {
        wallet_name: walletName,
        wallet_key: walletKeyHash,
        wallet_type: 'indy',
    };

    try {
        const response = await axios.post(`${acaPyBaseUrl}/multitenancy/wallet`, walletData);
        console.log('Wallet Created:', response.data.token);
        return response.data;
    } catch (error) {
        console.error('Error creating wallet:', error.response ? error.response.data : error.message);
        throw new Error('Failed to create wallet');
    }
}

//----------------------------------------------------------------------------------------------------------//
module.exports = { createWalletandDID };
