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

    // @route   /api/sales
    // @desc    Get all sales
    // @access  Public
    router.get("/", async (req, res) => {
        let sales = await db.query(
            `exec GetSellTransactionsWithDate '${req.query.startDate}', '${req.query.endDate}'`
        )
        console.log(sales)
        res.json(sales.recordset);
    });

    // @route   /api/sales/:id
    // @desc    Get a sale
    // @access  Public
    router.get("/:id", async (req, res) => {
        let sale = await db.query(
            `Select t.*,c.name as contact_name from [Transaction] t inner join Contact c on c.id=t.contact_id where t.id = ${req.params.id}`
        )
        // get associated sale orders
        let saleOrders = await db.query(
            `Select p.*,pv.name as name,pv.default_sell_price as default_sell_price from SellLines p inner join ProductVariation pv on pv.id=p.variation_id
             where p.transaction_id = ${req.params.id}`
        )
        let result = sale.recordset[0];
        console.log(saleOrders)
        result.sale_orders = saleOrders.recordset;
        res.json(result);
    });


    return router;
}
