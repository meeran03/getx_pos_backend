const express = require("express");
const router = express.Router();
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");
const path = require("path");

const validator = require("../validation/Auth");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const keys = require("../config/keys");

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, "images");
    },
    filename: function (req, file, cb) {
        cb(null, uuidv4() + "-" + Date.now() + path.extname(file.originalname));
    },
});

const fileFilter = (req, file, cb) => {
    const allowedFileTypes = ["image/jpeg", "image/jpg", "image/png"];
    if (allowedFileTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(null, false);
    }
};

let upload = multer({
    storage,
    fileFilter,
    limits: { fieldSize: 1024 * 1024 * 25 },
});

module.exports = (db) => {

    // get transactions between two dates
    router.get('/', async (req, res) => {
        const { start_date, end_date } = req.query;
        let result = await db.request()
            .input('start_date', start_date)
            .input('end_date', end_date)
            .execute('GetTransactions');
        res.json(result.recordset);
    });

    // get transaction by id
    router.get('/:id', async (req, res) => {
        const { id } = req.params;
        let result = await db.query(`SELECT * FROM Transaction WHERE ID = ${id}`);
        res.json(result.recordset);
    })



    return router;
}
