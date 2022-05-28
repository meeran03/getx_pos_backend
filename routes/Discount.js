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

    // @route   /api/discount
    // @desc    Get all discounts
    // @access  Public
    router.get("/", async (req, res) => {
        let discounts = await db.query(
            `SELECT * FROM [Discount]`,
        )
        res.json(discounts.recordset);
    });

    // @route   /api/discount/:id
    // @desc    Get a discount by id
    // @access  Public
    router.get("/:id", async (req, res) => {
        let discount = await db.query(
            `SELECT * FROM [Discount] WHERE id=${req.params.id}`,
        )
        res.json(discount.recordset);
    });


    // @route   /api/discount
    // @desc    Create a discount
    // @access  Private
    router.post("/", async (req, res) => {
        let discount = {
            name: req.body.name,
            percentage: req.body.percentage,
            active: req.body.active === true ? 1 : 0,
        }
        console.log(discount);
        // generate new id for the discount
        let newId = await db.query(
            `SELECT MAX(id) as CO FROM [Discount]`,
        )
        console.log(newId);
        newId = newId.recordset[0].CO + 1;
        discount.id = newId;
        // insert discount into db
        let result = await db.query(
            `INSERT INTO [Discount] VALUES (${newId}, 
                '${discount.name}'
                , ${discount.percentage}
                , ${discount.active}
            )`,
        )
        res.json(result);
    });

    // @route   /api/discount/:id
    // @desc    Update a discount
    // @access  Private
    router.put("/:id", async (req, res) => {
        let discount = {
            name: req.body.name,
            percentage: req.body.percentage,
            active: req.body.active === true ? 1 : 0,
        }
        console.log(discount);
        // update discount into db
        let result = await db.query(
            `UPDATE [Discount] SET name='${discount.name}',
                percentage=${discount.percentage},
                active=${discount.active}
                WHERE id=${req.params.id}`,
        )
        res.json(result);
    });

    // @route   /api/discount/:id
    // @desc    Delete a discount
    // @access  Private
    router.delete("/:id", async (req, res) => {
        // delete discount from db
        let result = await db.query(
            `DELETE FROM [Discount] WHERE id=${req.params.id}`,
        )
        res.json(result);
    });

    return router;
}
