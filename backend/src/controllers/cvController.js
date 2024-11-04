/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const sql = require('mssql');
const dbConfigWallet = require('../config/dbConfigWallet');
const axios = require('axios'); // Use axios for making HTTP requests from the backend
sql.globalConnectionPool = false;

// Initialize SQL connection pool
let poolPromise = new sql.connect(dbConfigWallet)
    .then(pool => {
        console.log('Connected to MSSQL Wallet DB');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });


// ACCOUNT MANAGEMENT
module.exports.saveProfile = async (req, res) => {
    const { accountID, firstName, lastName, mobilePhone, email, icNumber, Photo } = req.body;
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }
    try {
        const pool = await poolPromise;
        const profilePicBuffer = Photo ? Buffer.from(Photo, 'base64') : null;

        // Check if the profile already exists
        const checkQuery = `
            SELECT COUNT(*) AS count FROM Person WHERE AccountID = @accountID`;
        const checkResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(checkQuery);
        const recordExists = checkResult.recordset[0].count > 0;

        let query;
        let binaryPhoto = null;

        if (recordExists) {
            // Update the existing record
            query = `
                UPDATE Person 
                SET First_Name = @firstName, 
                    Last_Name = @lastName, 
                    Mobile_Number = @mobilePhone, 
                    Email_Address = @email, 
                    Identity_Code = @icNumber`;
            if (Photo) {
                binaryPhoto = Buffer.from(Photo, 'base64'); // Decode base64 to binary
                query += `, Photo = @Photo`;
            }
            query += ` WHERE AccountID = @accountID`;
        } else {
            // Insert a new record
            query = `
                INSERT INTO Person (AccountID, First_Name, Last_Name, Mobile_Number, Email_Address, Identity_Code, Photo)
                VALUES (@accountID, @firstName, @lastName, @mobilePhone, @email, @icNumber, @Photo)`;
            if (Photo) {
                binaryPhoto = Buffer.from(Photo, 'base64'); // Decode base64 to binary
            }
        }

        // Prepare the request with inputs
        const request = pool.request()
            .input('accountID', sql.Int, accountID)
            .input('firstName', sql.NVarChar, firstName)
            .input('lastName', sql.NVarChar, lastName)
            .input('mobilePhone', sql.NVarChar, mobilePhone)
            .input('email', sql.NVarChar, email)
            .input('icNumber', sql.NVarChar, icNumber);
        if (binaryPhoto) {
            request.input('Photo', sql.VarBinary(sql.MAX), profilePicBuffer);
        } else {
            request.input('Photo', sql.VarBinary(sql.MAX), null);  // Set Photo as null if not provided
        }

        // Execute the query
        await request.query(query);
        const action = recordExists ? 'Profile updated successfully' : 'Profile created successfully';
        res.status(200).send(action);
    } catch (err) {
        console.error('Error saving profile:', err.message);
        res.status(500).send('Server error: ' + err.message);
    }
};

// Get User Profile
module.exports.getProfile = async (req, res) => {
    const accountID = req.query.accountID;
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query('SELECT First_Name, Last_Name, Mobile_Number, Email_Address, Identity_Code, Photo FROM Person WHERE AccountID = @accountID');
        if (result.recordset.length > 0) {
            const profile = result.recordset[0];
            // Convert Photo binary data to base64 string
            if (profile.Photo) {
                profile.Photo = Buffer.from(profile.Photo).toString('base64');
            }
            res.json(profile);
        } else {
            res.status(404).send('Profile not found');
        }
    } catch (err) {
        console.error('Error fetching profile data:', err.message);
        res.status(500).send('Server error: ' + err.message);
    }
};

