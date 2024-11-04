/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const sql = require('mssql');

const dbConfigWallet = {
    user: 'Wallet',
    password: 'Wallet',
    server: '127.0.0.1',
    database: 'Wallet',
    options: {
        encrypt: true,
        trustServerCertificate: true,
        enableArithAbort: true,
        connectTimeout: 30000,
        requestTimeout: 30000,
    },
    port: 1433,
};

module.exports = dbConfigWallet;
