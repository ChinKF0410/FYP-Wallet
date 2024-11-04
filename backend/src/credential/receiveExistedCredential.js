/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const sql = require('mssql');
const dbConfig = require('../config/dbConfigWallet');

// Initialize the SQL connection pool
let poolPromise = sql.connect(dbConfig)
    .then(pool => {
        console.log('Connected to MSSQL Wallet DB');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });

// Function to fetch the credential based on email
async function receiveExistedCredential(req, res) {
    try {
        console.log("Fetching stored Credential");
        const { holder } = req.body;

        // Validate the required fields
        if (!holder) {
            return res.status(400).send('Holder Email is Required');
        }

        const pool = await poolPromise;

        // Query to fetch records based on the email
        const result = await pool.request()
            .input('email', sql.NVarChar(50), holder)
            .query(`
                SELECT CerName, CerEmail, CerType, CerIssuer, CerDescription, CerAcquiredDate, Active
                FROM Certification
                WHERE CerEmail = @email
                order by CerAcquiredDate desc
            `);

        // Check if any records were found
        if (result.recordset.length === 0) {
            return res.status(404).send('No Stored Credential');
        }

        // Format response data
        const credentials = result.recordset.map(credential => ({
            name: credential.CerName,
            email: credential.CerEmail,
            type: credential.CerType,
            issuer: credential.CerIssuer,
            description: credential.CerDescription,
            acquiredDate: credential.CerAcquiredDate,
            status: credential.Active === true ? 'Accepted' : 'Deleted By Issuer',
        }));
        res.status(200).json({ credentials });

    } catch (error) {
        console.error('SQL error', error);
        res.status(500).send('Internal Server Error');
    }
}

module.exports = { receiveExistedCredential };