// Get Account Email
module.exports.getAccountEmail = async (req, res) => {
    const accountID = req.query.accountID;

    if (!accountID) {
        return res.status(400).json({ error: 'Account ID is required' });
    }

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query('SELECT Email FROM Account WHERE AccountID = @accountID');

        if (result.recordset.length > 0) {
            res.status(200).json({ Email: result.recordset[0].Email });
        } else {
            res.status(404).json({ error: 'Email not found for the given account ID' });
        }
    } catch (err) {
        console.error('Database query error:', err.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};


// CV MANAGEMENT
// CV Profile


module.exports.saveCVProfile = async (req, res) => {
    const {
        accountID, Photo, name, age, email_address, mobile_number, address, description, PerID: passedPerID
    } = req.body;

    console.log("Try to save profile data:  " + passedPerID);

    try {
        // Fetch the connection pool
        const pool = await poolPromise;
        const profilePicBuffer = Photo ? Buffer.from(Photo, 'base64') : null;
        let PerID = passedPerID;
        // If PerID is passed from frontend, try to update the existing profile
        if (PerID != 0) {
            console.log(`Attempting to update profile with PerID: ${PerID}`);
            // Try updating the profile using the provided PerID
            const updateResult = await pool.request()
                .input('PerID', sql.Int, PerID)
                .input('AccountID', sql.Int, accountID)
                .input('Photo', sql.VarBinary(sql.MAX), profilePicBuffer)
                .input('Name', sql.NVarChar, name)
                .input('Age', sql.Int, age)
                .input('Email_Address', sql.NVarChar, email_address)
                .input('Mobile_Number', sql.NVarChar, mobile_number)
                .input('Address', sql.NVarChar, address)
                .input('Description', sql.NVarChar, description)
                .query(`
                    UPDATE Profile
                    SET Photo = @Photo, Name = @Name, Age = @Age, Email_Address = @Email_Address, 
                        Mobile_Number = @Mobile_Number, Address = @Address, Description = @Description
                    OUTPUT INSERTED.PerID
                    WHERE PerID = @PerID AND AccountID = @AccountID
                `);

            // Check if update was successful
            if (updateResult.recordset.length === 0) {
                console.error(`No profile found with PerID: ${PerID} for AccountID: ${accountID}`);
                return res.status(404).send('Profile not found for update.');
            }

            // Use the returned PerID after the update
            PerID = updateResult.recordset[0]?.PerID;

        } else {
            // If PerID is not provided, insert a new profile and return the new PerID
            console.log("No PerID provided, inserting new profile.");
            const insertResult = await pool.request()
                .input('AccountID', sql.Int, accountID)
                .input('Photo', sql.VarBinary(sql.MAX), profilePicBuffer)
                .input('Name', sql.NVarChar, name)
                .input('Age', sql.Int, age)
                .input('Email_Address', sql.NVarChar, email_address)
                .input('Mobile_Number', sql.NVarChar, mobile_number)
                .input('Address', sql.NVarChar, address)
                .input('Description', sql.NVarChar, description)
                .query(`
                    INSERT INTO Profile (
                        AccountID, Photo, Name, Age, Email_Address, Mobile_Number, Address, Description
                    ) OUTPUT INSERTED.PerID VALUES (
                        @AccountID, @Photo, @Name, @Age, @Email_Address, @Mobile_Number, @Address, @Description
                    )
                `);

            // Retrieve the new PerID from the insert result
            PerID = insertResult.recordset[0]?.PerID;
        }

        // If no PerID was returned, something went wrong
        if (!PerID) {
            console.error("Failed to generate or retrieve PerID.");
            return res.status(501).send('Fail to Save Profile: No PerID generated.');
        }

        console.log("PerID:", PerID);

        // Call the second API, passing the PerID and other profile data
        const secondApiUrl = 'http://127.0.0.1:3010/api/saveCVProfile';
        const profileData = { ...req.body, PerID }; // Add PerID to profile data

        try {
            const secondApiResponse = await axios.post(secondApiUrl, profileData, {
                headers: { 'Content-Type': 'application/json' }
            });

            console.log('Second API response:', secondApiResponse.data);

            // Return success response to the frontend
            res.status(200).json({
                message: PerID ? 'Profile updated successfully' : 'Profile created successfully',
                PerID,
                secondApiResponse: secondApiResponse.data
            });

        } catch (secondApiError) {
            console.error('Error calling second API:', secondApiError.message);
            return res.status(502).send('Failed to Save Into Second Database: ' + secondApiError.message);
        }

    } catch (error) {
        console.error('Error saving profile:', error);
        return res.status(500).send('Failed to save profile.');
    }
};




// Get CV Profile 
module.exports.getCVProfile = async (req, res) => {
    const accountID = req.query.accountID;
    console.log('Received AccountID:', accountID);
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT Name AS name, Age AS age, Email_Address AS email, Mobile_Number AS phone, 
                    Address AS address, Description AS description, Photo AS profile_image_path, PerID
                FROM Profile 
                WHERE AccountID = @accountID`);

        // Check if any profile data was found
        if (result.recordset.length === 0) {
            return res.status(404).send('No profile data found');
        }
        const profile = result.recordset[0];
        console.log("Found PerID: " + profile.PerID);

        // Check if profile_image_path exists and convert it to base64 if it does
        if (profile.profile_image_path) {
            profile.Photo = Buffer.from(profile.profile_image_path).toString('base64');
        } else {
            profile.Photo = null; // Set to null if no photo is available
        }

        return res.status(200).send(profile);
    } catch (err) {
        console.error('Server error:', err);
        return res.status(500).send('Server error');
    }
};


// Get Default Person Info : Name, Email, Phone
module.exports.getPersonDetails = async (req, res) => {
    const accountID = req.query.accountID;

    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const pool = await poolPromise;

        // SQL query to get email, full name, and mobile number
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT 
                    Email_Address AS Email, 
                    Last_Name + ' ' + First_Name AS FullName, 
                    Mobile_Number 
                FROM 
                    Person 
                WHERE 
                    AccountID = @accountID
            `);

        if (result.recordset.length > 0) {
            res.status(200).json(result.recordset[0]); // Return the first matching record
        } else {
            res.status(404).send('Person not found');
        }
    } catch (error) {
        console.error('Error fetching person details:', error);
        res.status(500).send('Failed to fetch person details');
    }
};


