/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const sql = require('mssql');
const dbConfig = require('../config/dbConfigWallet'); // Assuming correct db config
const axios = require('axios');

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

async function UpdateActive(req, res) {
    try {
        console.log("update Active state");
        // Destructuring values from req.body
        const { issuance_date, credential_type, name, email } = req.body;

        // Validate the required fields
        if (!issuance_date || !credential_type || !name || !email) {
            return res.status(400).send('All fields are required');
        }

        const pool = await poolPromise;
        console.log(credential_type);
        console.log(name);
        // Query to update `IsPublic` and `Active` to 0 for the matching record
        const result = await pool.request()
            .input('issuance_date', sql.DateTime, issuance_date)
            .input('credential_type', sql.NVarChar(50), credential_type)
            .input('name', sql.NVarChar(50), name)
            .input('email', sql.NVarChar(50), email)
            .query(`
                UPDATE Certification
                SET IsPublic = 0, Active = 0
                WHERE CerName = @name
                AND CerEmail = @email
                AND CerType = @credential_type
                AND CerAcquiredDate = @issuance_date;
                
                SELECT AccountID, CerID, IsPublic
                FROM Certification
                WHERE CerName = @name
                AND CerEmail = @email
                AND CerType = @credential_type
                AND CerAcquiredDate = @issuance_date;
            `);
      
        // Check if exactly one row was affected
        if (result.rowsAffected[0] === 1) {
            console.log("Successfully updated 1 record.");

            // Get the updated record's data
            const updatedRecord = result.recordset[0];
            const { AccountID, CerID, IsPublic } = updatedRecord;

            // Log the updated record's data
            console.log("Updated Record:", updatedRecord);

            // Send the updated data to the backend
            await axios.post(
                `http://127.0.0.1:3010/api/deleteCVCertification`,
                {
                    accountID: AccountID,
                    CerID: CerID,
                    isPublic: IsPublic,
                }
            );

            res.json({ message: 'Record updated and data sent successfully' });
        } else if (result.rowsAffected[0] === 0) {
            res.status(404).send('No matching record found to update');
        } else {
            // This handles the rare case where multiple records may have been updated
            res.status(500).send('Multiple records were modified, which should not happen');
        }

    } catch (error) {
        console.error('SQL error', error);
        res.status(500).send('Internal Server Error');
    }
}

module.exports = { UpdateActive };
