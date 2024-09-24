const sql = require('mssql');
const crypto = require('crypto');
const QRCode = require('qrcode');
const dbConfigWallet = require('../config/dbConfigWallet');
sql.globalConnectionPool = false;


// Initialize SQL connection pool
let poolPromise = sql.connect(dbConfigWallet)
    .then(pool => {
        console.log('Connected to MSSQL');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });

module.exports.generateQRCode = async (req, res) => {
    const { userID, PerID, EduBacID, CerID, IntelID, WorkExpID } = req.body;

    try {
        const pool = await poolPromise;

        const dataString = `PerID=${PerID};EduBacID=${EduBacID};CerID=${CerID};IntelID=${IntelID};WorkExpID=${WorkExpID}`;
        const timestamp = Date.now().toString();
        const dataToHash = `${userID}:${timestamp}:${dataString}`;
        const qrHash = crypto.createHash('sha256').update(dataToHash).digest('hex');

        const qrCodeBuffer = await QRCode.toBuffer(qrHash);

        const result = await pool.request()
            .input('userID', sql.Int, userID)
            .input('PerID', sql.VarChar, PerID)
            .input('EduBacIDs', sql.VarChar, EduBacID)
            .input('CerIDs', sql.VarChar, CerID)
            .input('IntelIDs', sql.VarChar, IntelID)
            .input('WorkExpIDs', sql.VarChar, WorkExpID)
            .input('QRHashCode', sql.VarChar, qrHash)
            .input('QRCodeImage', sql.VarBinary, qrCodeBuffer)
            .query(`
                INSERT INTO QRPermission 
                (UserID, PerID, EduBacIDs, CerIDs, IntelIDs, WorkExpIDs, QRHashCode, ExpireDate, QRCodeImage) 
                OUTPUT INSERTED.QRCodeImage
                VALUES (@userID, @PerID, @EduBacIDs, @CerIDs, @IntelIDs, @WorkExpIDs, @QRHashCode, DATEADD(DAY, 30, GETDATE()), @QRCodeImage);
            `);

        const qrCodeImageBase64 = result.recordset[0].QRCodeImage.toString('base64');

        res.status(201).json({
            qrHash,
            qrCodeImage: qrCodeImageBase64
        });
    } catch (err) {
        console.error('QR Code Generation Error: ', err);
        res.status(500).send('Server error');
    }
};

const formatDate = (datetime) => {
    if (!datetime) return null;
    const date = new Date(datetime);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
};

module.exports.searchQRCode = async (req, res) => {
    const { qrHashCode } = req.body;

    try {
        const pool = await poolPromise;

        const qrPermissionResult = await pool.request()
            .input('qrHashCode', sql.NVarChar, qrHashCode)
            .query(`
                SELECT * 
                FROM QRPermission 
                WHERE QRHashCode = @qrHashCode
                AND ExpireDate > GETDATE();
            `);

        if (qrPermissionResult.recordset.length === 0) {
            return res.status(404).send('QR code not found or expired.');
        }

        const qrPermissionData = qrPermissionResult.recordset[0];

        const splitIds = (idString) => {
            if (!idString) return [];
            return idString.replace(/;$/, '').split(';').map(id => id.trim()).filter(id => id !== '');
        };

        const fetchRelatedData = async (table, column, ids) => {
            const results = [];
            for (let id of ids) {
                const query = `SELECT * FROM ${table} WHERE CAST(${column} AS NVARCHAR) = @id`;
                const result = await pool.request()
                    .input('id', sql.NVarChar, id)
                    .query(query);
                results.push(...result.recordset);
            }
            return results;
        };

        const education = await fetchRelatedData('Education', 'EduBacID', splitIds(qrPermissionData.EduBacIDs));
        const qualification = await fetchRelatedData('Qualification', 'QuaID', splitIds(qrPermissionData.CerIDs));
        const softSkill = await fetchRelatedData('Skills', 'IntelID', splitIds(qrPermissionData.IntelIDs));
        const workExperience = await fetchRelatedData('Work', 'WorkExpID', splitIds(qrPermissionData.WorkExpIDs));
        const profile = qrPermissionData.PerID ? await fetchRelatedData('Profile', 'PerID', splitIds(qrPermissionData.PerID)) : null;

        // Format dates to 'YYYY-MM-DD'
        education.forEach(edu => {
            edu.EduStartDate = formatDate(edu.EduStartDate);
            edu.EduEndDate = formatDate(edu.EduEndDate);
        });

        qualification.forEach(quali => {
            quali.CerAcquiredDate = formatDate(quali.CerAcquiredDate);
        });

        workExperience.forEach(work => {
            work.WorkStartDate = formatDate(work.WorkStartDate);
            work.WorkEndDate = formatDate(work.WorkEndDate);
        });

        const responseData = {
            profile: profile ? profile[0] : null,
            education,
            qualification,
            softSkill,
            workExperience,
        };

        res.status(200).json(responseData);
    } catch (err) {
        console.error('QR Code Search Error: ', err);
        res.status(500).send('Server error');
    }
};


module.exports.fetchQRCodesByUserId = async (req, res) => {
    const accountID = req.query.accountID;

    if (!accountID) {
        return res.status(400).json({ error: "accountID is required" });
    }

    try {
        const pool = await poolPromise;
        const qrCodesResult = await pool.request()
            .input('accountID', sql.Int, accountID)  // Make sure 'AccountID' matches your DB schema
            .query(`
                SELECT QRHashCode, QRCodeImage, ExpireDate 
                FROM QRPermission 
                WHERE AccountID = @accountID AND ExpireDate > GETDATE()
            `);

        if (qrCodesResult.recordset.length === 0) {
            return res.status(404).send('No active QR codes found for this user.');
        }

        const qrCodes = qrCodesResult.recordset.map(record => ({
            qrHashCode: record.QRHashCode,
            qrCodeImage: record.QRCodeImage.toString('base64'),
            expireDate: record.ExpireDate.toISOString()
        }));

        res.status(200).json({ qrCodes });
    } catch (err) {
        console.error('Fetch QR Codes by AccountID Error:', err);
        res.status(500).send('Server error');
    }
};