// CV Education
//Save CV Education
module.exports.saveCVEducation = async (req, res) => {
    const { accountID, newEducationEntries, existingEducationEntries } = req.body;
    console.log("newEducationEntries: " + newEducationEntries);
    console.log("existingEducationEntries123: " + existingEducationEntries);

    let newEducationsWithID = []; // Array to store newly inserted education entries with their EduBacID

    try {
        const pool = await poolPromise;

        // Process existing entries (updates)
        if (existingEducationEntries && existingEducationEntries.length > 0) {
            console.log("Exist");
            for (let entry of existingEducationEntries) {
                console.log("existingEducationEntries: " + existingEducationEntries);

                const {
                    EduBacID, level, field_of_study, institute_name, institute_country, institute_city, institute_state, start_date, end_date, isPublic
                } = entry;
                console.log("level: " + level);

                await pool.request()
                    .input('EduBacID', sql.Int, EduBacID)
                    .input('LevelEdu', sql.NVarChar, level)
                    .input('FieldOfStudy', sql.NVarChar, field_of_study)
                    .input('InstituteName', sql.NVarChar, institute_name)
                    .input('InstituteCountry', sql.NVarChar, institute_country)
                    .input('InstituteCity', sql.NVarChar, institute_city)
                    .input('InstituteState', sql.NVarChar, institute_state)
                    .input('EduStartDate', sql.NVarChar, start_date)
                    .input('EduEndDate', sql.NVarChar, end_date)
                    .input('IsPublic', sql.Bit, isPublic)
                    .query(`
                        UPDATE Education
                        SET LevelEdu = @LevelEdu, FieldOfStudy = @FieldOfStudy, InstituteName = @InstituteName, 
                            InstituteCountry = @InstituteCountry, InstituteCity = @InstituteCity, 
                            InstituteState = @InstituteState, EduStartDate = @EduStartDate, EduEndDate = @EduEndDate,
                            IsPublic = @IsPublic
                        WHERE EduBacID = @EduBacID
                    `);
            }
        }
        // Process new entries (inserts)
        if (newEducationEntries && newEducationEntries.length > 0) {
            for (let entry of newEducationEntries) {
                console.log("New");
                const {
                    level, field_of_study, institute_name, institute_country, institute_city, institute_state, start_date, end_date, isPublic
                } = entry;

                // Capture the result of the insert query
                const result = await pool.request()
                    .input('AccountID', sql.Int, accountID)
                    .input('LevelEdu', sql.NVarChar, level)
                    .input('FieldOfStudy', sql.NVarChar, field_of_study)
                    .input('InstituteName', sql.NVarChar, institute_name)
                    .input('InstituteCountry', sql.NVarChar, institute_country)
                    .input('InstituteCity', sql.NVarChar, institute_city)
                    .input('InstituteState', sql.NVarChar, institute_state)
                    .input('EduStartDate', sql.NVarChar, start_date)
                    .input('EduEndDate', sql.NVarChar, end_date)
                    .input('IsPublic', sql.Bit, isPublic)
                    .query(`
                        INSERT INTO Education (AccountID, LevelEdu, FieldOfStudy, InstituteName, InstituteCountry, 
                            InstituteCity, InstituteState, EduStartDate, EduEndDate, IsPublic)
                        OUTPUT INSERTED.EduBacID
                        VALUES (@AccountID, @LevelEdu, @FieldOfStudy, @InstituteName, @InstituteCountry, 
                            @InstituteCity, @InstituteState, @EduStartDate, @EduEndDate, @IsPublic)
                    `);

                // Add the inserted EduBacID to the array
                if (result.recordset && result.recordset.length > 0) {
                    console.log(result.recordset[0].EduBacID);
                    const insertedEntry = result.recordset[0];
                    newEducationsWithID.push({
                        EduBacID: insertedEntry.EduBacID,                          // No change
                        accountID: accountID,                        // Changed 'AccountID' to 'accountID'
                        level: level,                             // Changed 'LevelEdu' to 'level'
                        field_of_study: field_of_study,                // Changed 'FieldOfStudy' to 'field_of_study'
                        institute_name: institute_name,               // Changed 'InstituteName' to 'institute_name'
                        institute_country: institute_country,         // Changed 'InstituteCountry' to 'institute_country'
                        institute_city: institute_city,               // Changed 'InstituteCity' to 'institute_city'
                        institute_state: institute_state,             // Changed 'InstituteState' to 'institute_state'
                        start_date: start_date,                    // Changed 'EduStartDate' to 'start_date'
                        end_date: end_date,                        // Changed 'EduEndDate' to 'end_date'
                        isPublic: isPublic                           // No change
                    });
                    console.log(newEducationsWithID[0].EduBacID);
                } else {
                    console.error("Insert failed, no EduBacID returned.");
                }

            }
        }

        const educationEntries = [...existingEducationEntries, ...newEducationsWithID];


        console.log("Before Pass:2");
        console.log("educationEntries: " + educationEntries[0].EduBacID);
        console.log("educationEntries: " + educationEntries[0].start_date);


        const secondApiUrl = 'http://127.0.0.1:3010/api/saveCVEducation';
        const secondApiData = { ...req.body, educationEntries }; // Pass the inserted entries with EduBacID
        try {
            const secondApiResponse = await axios.post(secondApiUrl, secondApiData, {
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            // Log response from the second API if necessary
            console.log('Second API response:', secondApiResponse.data);

            res.status(200).json({
                newEducationsWithID: newEducationsWithID,
            });
            console.log("Success");
        } catch (secondApiError) {
            console.error('Error calling second API:', secondApiError.message);
            res.status(500).send('Error calling second API: ' + secondApiError.message);
        }
    } catch (error) {
        console.error('Error saving education info:', error);
        res.status(500).send('Failed to save education info');
    }
};

// Get CV Education
module.exports.getCVEducation = async (req, res) => {
    const accountID = req.query.accountID;
    console.log('Received AccountID:', accountID);

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT EduBacID AS eduBacID, LevelEdu AS level, FieldOfStudy AS field_of_study, 
                    InstituteName AS institute_name, InstituteCountry AS institute_country, 
                    InstituteState AS institute_state, InstituteCity AS institute_city, 
                    EduStartDate AS start_date, EduEndDate AS end_date, IsPublic AS isPublic
                FROM Education
                WHERE AccountID = @accountID
            `);

        console.log('Query Result:', result.recordset);

        if (result.recordset.length === 0) {
            res.status(404).send('No education data found');
        } else {
            res.json(result.recordset);
        }
    } catch (err) {
        console.error('Server error:', err);
        res.status(500).send('Server error');
    }
};

module.exports.deleteCVEducation = async (req, res) => {
    const { EduBacID } = req.body;

    if (!EduBacID) {
        return res.status(400).json({ message: 'EduBacID is required' });
    }

    try {
        const pool = await poolPromise;

        // Directly delete the education entry based on the RefID (EduBacID)
        const deleteResult = await pool.request()
            .input('EduBacID', sql.Int, EduBacID)
            .query(`
                DELETE FROM Education
                WHERE EduBacID = @EduBacID
            `);

        // Check if any rows were affected (i.e., entry was deleted)
        if (deleteResult.rowsAffected[0] > 0) {
            // Return 200 status code for successful deletion

            const secondApiUrl = 'http://127.0.0.1:3010/api/deleteCVEducation';


            try {
                const secondApiResponse = await axios.post(secondApiUrl, { EduBacID }, {
                    headers: { 'Content-Type': 'application/json' }
                });

                console.log('Second API response:', secondApiResponse.data);

                // Return success response to the frontend
                return res.status(200).json({ message: 'Education entry deleted successfully' });

            } catch (secondApiError) {
                console.error('Error calling second API:', secondApiError.message);
                return res.status(502).send('Failed to Save Into Second Database: ' + secondApiError.message);
            }

        } else {
            // Return 201 status code if no matching entry was found
            return res.status(201).json({ message: 'Education entry not found' });
        }


    } catch (error) {
        console.error('Error deleting education entry:', error.message);
        return res.status(500).json({ message: 'Error deleting education entry' });
    }
};

// CV Work
// Save CV Work
module.exports.saveCVWork = async (req, res) => {
    const { accountID, newWorkEntries, existingWorkEntries } = req.body;

    try {
        const pool = await poolPromise;
        let newWorkWithID = []; // Array to store newly inserted work entries with their WorkExpID
        console.log(req.body);
        // Process existing work entries (updates)
        if (existingWorkEntries && existingWorkEntries.length > 0) {
            for (let entry of existingWorkEntries) {
                const {
                    WorkExpID, job_title, company_name, industry,
                    country, state, city, description, start_date, end_date, isPublic
                } = entry;
                await pool.request()
                    .input('WorkExpID', sql.Int, WorkExpID)
                    .input('WorkTitle', sql.NVarChar, job_title)
                    .input('WorkCompany', sql.NVarChar, company_name)
                    .input('WorkIndustry', sql.NVarChar, industry)
                    .input('WorkCountry', sql.NVarChar, country)
                    .input('WorkState', sql.NVarChar, state)
                    .input('WorkCity', sql.NVarChar, city)
                    .input('WorkDescription', sql.NVarChar, description)
                    .input('WorkStartDate', sql.NVarChar, start_date)
                    .input('WorkEndDate', sql.NVarChar, end_date)
                    .input('IsPublic', sql.Bit, isPublic)  // Including isPublic in the update
                    .query(`
                        UPDATE Work
                        SET WorkTitle = @WorkTitle, WorkCompany = @WorkCompany,
                            WorkIndustry = @WorkIndustry, WorkCountry = @WorkCountry, WorkState = @WorkState,
                            WorkCity = @WorkCity, WorkDescription = @WorkDescription, WorkStartDate = @WorkStartDate,
                            WorkEndDate = @WorkEndDate, IsPublic = @IsPublic
                        WHERE WorkExpID = @WorkExpID
                    `);
            }
        }

        // Process new work entries (inserts)
        if (newWorkEntries && newWorkEntries.length > 0) {
            for (let entry of newWorkEntries) {
                const {
                    job_title, company_name, industry,
                    country, state, city, description, start_date, end_date, isPublic
                } = entry;

                const result = await pool.request()
                    .input('AccountID', sql.Int, accountID)
                    .input('WorkTitle', sql.NVarChar, job_title)
                    .input('WorkCompany', sql.NVarChar, company_name)
                    .input('WorkIndustry', sql.NVarChar, industry)
                    .input('WorkCountry', sql.NVarChar, country)
                    .input('WorkState', sql.NVarChar, state)
                    .input('WorkCity', sql.NVarChar, city)
                    .input('WorkDescription', sql.NVarChar, description)
                    .input('WorkStartDate', sql.NVarChar, start_date)
                    .input('WorkEndDate', sql.NVarChar, end_date)
                    .input('IsPublic', sql.Bit, isPublic)  // Including isPublic in the insert
                    .query(`
                        INSERT INTO Work (AccountID, WorkTitle, WorkCompany, WorkIndustry, 
                                          WorkCountry, WorkState, WorkCity, WorkDescription, WorkStartDate, WorkEndDate, IsPublic)
                        OUTPUT INSERTED.WorkExpID
                        VALUES (@AccountID, @WorkTitle, @WorkCompany, @WorkIndustry, 
                                @WorkCountry, @WorkState, @WorkCity, @WorkDescription, @WorkStartDate, @WorkEndDate, @IsPublic)
                    `);

                newWorkWithID.push({
                    WorkExpID: result.recordset[0].WorkExpID,
                    job_title,
                    company_name,
                    industry,
                    country,
                    state,
                    city,
                    description,
                    start_date,
                    end_date,
                    isPublic,
                });
                console.log("123");
                console.log("WorkExpID: " + result.recordset[0].WorkExpID);
            }
        }
        const workEntries = [...existingWorkEntries, ...newWorkWithID];
        console.log(workEntries[0]);

        const secondApiUrl = 'http://127.0.0.1:3010/api/saveCVWork';
        const secondApiData = { ...req.body, workEntries }; // Pass the inserted entries with EduBacID
        try {
            const secondApiResponse = await axios.post(secondApiUrl, secondApiData, {
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            // Log response from the second API if necessary
            console.log('Second API response:', secondApiResponse.data);

            res.status(200).json({
                newWorkWithID: newWorkWithID,
            });
            console.log("Success");
        } catch (secondApiError) {
            console.error('Error calling second API:', secondApiError.message);
            res.status(500).send('Error calling second API: ' + secondApiError.message);
        }
    } catch (error) {
        console.error('Error saving work info:', error);
        res.status(500).send('Failed to save work info');
    }
};

// Get CV Work 
module.exports.getCVWork = async (req, res) => {
    const accountID = req.query.accountID;
    console.log('Received AccountID:', accountID);

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT
                    WorkExpID AS WorkExpID, 
                    WorkTitle AS job_title, 
                    WorkCompany AS company_name, 
                    WorkIndustry AS industry, 
                    WorkCountry AS country, 
                    WorkState AS state, 
                    WorkCity AS city, 
                    WorkDescription AS description, 
                    WorkStartDate AS start_date, 
                    WorkEndDate AS end_date,
                    isPublic AS isPublic
                FROM Work
                WHERE AccountID = @accountID
            `);

        console.log('Query Result:', result.recordset);

        if (result.recordset.length === 0) {
            res.status(200).send('No work data found');
        } else {
            res.json(result.recordset);
        }
    } catch (err) {
        console.error('Server error:', err);
        res.status(500).send('Server error');
    }
};

