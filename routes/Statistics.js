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

    // get top customers
    router.get('/top-customers/', async (req, res) => {
        console.log("I amhit")
        let result = await db.query(`Select * from GetTopBuyerCustomers`)

        res.json(result.recordset);
    })

    // get top products
    router.get('/top-products/', async (req, res) => {
        console.log("I amhit")
        let result = await db.query(`Select * from GetBestPerformingProducts`)
        return res.json(result.recordset);
    })


    // get current month sales
    router.get('/current-month-sales/', async (req, res) => {
        console.log("I amhit")
        let result = await db.query(`Select * from GetCurrentMonthSales`)
        let previousMonthSales = await db.query(`Select * from PreviousMonthSales`)
        let currentMonthSales = result.recordset[0]
        previousMonthSales = previousMonthSales.recordset[0]
        let data = {
            currentMonthSales: currentMonthSales,
            previousMonthSales: previousMonthSales
        }
        return res.json(data);
    })

    // get current month customers
    router.get('/current-month-customers/', async (req, res) => {
        console.log("I amhit")
        let result = await db.query(`Select * from CurrentMonthCustomers`)
        let previousMonthCustomers = await db.query(`Select * from PreviousMonthCustomers`)
        let currentMonthCustomers = result.recordset[0].customer_count
        previousMonthCustomers = previousMonthCustomers.recordset[0].customer_count
        let data = {
            currentMonthCustomers: currentMonthCustomers,
            previousMonthCustomers: previousMonthCustomers
        }
        return res.json(data);
    })
    return router;
}
