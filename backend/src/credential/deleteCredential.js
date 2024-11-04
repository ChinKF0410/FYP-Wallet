/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const axios = require('axios');
const acaPyBaseUrl = 'http://127.0.0.1:7011';



// Function to store the credential (modified to take data from req.body)
const deleteCredential = async (req, res) => {
    const { credExId, jwtToken } = req.body; // Extract credExId and jwtToken from request body

    // Check if both credExId and jwtToken are provided
    if (!credExId || !jwtToken) {
        return res.status(400).json({ error: "credExId and jwtToken are required" });
    }

    try {
        console.log("Step 1: Received credExId and jwtToken from request body");
        console.log("credExId: ", credExId);
        console.log("\n\n\njwtToken:\n", jwtToken + "\n\n\n\n\n");

        //log the url
        console.log(`${acaPyBaseUrl}/issue-credential-2.0/records/${credExId}`);
        // delete
        const delteResponse = await axios.delete(
            `${acaPyBaseUrl}/issue-credential-2.0/records/${credExId}`,
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`,  // Use the JWT token from the request body
                    'Content-Type': 'application/json'
                }
            }
        );

        console.log("Offer deleted: ", delteResponse.data);

        // Send success response back to the client
        return res.status(200).json({
            message: "Credential delete successfully",
        });

    } catch (error) {
        console.error('Error deleted credential:', error.message);
        return res.status(500).json({ error: 'Failed to delete credential' });
    }
};



// Export the deleteCredential function
module.exports = {
    deleteCredential
};