// Delete CV Work
module.exports.deleteCVWork = async (req, res) => {
    const { WorkExpID } = req.body;

    try {
        const pool = await poolPromise;

        // Check if the work experience entry exists
        const existingWork = await pool.request()
            .input('WorkExpID', sql.Int, WorkExpID)
            .query('SELECT COUNT(*) AS count FROM Work WHERE WorkExpID = @WorkExpID');

        if (existingWork.recordset[0].count > 0) {
            // Delete the work experience entry
            await pool.request()
                .input('WorkExpID', sql.Int, WorkExpID)
                .query('DELETE FROM Work WHERE WorkExpID = @WorkExpID');
            const secondApiUrl = 'http://127.0.0.1:3010/api/deleteCVWork';


            try {
                const secondApiResponse = await axios.post(secondApiUrl, { WorkExpID }, {
                    headers: { 'Content-Type': 'application/json' }
                });

                console.log('Second API response:', secondApiResponse.data);

                // Return success response to the frontend
                return res.status(200).json({ message: 'Work experience deleted successfully' });


            } catch (secondApiError) {
                console.error('Error calling second API:', secondApiError.message);
                return res.status(502).send('Failed to Save Into Second Database: ' + secondApiError.message);
            }
        } else {
            res.status(404).json({ message: 'Work experience not found' });
        }
    } catch (error) {
        console.error('Error deleting work experience:', error.message);
        res.status(500).json({ message: 'Error deleting work experience' });
    }
};

