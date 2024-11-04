/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const axios = require('axios');
const { getAuthToken, getWalletData } = require('./receiveConnection'); // Import functions from receiveConnection.js

async function receiveOffer(req, res) {
    try {
        // Extract the attributes and holder details from the request body
        const { holder } = req.body; // Include holder to fetch wallet data

        // Step 1: Get wallet data for the user
        const walletData = await getWalletData(holder);
        if (!walletData) {
            throw new Error(`Wallet not found for holder: ${holder}`);
        }

        // Step 2: Get JWT token for the user's wallet
        const jwtToken = await getAuthToken(walletData.wallet_id);

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

        let records = [];
        console.log("Fetched All records: ", recordsResponse);

        // Check if the response structure is valid and extract 'results'
        if (recordsResponse?.data?.results) {
            records = recordsResponse.data.results; // Fetch the list of credential exchange records
            console.log("Fetched records: ", records);
        } else {
            console.log("No records found or incorrect response structure.");
        }

        // Check if records exist
        if (records.length === 0) {
            return res.status(201).json({ message: 'No credential offers found.' });
        }

        const credentialsWithIds = records.map(record => {
            const credentialPreview = record.cred_ex_record?.cred_offer?.credential_preview || null;
            const attributes = credentialPreview?.attributes || [];

            // Extracting individual attributes from the credential preview
            const credentialType = attributes.find(attr => attr.name === "credentialType")?.value || "lissierdateadd";
            const issuerName = attributes.find(attr => attr.name === "issuerName")?.value || "ChinXh";
            const name = attributes.find(attr => attr.name === "name")?.value || "skddsje";
            const email = attributes.find(attr => attr.name === "email")?.value || "chuqing@gmail.com";
            const phoneNo = attributes.find(attr => attr.name === "phoneNo")?.value || "0194483310";
            const description = attributes.find(attr => attr.name === "description")?.value || "skdjde";
            const did = attributes.find(attr => attr.name === "did")?.value || "klk"; //modify did
            const issueDate = attributes.find(attr => attr.name === "issueDate")?.value || "2024-09-27";

            return {
                cred_ex_id: record.cred_ex_record?.cred_ex_id || 'N/A',  // The credential exchange ID
                credentialType,
                issuerName,
                name,
                email,
                phoneNo,
                description,
                did,
                issueDate
            };
        });

        console.log("Store Done");
        console.log('Pending Credential Record:', credentialsWithIds);

        // Respond with success message and credentials along with cred_ex_id and extracted attributes
        res.status(200).json({
            message: "Pending Credential Retrieve Successfully!",
            credentials: credentialsWithIds  // Pass credentials with individual attributes to frontend
        });

    } catch (error) {
        console.error('Error processing credential offer:', error.message);
        res.status(500).json({ message: 'Internal server error' });
    }
}


module.exports = { receiveOffer };