module.exports.saveCVCertification = async (req, res) => {
    const { accountID, CerName, CerEmail, CerType, CerIssuer, CerDescription, CerAcquiredDate } = req.body;
    const IsPublic = 1;

    // Validate input
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }
    if (!CerName || !CerIssuer || !CerAcquiredDate) {
        return res.status(400).send('Certification Name, Issuer, and Acquired Date are required');
    }

    try {
        const pool = await poolPromise;

        // Insert new certification into the Certification table
        const result = await pool.request()
            .input('AccountID', sql.Int, accountID)
            .input('CerName', sql.NVarChar(50), CerName)
            .input('CerEmail', sql.NVarChar(50), CerEmail)
            .input('CerType', sql.NVarChar(50), CerType)
            .input('CerIssuer', sql.NVarChar(50), CerIssuer)
            .input('CerDescription', sql.NVarChar(200), CerDescription)
            .input('CerAcquiredDate', sql.DateTime, CerAcquiredDate)
            .input('IsPublic', sql.Bit, IsPublic)
            .input('Active', sql.Bit, IsPublic)
            .query(`
                INSERT INTO Certification (AccountID, CerName, CerEmail, CerType, CerIssuer, CerDescription, CerAcquiredDate, IsPublic, Active)
                OUTPUT INSERTED.CerID
                VALUES (@AccountID, @CerName, @CerEmail, @CerType, @CerIssuer, @CerDescription, @CerAcquiredDate, @IsPublic, @Active)
            `);

        const CerID = result.recordset[0].CerID;

        // Call the second function and pass the necessary data
        const secondApiUrl = 'http://127.0.0.1:3010/api/saveCVCertification'; // Update with the actual URL if needed
        const secondApiData = {
            accountID,  // Account ID to be used as StudentAccID in the second function
            CerID,      // CerID from the first function passed as RefID in the second function
            CerName,
            CerEmail,
            CerType,
            CerIssuer,
            CerDescription,
            CerAcquiredDate
        };

        const axios = require('axios'); // Assuming you're using Axios for the HTTP call

        const secondApiResponse = await axios.post(secondApiUrl, secondApiData, {
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (secondApiResponse.status === 200) {
            res.status(200).json({
                message: 'Certification saved successfully in both databases',
                CerID,
                CerName,
                CerEmail,
                CerType,
                CerIssuer,
                CerDescription,
                CerAcquiredDate,
                IsPublic,
                secondApiResponse: secondApiResponse.data
            });
        } else if (secondApiResponse.status === 501) {
            res.status(501).json({ message: 'Error saving certification in the second database' });

        }

    } catch (error) {
        console.error('Error saving certification:', error.message);
        res.status(500).send('Server error');
    }
};


module.exports.getCVCertifications = async (req, res) => {
    const { accountID } = req.body;

    // Validate input
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const pool = await poolPromise;

        // Fetch all certifications for the given accountID
        const result = await pool.request()
            .input('AccountID', sql.Int, accountID)
            .query(`
                SELECT CerID, CerName, CerEmail, CerType, CerIssuer, CerDescription, CerAcquiredDate, IsPublic
                FROM Certification
                WHERE AccountID = @AccountID
            `);

        if (result.recordset.length === 0) {
            return res.status(404).send('No certifications found for this account');
        }

        // Return the list of certifications
        res.status(200).json(result.recordset);
    } catch (error) {
        console.error('Error fetching certifications:', error.message);
        res.status(500).send('Server error');
    }
};

module.exports.saveCVSkill = async (req, res) => {
    const { accountID, newSkillEntries, existingSkillEntries } = req.body;

    // Validate input
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const pool = await poolPromise;
        let newSkillsWithID = []; // Array to store newly inserted skills with their SoftID

        // Process existing skills (updates)
        if (existingSkillEntries && existingSkillEntries.length > 0) {
            for (const skill of existingSkillEntries) {
                const { SoftID, SoftHighlight, SoftDescription, isPublic, SoftLevel } = skill;

                // Validate SoftLevel is between 1 and 5
                if (SoftLevel < 1 || SoftLevel > 5) {
                    return res.status(400).send('Invalid SoftLevel value. It must be between 1 and 5.');
                }

                // Update the existing skill in the SoftSkill table
                await pool.request()
                    .input('SoftID', sql.Int, SoftID)
                    .input('SoftHighlight', sql.NVarChar, SoftHighlight)
                    .input('SoftDescription', sql.NVarChar, SoftDescription)
                    .input('IsPublic', sql.Bit, isPublic)
                    .input('SoftLevel', sql.Int, SoftLevel) // Add SoftLevel input
                    .query(`
                        UPDATE SoftSkill
                        SET SoftHighlight = @SoftHighlight, SoftDescription = @SoftDescription, IsPublic = @IsPublic, SoftLevel = @SoftLevel
                        WHERE SoftID = @SoftID
                    `);
            }
        }

        // Process new skills (inserts)
        if (newSkillEntries && newSkillEntries.length > 0) {
            for (const skill of newSkillEntries) {
                const { SoftHighlight, SoftDescription, isPublic, SoftLevel } = skill;

                // Validate SoftLevel is between 1 and 5
                if (SoftLevel < 1 || SoftLevel > 5) {
                    return res.status(400).send('Invalid SoftLevel value. It must be between 1 and 5.');
                }

                // Insert new skill into the SoftSkill table
                const result = await pool.request()
                    .input('AccountID', sql.Int, accountID)
                    .input('SoftHighlight', sql.NVarChar, SoftHighlight)
                    .input('SoftDescription', sql.NVarChar, SoftDescription)
                    .input('IsPublic', sql.Bit, isPublic)
                    .input('SoftLevel', sql.Int, SoftLevel) // Add SoftLevel input
                    .query(`
                        INSERT INTO SoftSkill (AccountID, SoftHighlight, SoftDescription, IsPublic, SoftLevel)
                        OUTPUT INSERTED.SoftID
                        VALUES (@AccountID, @SoftHighlight, @SoftDescription, @IsPublic, @SoftLevel)
                    `);

                // Add newly inserted SoftID to the response array
                newSkillsWithID.push({
                    SoftID: result.recordset[0].SoftID,
                    SoftHighlight,
                    SoftDescription,
                    SoftLevel,  // Include SoftLevel in the response
                    isPublic,
                });
            }
        }

        const skillEntries = [...existingSkillEntries, ...newSkillsWithID];
        const secondApiUrl = 'http://127.0.0.1:3010/api/saveCVSkill';
        const secondApiData = { ...req.body, skillEntries }; // Pass the inserted entries with EduBacID
        try {
            const secondApiResponse = await axios.post(secondApiUrl, secondApiData, {
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            // Log response from the second API if necessary
            console.log('Second API response:', secondApiResponse.data);

            res.status(200).json({
                newSkillsWithID: newSkillsWithID,
            });
            console.log("Success");
        } catch (secondApiError) {
            console.error('Error calling second API:', secondApiError.message);
            res.status(500).send('Error calling second API: ' + secondApiError.message);
        }
    } catch (error) {
        console.error('Error saving skills:', error.message);
        res.status(500).send('Server error');
    }
};

// Get CV Skill 
module.exports.getCVSkill = async (req, res) => {
    const accountID = req.query.accountID;
    console.log('Received AccountID:', accountID);

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('AccountID', sql.Int, accountID)
            .query(`
                SELECT 
                    SoftID AS SoftID,
                    SoftHighlight AS SoftHighlight,
                    SoftDescription AS SoftDescription,
                    SoftLevel AS SoftLevel,  -- Include SoftLevel in the query
                    isPublic AS isPublic
                FROM SoftSkill
                WHERE AccountID = @AccountID
            `);

        console.log('Query Result:', JSON.stringify(result.recordset, null, 2));

        if (result.recordset.length === 0) {
            res.status(404).send('No soft skill data found');
        } else {
            res.json(result.recordset);  // Return the skill data with SoftLevel
        }
    } catch (err) {
        console.error('Server error:', err);
        res.status(500).send('Server error');
    }
};


// Delete CV Skill
module.exports.deleteCVSkill = async (req, res) => {
    const { SoftID } = req.body;

    // Validate input
    if (!SoftID) {
        return res.status(400).send('SoftID is required');
    }

    try {
        const pool = await poolPromise;

        // Check if the skill exists
        const existingSkill = await pool.request()
            .input('SoftID', sql.Int, SoftID)
            .query('SELECT COUNT(*) AS count FROM SoftSkill WHERE SoftID = @SoftID');

        if (existingSkill.recordset[0].count === 0) {
            return res.status(404).send('Skill not found');
        }

        // Delete the skill from the database
        await pool.request()
            .input('SoftID', sql.Int, SoftID)
            .query('DELETE FROM SoftSkill WHERE SoftID = @SoftID');
        const secondApiUrl = 'http://127.0.0.1:3010/api/deleteCVSkill';


        try {
            const secondApiResponse = await axios.post(secondApiUrl, { SoftID }, {
                headers: { 'Content-Type': 'application/json' }
            });

            console.log('Second API response:', secondApiResponse.data);

            // Return success response to the frontend
            return res.status(200).send('Skill deleted successfully');

        } catch (secondApiError) {
            console.error('Error calling second API:', secondApiError.message);
            return res.status(502).send('Failed to Save Into Second Database: ' + secondApiError.message);
        }
    } catch (error) {
        console.error('Error deleting skill:', error.message);
        res.status(500).send('Server error');
    }
};





// Get Certifications
module.exports.getCertifications = async (req, res) => {
    const accountID = req.query.accountID;
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT 
                CerID,
                  CerName AS [Name], 
                  CerEmail AS [Email], 
                  CerType AS [CertificationType], 
                  CerIssuer AS [Issuer], 
                  CerDescription AS [Description], 
                  CerAcquiredDate AS [CertificationAcquireDate],
                  isPublic AS isPublic,
                  Active As Active
                FROM 
                  Certification 
                WHERE 
                  AccountID = @accountID
            `);

        console.log(result.recordset); // Log the result for debugging purposes
        res.json({ certifications: result.recordset });
    } catch (error) {
        console.error('Error fetching certifications:', error);
        res.status(500).send('Internal Server Error');
    }
};


module.exports.updateCertificationStatus = async (req, res) => {
    const { accountID, CerID, isPublic, certification } = req.body;
    console.log(accountID);
    console.log(CerID);
    console.log(isPublic);

    console.log("========");

    if (!accountID || !CerID) {
        console.log("Missing accountID or certification data");
        return res.status(400).send('Missing required fields');
    }

    try {
        const pool = await poolPromise;

        // Extract data from the certification object
        // Update the Certification table in the database
        await pool.request()
            .input('accountID', sql.Int, accountID)
            .input('CerID', sql.Int, CerID)
            .input('isPublic', sql.Int, isPublic)
            .query(`
              UPDATE Certification
              SET IsPublic = @isPublic
              WHERE AccountID = @accountID AND CerID = @CerID
            `);

        console.log("Certification visibility updated successfully");

        // Determine the external API URL based on the isPublic value
        const apiUrl = isPublic
            ? 'http://127.0.0.1:3010/api/updateCVCertification'
            : 'http://127.0.0.1:3010/api/deleteCVCertification';
        console.log(apiUrl);
        // Prepare the certification object for the external API call
        const certData = {
            accountID: accountID,
            CerID,
            isPublic,
            certification,
        };

        console.log(`Calling ${isPublic ? 'save' : 'delete'} certification API: ${apiUrl}`);

        // Make the external API call
        const response = await fetch(apiUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(certData),
        });

        if (!response.ok) {
            throw new Error(`Failed to call external API: ${response.statusText}`);
        }

        console.log(`API call to ${apiUrl} successful`);
        res.status(200).send('Public status updated and external API call successful');
    } catch (error) {
        console.error('Error updating public status or calling external API:', error);
        res.status(500).send('Internal Server Error');
    }
};








// Save CV Qualification Info
module.exports.saveCVQuali = async (req, res) => {
    const { accountID, qualifications } = req.body;

    try {
        const pool = await poolPromise;
        let newQualificationsWithID = [];

        // Process existing qualifications (updates)
        if (qualifications && qualifications.length > 0) {
            for (const qual of qualifications) {
                const { quaID, quaTitle, quaIssuer, quaDescription, quaAcquiredDate, isPublic } = qual;

                if (quaID) {
                    await pool.request()
                        .input('QuaID', sql.Int, quaID)
                        .input('QuaTitle', sql.NVarChar, quaTitle)
                        .input('QuaIssuer', sql.NVarChar, quaIssuer)
                        .input('QuaDescription', sql.NVarChar, quaDescription)
                        .input('QuaAcquiredDate', sql.DateTime, quaAcquiredDate)
                        .input('IsPublic', sql.Bit, isPublic)
                        .query(`
                            UPDATE Qualification
                            SET QuaTitle = @QuaTitle, QuaIssuer = @QuaIssuer, 
                                QuaDescription = @QuaDescription, QuaAcquiredDate = @QuaAcquiredDate, IsPublic = @IsPublic
                            WHERE QuaID = @QuaID
                        `);
                } else {
                    const result = await pool.request()
                        .input('AccountID', sql.Int, accountID)
                        .input('QuaTitle', sql.NVarChar, quaTitle)
                        .input('QuaIssuer', sql.NVarChar, quaIssuer)
                        .input('QuaDescription', sql.NVarChar, quaDescription)
                        .input('QuaAcquiredDate', sql.DateTime, quaAcquiredDate)
                        .input('IsPublic', sql.Bit, isPublic)
                        .query(`
                            INSERT INTO Qualification (AccountID, QuaTitle, QuaIssuer, QuaDescription, QuaAcquiredDate, IsPublic)
                            OUTPUT INSERTED.QuaID
                            VALUES (@AccountID, @QuaTitle, @QuaIssuer, @QuaDescription, @QuaAcquiredDate, @IsPublic)
                        `);

                    newQualificationsWithID.push({
                        QuaID: result.recordset[0].QuaID,
                        quaTitle,
                        quaIssuer
                    });
                }
            }
        }

        res.status(200).json({
            message: 'Qualifications processed successfully',
            newQualificationsWithID
        });
    } catch (error) {
        console.error('Error saving qualification info:', error);
        res.status(500).send('Failed to save qualification info');
    }
};

// Get CV Qualification Info
module.exports.getCVQualiInfo = async (req, res) => {
    const accountID = req.query.accountID;

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('AccountID', sql.Int, accountID)
            .query(`
                SELECT QuaID AS qualification_id, QuaTitle AS title, QuaIssuer AS issuer,
                       QuaDescription AS description, QuaAcquiredDate AS acquired_date,
                       IsPublic AS isPublic
                FROM Qualification
                WHERE AccountID = @AccountID
            `);

        if (result.recordset.length === 0) {
            res.status(404).send('No qualification data found');
        } else {
            res.json(result.recordset);
        }
    } catch (err) {
        console.error('Server error:', err);
        res.status(500).send('Server error');
    }
};




module.exports.showDetails = async (req, res) => {
    try {
        const { accountID } = req.body; // Get accountID from the request body

        if (!accountID) {
            return res.status(400).json({ error: 'AccountID is required' });
        }

        const pool = await poolPromise;

        // Fetch Profile information, including PerID
        const profileQuery = `
            SELECT 
                PerID AS perID,        -- Assuming PerID is the column for the profile ID
                Name AS name, 
                Age AS age, 
                Email_Address AS email, 
                Mobile_Number AS phone, 
                Address AS address, 
                Description AS description, 
                Photo AS profile_image_path
            FROM Profile
            WHERE AccountID = @accountID
        `;
        const profileResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(profileQuery);

        if (profileResult.recordset.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        const userDetails = profileResult.recordset[0];

        // If the user has a Photo, encode it in base64
        if (userDetails.profile_image_path) {
            userDetails.profile_image_path = Buffer.from(userDetails.profile_image_path).toString('base64');
        }

        // Fetch Education information
        const educationQuery = `
            SELECT 
                EduBacID AS eduBacID, 
                LevelEdu AS level, 
                FieldOfStudy AS field_of_study, 
                InstituteName AS institute_name, 
                InstituteCountry AS institute_country, 
                InstituteState AS institute_state, 
                InstituteCity AS institute_city, 
                CONVERT(VARCHAR(10), EduStartDate, 120) AS start_date, 
                CONVERT(VARCHAR(10), EduEndDate, 120) AS end_date, 
                IsPublic AS isPublic
            FROM Education 
            WHERE AccountID = @accountID AND IsPublic = 1;
        `;
        const educationResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(educationQuery);

        // Fetch Work Experience information
        const workExperienceQuery = `
            SELECT
                WorkExpID AS WorkExpID, 
                WorkTitle AS job_title, 
                WorkCompany AS company_name, 
                WorkIndustry AS industry, 
                WorkCountry AS country, 
                WorkState AS state, 
                WorkCity AS city, 
                WorkDescription AS description, 
                CONVERT(VARCHAR(10), WorkStartDate, 120) AS start_date, 
                CONVERT(VARCHAR(10), WorkEndDate, 120) AS end_date
            FROM Work
            WHERE AccountID = @accountID AND IsPublic = 1;
        `;
        const workExperienceResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(workExperienceQuery);

        // Fetch SoftSkill information
        const skillsQuery = `
            SELECT 
                SoftID AS SoftID,
                SoftHighlight AS skill,
                SoftLevel as level,
                SoftDescription AS description,
                IsPublic AS isPublic
            FROM SoftSkill
            WHERE AccountID = @accountID AND IsPublic = 1;
        `;
        const skillsResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(skillsQuery);

        // Fetch Certifications information
        const certificationsQuery = `
    SELECT 
        CerID AS cerID, 
        CerName AS name, 
        CerEmail AS email, 
        CerType AS type, 
        CerIssuer AS issuer, 
        CerDescription AS description, 
        CONVERT(VARCHAR(10), CerAcquiredDate, 120) AS acquiredDate,
        IsPublic AS isPublic
    FROM Certification 
    WHERE AccountID = @accountID AND IsPublic = 1;
`;

        const certificationResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(certificationsQuery);

        // Combine profile, education, work experience, skills, and certifications into a single object
        const combinedDetails = {
            profile: userDetails,  // Includes PerID
            education: educationResult.recordset,
            workExperience: workExperienceResult.recordset,
            skills: skillsResult.recordset,
            certification: certificationResult.recordset,
        };

        res.status(200).json(combinedDetails);
    } catch (err) {
        console.error('Show Details Error:', err);
        res.status(500).json({ error: 'Server error. Please try again later.' });
    }
};

module.exports.showDetailsQR = async (req, res) => {
    try {
        const { accountID } = req.body; // Get accountID from the request body
        console.log("Called Backnd with AccID: " + accountID);
        if (!accountID) {
            return res.status(400).json({ error: 'AccountID is required' });
        }

        const pool = await poolPromise;

        // Fetch Profile information, including PerID
        const profileQuery = `
            SELECT 
                PerID AS perID,        -- Assuming PerID is the column for the profile ID
                Name AS name, 
                Age AS age, 
                Email_Address AS email, 
                Mobile_Number AS phone, 
                Address AS address, 
                Description AS description, 
                Photo AS profile_image_path
            FROM Profile
            WHERE AccountID = @accountID
        `;
        const profileResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(profileQuery);
        console.log("Done Search Profile");
        if (profileResult.recordset.length === 0) {
            console.log("Search Profile Error");
            return res.status(404).json({ error: 'User not found' });
        }

        const userDetails = profileResult.recordset[0];
        // If the user has a Photo, encode it in base64
        if (userDetails.profile_image_path) {
            userDetails.profile_image_path = Buffer.from(userDetails.profile_image_path).toString('base64');
        }


        console.log("\nFetch Profile Done");

        // Fetch Education information
        const educationQuery = `
            SELECT 
                EduBacID AS eduBacID, 
                LevelEdu AS level, 
                FieldOfStudy AS field_of_study, 
                InstituteName AS institute_name, 
                InstituteCountry AS institute_country, 
                InstituteState AS institute_state, 
                InstituteCity AS institute_city, 
                CONVERT(VARCHAR(10), EduStartDate, 120) AS start_date, 
                CONVERT(VARCHAR(10), EduEndDate, 120) AS end_date, 
                IsPublic AS isPublic
            FROM Education 
            WHERE AccountID = @accountID
        `;
        const educationResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(educationQuery);


        console.log("\nFetch Education Done");

        // Fetch Work Experience information
        const workExperienceQuery = `
            SELECT
                WorkExpID AS workExpID, 
                WorkTitle AS job_title, 
                WorkCompany AS company_name, 
                WorkIndustry AS industry, 
                WorkCountry AS country, 
                WorkState AS state, 
                WorkCity AS city, 
                WorkDescription AS description, 
                CONVERT(VARCHAR(10), WorkStartDate, 120) AS start_date, 
                CONVERT(VARCHAR(10), WorkEndDate, 120) AS end_date
            FROM Work
            WHERE AccountID = @accountID 
        `;
        const workExperienceResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(workExperienceQuery);


        console.log("\nFetch Work Done");

        // Fetch SoftSkill information
        const skillsQuery = `
            SELECT 
                SoftID AS SoftID,
                SoftHighlight AS skill,
                SoftDescription AS description,
                SoftLevel AS level,
                IsPublic AS isPublic
            FROM SoftSkill
            WHERE AccountID = @accountID
        `;
        const skillsResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(skillsQuery);


        console.log("\nFetch SoftSkill Done");

        // Fetch Certifications information
        const certificationsQuery = `
    SELECT 
        CerID AS cerID, 
        CerName AS name, 
        CerEmail AS email, 
        CerType AS type, 
        CerIssuer AS issuer, 
        CerDescription AS description, 
        CONVERT(VARCHAR(10), CerAcquiredDate, 120) AS acquiredDate,
        IsPublic AS isPublic
    FROM Certification 
    WHERE AccountID = @accountID AND Active = 1
`;

        const certificationResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(certificationsQuery);
        console.log("\nFetch Certification Done");

        // Combine profile, education, work experience, skills, and certifications into a single object
        const combinedDetails = {
            profile: userDetails,  // Includes PerID
            education: educationResult.recordset,
            workExperience: workExperienceResult.recordset,
            skills: skillsResult.recordset,
            certification: certificationResult.recordset,
        };

        res.status(200).json(combinedDetails);
    } catch (err) {
        console.error('Show Details Error:', err);
        res.status(500).json({ error: 'Server error. Please try again later.' });
    }
};
